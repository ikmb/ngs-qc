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

reads.map { file-> [ file.getParent().getName(), file ] }.into { reads_by_project ; reads_screen }

process fastqc {

	publishDir "${params.outdir}/${project}/fastqc", mode: 'copy'

	input:
	set val(project),path(fastq) from reads_by_project

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
		set val(project),path(fastq) from reads_screen

		output:
		set val(project),path("*_screen.txt") into contaminations

		script:

		"""
			fastq_screen --force --subset 2000000 --conf ${params.fastq_screen_config} --aligner bowtie2 $fastq
		"""

	}

} else {
	contaminations = Channel.empty()
}

fastqc_by_project = fastqc_reports.groupTuple()
screen_by_project = contaminations.groupTuple()

process multiqc_run {

	publishDir "${params.outdir}/MultiQC", mode: 'copy'

	input:
	file(json) from stats_file

	output:
	file(multiqc)

	script:
	multiqc = "multiqc_demux.html"	
	"""
		multiqc -n $multiqc .
	"""

}
 
process multiqc_files {

	publishDir "${params.outdir}/${project}/MultiQC", mode: 'copy'

	input:
	set val(project),file('*') from fastqc_by_project
	set val(project),file('*') from screen_by_project

	output:
	path("multiqc_report.html") 

	script:

	"""
		cp ${baseDir}/assets/multiqc_config.yaml . 
		cp ${baseDir}/assets/ikmblogo.png . 
		multiqc .
	"""		
}
