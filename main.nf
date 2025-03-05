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
stats_atac = file("${params.folder}/*/Stats/Stats.json")

if (!stats_atac.isEmpty() ) {
	stats_file = Channel.fromPath(stats_atac[0])
} else if (stats.exists()) {
	stats_file = Channel.fromPath(stats) 
} else {
	stats_file = Channel.empty()
}

// Info screen

log.info "-------------------------------------"
log.info "IKMB QC Pipeline - version ${version}"
log.info "-------------------------------------"
log.info "Date			${workflow.start}"
log.info "Work dir		${workflow.workDir}"
log.info "Target folder:		${params.folder}"

// Get list of all project folders

reads = Channel.fromPath("${demux_folder}/[A-Z][A-Za-z]*_*/*_R*_001.fastq.gz").filter { !it.toString().contains("Undetermined") }  
//diagx_reads = Channel.fromPath("${demux_folder}/NGS_Diagnostik-Exome/*_001.fastq.gz")


tenx_standard_reads = Channel.fromPath("${demux_folder}/[A-Z][A-Z]_*/[A-Z0-9]*/*_001.fastq.gz", followLinks: false) 
tenx_atac_reads = Channel.fromPath("${demux_folder}/*/[A-Z0-9]*/*-*/*_001.fastq.gz")
tenx_cite_reads = Channel.fromPath("${demux_folder}/[A-Z][A-Z]_*/*/[A-Z]*/*_001.fastq.gz", followLinks: false)

tenx_cite_reads.map { f ->
            [ f.toString().replaceAll(params.folder + "/", "").split("/")[0], f ]
        }
        .ifEmpty { log.info "No 10X CITE reads were found, assuming none were included..."}
        .filter ( f -> f != null )
        .set { tenx_cite_by_project }

tenx_standard_reads.map { f -> 
            [ f.toString().replaceAll(params.folder + "/", "").split("/")[0], f ] 
        }
	.ifEmpty { log.info "No regular 10X reads were found, assuming none were included..."}
	.filter ( f -> f != null )
	.set { tenx_standard_by_project } 


// /mnt/demux/illumina/230113_M05583_0213_000000000-DJC8H/SF_Jinru_Hydra_scATAC/DJC8H/22Nov728-L1/
tenx_atac_reads.map { f -> [ file(f).getParent().getParent().getParent().getName(), f ] }
        .ifEmpty { log.info "No 10X ATAC reads were found, assuming none were included..."}
        .filter ( f -> f != null )
        .set { tenx_atac_by_project }

tenx_by_project = tenx_atac_by_project.mix(tenx_standard_by_project,tenx_cite_by_project)

reads.map { f-> [ file(f).getParent().getName(),f ] }
	.ifEmpty { log.info "No regular projects found, assuming none were included..." }
	.filter ( f -> f != null )
	.set { reads_by_project }

reads_by_project.mix(tenx_by_project)
	.ifEmpty{ exit  1; "Found neither regular sequencing data nor 10X reads - exiting"}
	.set { all_reads_by_project }

// Enrich channel with LIMS meta data to select projects for specific QC measures
reads_by_project.groupTuple().flatMap { p,files ->
	def meta = get_lims_info(p)
	files.collect { tuple(p,meta,file(it)) }
}.branch { p,m,f ->
	ampliseq: m.protocol == "Amplicon_Seq" && m.containsKey("AmpliconProtocol")
	unknown: m.protocol == "Unknown"
}.set { reads_by_application }


// MODULES and WORKFLOWS
include { FASTQC } from "./modules/fastqc"
include { FASTQ_SCREEN } from "./modules/fastq_screen"
include { AMPLICON_QC } from "./workflows/amplicon_qc"
include { MULTIQC_RUN; MULTIQC_PROJECT } from './modules/multiqc'
include { CONTAMINATIONS } from "./workflows/contaminations.nf"
include { METADATA } from "./modules/metadata.nf"

ch_qc = Channel.from([])

workflow {

	// Produce a generic CCGA metadata sheet in XLSX format
	if (params.metadata) {
		METADATA(
			all_reads_by_project.groupTuple()
		)
	}

	FASTQC(all_reads_by_project)
	ch_qc = ch_qc.mix(FASTQC.out.zip)
	fastqc_by_project = FASTQC.out.zip.groupTuple()

	reports = Channel.from([])

	reports = reports.mix(FASTQC.out.zip)

	if (params.bloomfilter) {

		CONTAMINATIONS(
			all_reads_by_project
		)

		reports = reports.mix(CONTAMINATIONS.out.qc)
	}

	// Amplicon QC subworkflow	
	AMPLICON_QC(
		reads_by_application.ampliseq.map { p,m,f ->
			tuple(p,m,file(f))
		}
		.groupTuple(by: [0,1])
	)

	reports = reports.mix(AMPLICON_QC.out.qc)
	
	//reports_by_project = fastqc_by_project.join(screens_by_project).join(amplicon_by_project)

	// MultiQC reports
	MULTIQC_RUN(stats_file)
	MULTIQC_PROJECT(
		reports.groupTuple()
	)


}
	
workflow.onComplete { 

	log.info "QC Pipeline successful: ${workflow.success}"

}

// Functions to retrieve LIMS information about projects
def get_lims_info(String name) {

	def project_name = name.trim()
	def url_path = "/project/info/${project_name}"
	RESTClient client = new RESTClient("http://172.27.2.22/restapi")
	def response = client.get( path: url_path,
		accept: ContentType.JSON,
		connectTimeout: 5000,
                readTimeout: 10000,
                followRedirects: false,
                useCaches: false,
                sslTrustAllCerts: true 
	)
	def external_id = response.json.external_id
	def meta = [:]

	if (external_id) {
		meta = get_project_details(external_id)
	} 
	

	return meta
}

def get_project_details(Integer id) {

	def meta = [:]
	meta["protocol"] = "Unknown"
	def url_path = "/get_order_info/order_id/${id}"
	RESTClient client = new RESTClient("http://172.21.96.85/IKMB_order_service/api")
        def response = client.post( path: url_path,
                accept: ContentType.JSON,
                headers:[Authorization:  System.getenv('LIMS_TOKEN')],
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
		} else if (key == "We detect the variable region") {
			key = "primers"
		}
		meta[key] = value
		if (key == "primers") {

			if ( value.contains("V1-V2") ) {
				meta["AmpliconProtocol"] = "V1V2"
				meta["FWD"] = params.amplicons["V1V2"].fwd
				meta["REV"] = params.amplicons["V1V2"].rev
				meta["trunclenf"] = params.amplicons["V1V2"].trunclenf.toInteger()
				meta["trunclenr"] = params.amplicons["V1V2"].trunclenr.toInteger()
			} else if ( value.contains("V3-V4") ) {
				meta["AmpliconProtocol"] = "V3V4"
				meta["FWD"] = params.amplicons["V3V4"].fwd
                                meta["REV"] = params.amplicons["V3V4"].rev
				meta["FWD_RC"] = rc(params.amplicons["V3V4"].fwd)
                                meta["REV_RC"] = rc(params.amplicons["V3V4"].rev)
				meta["trunclenf"] = params.amplicons["V3V4"].trunclenf.toInteger()
                                meta["trunclenr"] = params.amplicons["V3V4"].trunclenr.toInteger()
			} else if ( value.contains("archaea") ) {
				meta["AmpliconProtocol"] = "Archaea"
				meta["FWD"] = params.amplicons["Archaea"].fwd
                                meta["REV"] = params.amplicons["Archaea"].rev
                                meta["FWD_RC"] = rc(params.amplicons["Archaea"].fwd)
                                meta["REV_RC"] = rc(params.amplicons["Archaea"].rev)
				meta["trunclenf"] = params.amplicons["Archaea"].trunclenf.toInteger()
                                meta["trunclenr"] = params.amplicons["Archaea"].trunclenr.toInteger()
                        } else if ( value.contains("fungi") ) {
				meta["AmpliconProtocol"] = "Fungi"
				meta["FWD"] = params.amplicons["Fungi"].fwd
                                meta["REV"] = params.amplicons["Fungi"].rev
				meta["trunclenf"] = params.amplicons["Fungi"].trunclenf.toInteger()
                                meta["trunclenr"] = params.amplicons["Fungi"].trunclenr.toInteger()
			}
						
		}

	}
	
	return meta
}

def rc(String seq) {
	def complements = [ A:'T', T:'A', U:'A', G:'C', C:'G', Y:'R', R:'Y', S:'S', W:'W', K:'M', M:'K', B:'V', D:'H', H:'D', V:'B', N:'N' ]
        comp = seq.reverse().toUpperCase().collect { base -> complements[ base ] ?: 'X' }.join()
        return comp
}
