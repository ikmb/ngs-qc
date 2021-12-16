#!/usr/bin/env nextflow

/**
===============================
QC Pipeline
===============================

This Pipeline performs QC on demuxed NGS runs

### Homepage / git
git@github.com:ikmb/ngs-qc.git
### Implementation
v1.0 in Q1 2021

Author: Marc P. Hoeppner, m.hoeppner@ikmb.uni-kiel.de

**/

// Pipeline version

params.version = workflow.manifest.version

// Help message
helpMessage = """
===============================================================================
IKMB QC pipeline | version ${params.version}
===============================================================================
Usage: nextflow run ikmb/ngs-qc --folder /path/to/demux/folder

Required parameters:
--folder                      Path to Illumina demux run dir
--skip_multiqc		      Do not generate an aggregated report for individual projects
Optional parameters:

Output:
--outdir                       Local directory to which all output is written (default: results)

"""

params.help = false
version = workflow.manifest.version

// Show help when needed
if (params.help){
    log.info helpMessage
    exit 0
}

def summary = [:]

demux_folder = file(params.folder)
run_dir = demux_folder.getName()

stats = file("${params.folder}/Stats/Stats.json")

if (!stats.exists()) {
	stats_file = Channel.empty()
} else {
	stats_file = Channel.fromPath(stats)
}

// Info screen

log.info "-------------------------------------"
log.info "IKMB QC Pipeline - version ${version}"
log.info "-------------------------------------"
log.info "Date			${workflow.start}"
log.info "Work dir		${workflow.workDir}"
log.info "Target folder:		${params.folder}"
log.info "FastqScreen config:	${params.fastq_screen_config}"

// Get list of all project folders

reads = Channel.fromPath("${demux_folder}/*/*_R*_001.fastq.gz")
tenx_reads = Channel.fromPath("${demux_folder}/*/H*/*-L?/*_001.fastq.gz", followLinks: false) 

tenx_reads.map { file -> [ file.getParent().getParent().getParent().getName(), file ] }
	.ifEmpty { log.info "No 10X reads were found, assuming none were included..."}
	.filter ( f -> f != null )
	.into { tenx_by_project; tenx_test } 

reads.map { file-> [ file.getParent().getName(), file ] }
	.ifEmpty { log.info "No regular projects found, assuming none were included..." }
	.filter ( f -> f != null )
	.into { reads_by_project; reads_test }

reads_by_project.mix(tenx_by_project)
	.ifEmpty{ exit  1; "Found neither regular sequencing data nor 10X reads - exiting"}
	.into { all_reads_by_project; all_reads_screen  }

process fastqc {

	publishDir "${params.outdir}/${project}/fastqc", mode: 'copy' , overwrite: true

	scratch true

	stageOutMode 'rsync'

	input:
	set val(project),path(fastq) from all_reads_by_project

	output:
	set val(project), path("*.zip") into fastqc_reports
	path("*.html")
	
	script:
	
	"""
		fastqc -t 1 $fastq	
	"""

}

if (params.fastq_screen_config) {

	process screen_contaminations {

		input:
		set val(project),path(fastq) from all_reads_screen

		output:
		set val(project),path("*_screen.txt") into contaminations

		script:

		"""
			fastq_screen --force --subset 200000 --conf ${params.fastq_screen_config} --aligner bowtie2 $fastq
		"""

	}

} else {
	contaminations = Channel.empty()
}

fastqc_by_project = fastqc_reports.groupTuple()
screens_by_project = contaminations.groupTuple()
reports_by_project = fastqc_by_project.join(screens_by_project)

process multiqc_run {

	publishDir "${params.outdir}/MultiQC", mode: 'copy', overwrite: true

	stageOutMode 'rsync'

	input:
	file(json) from stats_file

	output:
	file(multiqc)

	script:
	multiqc = "multiqc_demux.html"	
	"""
		multiqc -b "Run ${run_dir}" -n $multiqc .
	"""

}
 
process multiqc_files {

	tag "${project}"

	publishDir "${params.outdir}/${project}/MultiQC", mode: 'copy', overwrite: true

	stageOutMode 'rsync'

	when:
	!params.skip_multiqc

	input:
	set val(project),file('*'),file('*') from reports_by_project

	output:
	path("multiqc_*.html") 

	script:
	"""
		cp ${baseDir}/assets/multiqc_config.yaml . 
		cp ${baseDir}/assets/ikmblogo.png . 
		partition_multiqc.pl --title ${project} --chunk ${params.chunk_size} --title "QC for ${project} ${run_dir}" --config multiqc_config.yaml 
	"""		
}

workflow.onComplete { 

	log.info "QC Pipeline successful: ${workflow.success}"

}
