![](images/ikmb_bfx_logo.png)

# ngs-qc
QC tools for new sequencing runs (FastQC, FastQ Screen, MultiQC Report)

## Usage instructions

This pipeline is currently defined to run on the IKMB DX Cluster. To start the pipeline, you need:

* singularity
* nextflow

Both of these should be available automatically. 

The basic syntax is as follows:

```bash

nextflow run ikmb/ngs-qc --folder /mnt/demux/illumina/<PROJECT>

```

This will traverse all the project folders and produce both a global run statistic 
from the bcl2fastq stats file as well as per-library metrics on sequence 
quality and possible contaminations, separated by project name. 

By default, the results are written to the folder "results", created in the 
place where the pipeline is launched from. Alternatively, you may specify 
`--outdir /some/outdir` to generate the results elsewhere. If you point 
`--outdir` to  the same folder as the demuxed run, the QC reports should be 
correctly sorted into the respective project directories. 

```bash

nextflow run ikmb/ngs-qc --folder /mnt/demux/illumina/<PROJECT> --outdir /mnt/demux/illumina/<PROJECT>

```

