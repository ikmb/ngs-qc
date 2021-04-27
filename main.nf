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
--folder                      Path to a demuxed Illumina project folder

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

// #############
// INPUT OPTIONS
// #############

// Sample input file

demux_folder = file(params.folder)

stats_file = file(params.folder + "/../Stats/Stats.json")

if (!stats_file.exists()) {
	stats_json = Channel.empty()
} else {
	stats_json = Channel.from(stats_file)
}	

reads = Channel.from("${params.demux_folder}/*.fastq.gz")

