#!/usr/bin/env nextflow
nextflow.enable.dsl=2

@Grab('com.github.groovy-wslite:groovy-wslite:1.1.2')
import wslite.rest.*

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
params.run_dir = demux_folder.getName()

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
tenx_reads = Channel.fromPath("${demux_folder}/*/[A-Z0-9]*/*_001.fastq.gz", followLinks: false) 

tenx_reads.map { file -> [ file.getParent().getParent().getName(), file ] }
	.ifEmpty { log.info "No 10X reads were found, assuming none were included..."}
	.filter ( f -> f != null )
	.into { tenx_by_project; tenx_test } 

reads.map { file-> 
		def project = file.getParent().getName()
		tuple(project file) 
	}
	.ifEmpty { log.info "No regular projects found, assuming none were included..." }
	.filter ( f -> f != null )
	.into { reads_by_project; reads_test }

reads_by_project.mix(tenx_by_project)
	.ifEmpty{ exit  1; "Found neither regular sequencing data nor 10X reads - exiting"}
	.into { all_reads_by_project; all_reads_screen ; all_reads_test }

// Enrich channel with LIMS meta data to select data for specific QC measures
all_reads_test.groupTuple().map { p,files ->
	def meta = get_lims_info(p)
	tuple(p,meta,files)
}.branch { p,m,f ->
	ampliseq: m.protocol == "Amplicon_Seq"
	unknown: m.protocol == "Unknown"
}.set { reads_by_application }

// MODULES and WORKFLOWS
include { FASTQC } from "./modules/fastqc"
include { FASTQ_SCREEN } from "./modules/fastq_screen"
include { AMPLICON_QC } from "./workflows/amplicon_qc"
include { MULTIQC_RUN; MULTIQC_PROJECT } from './modules/multiqc'

ch_qc = Channel.from([])

workflow {

	FASTQC(all_reads_by_project)
	ch_qc = ch_qc.mix(FASTQC.out.zip)
	fastqc_by_project = FASTQC.out.zip.groupTuple()

	if (params.fastq_screen_config) {
		FASTQ_SCREEN(all_reads_screen)
		ch_qc = ch_qc.mix(FASTQ_SCREEN.out.txt)
		screens_by_project = FASTQ_SCREEN.out.txt.groupTuple()
	}

	reports_by_project = fastqc_by_project.join(screens_by_project)

	// Amplicon QC subworkflow	
	AMPLICON_QC(reads_by_application.ampliseq)
		
	// MultiQC reports
	MULTIQC_RUN(stats_file)
	MULTIQC_PROJECT(reports_by_project)

}
	
workflow.onComplete { 

	log.info "QC Pipeline successful: ${workflow.success}"

}

// Functions to retrieve LIMS information about projects
def get_lims_info(String name) {

	def project_name = name.trim()
	def url_path = "/project/info/${project_name}"
	RESTClient client = new RESTClient("http://172.21.99.59/restapi")
	def response = client.get( path: url_path,
		accept: ContentType.JSON,
		connectTimeout: 5000,
                readTimeout: 10000,
                followRedirects: false,
                useCaches: false,
                sslTrustAllCerts: true 
	)
	def external_id = response.json.external_id
	def meta = get_project_details(external_id)

	return meta
}

def get_project_details(Integer id) {

	def meta = [:]
	meta["protocol"] = "Unknown"
	def url_path = "/get_order_info/order_id/${id}"
	RESTClient client = new RESTClient("http://172.21.96.85/IKMB_order_service/api")
        def response = client.post( path: url_path,
                accept: ContentType.JSON,
                headers:[Authorization: 'Token 6f332d6c7b99a76f183e6a295fb10aef9b9ce38a'],
                connectTimeout: 5000,
                readTimeout: 10000,
                followRedirects: false,
                useCaches: false,
                sslTrustAllCerts: true
        )

	def data = response.json.info_dict.data
	data.each { e ->
		def key = e.type
		def value = e.value
		if (key == "Please prepare") {
			key = "protocol"
		}
		meta[key] = value
	}
	
	return meta
}


