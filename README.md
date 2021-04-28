# ngs-qc
QC tools for new sequencing runs (FastQC, Bloomfilters, MultiQC Report)

## Usage instructions

This pipeline is currently defined to run on the IKMB DX Cluster. To start the pipeline, you need:

* singularity
* nextflow

Both of these should be available automatically. 

The basic syntax is as follows:

```bash

nextflow run ikmb/ngs-qc --folder /mnt/demux/illumina/<PROJECT>

```

This will traverse all the project folders and produce both a global run statistic from the bcl2fastq stats file as well as 
pre-library metrics on sequence quality and possible contaminations. 

By default, the results are writting to the folder "results", create in the place where the pipeline is launched from. Alternatively, 
you may specifiy `--outdir /some/outdir` to generate the results elsewhere. If you point `--outdir` to  the same folder as the demuxed run,
the QC reports should be correctly sorted into the respective project directories. 

