process DADA2_DEREP {
    tag "$project"
    label 'process_medium'
    label 'process_long'

    container 'quay.io/biocontainers/bioconductor-dada2:1.22.0--r41h399db7b_0'

    input:
    tuple val(project),val(meta), path(reads)

    output:
    tuple val(meta), path("*.dada.rds")   , emit: derep
    tuple val(meta), path("*.log")        , emit: log

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        errF = readRDS("${errormodel[0]}")
        errR = readRDS("${errormodel[1]}")

        filtFs <- sort(list.files(".", pattern = "_1.filt.fastq.gz", full.names = TRUE))
        filtRs <- sort(list.files(".", pattern = "_2.filt.fastq.gz", full.names = TRUE))

        sample.names <- sapply(strsplit(basename(filtFs), "_"), `[`, 1)

	# derep
	derepFs <- derepFastq(filtFs, verbose=TRUE)
	derepRs <- derepFastq(filtRs, verbose=TRUE)
	
	names(derepFs) <- sample.names
	names(derepRs) <- sample.names

        write.table('mergePairs\t$args2', file = "mergePairs.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    """
}
