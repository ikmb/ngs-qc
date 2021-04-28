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

// Get list of all project folders

reads = Channel.fromPath("${demux_folder}/*/*_R*_001.fastq.gz")

reads_by_project = reads.map { file-> [ file.getParent().getName(), file ] }

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

fastqc_by_project = fastqc_reports.groupTuple()

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

	output:
	path("multiqc_report.html") 

	script:

	"""
		cp ${baseDir}/assets/multiqc_config.yaml . 
		cp ${baseDir}/assets/ikmblogo.png . 
		multiqc .
	"""		
}
