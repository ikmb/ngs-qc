process DADA2_ERR {

    tag "${project}"


    container 'quay.io/biocontainers/bioconductor-dada2:1.22.0--r41h399db7b_0'

    input:
    tuple val(project),val(meta),path(reads)

    output:
    tuple val(meta), path("*.err.rds"), emit: errormodel
    tuple val(meta), path("*.err.pdf"), emit: pdf
    tuple val(meta), path("*.err.log"), emit: log
    tuple val(meta), path("*.err.convergence.txt"), emit: convergence

    script:
    def args = task.ext.args ?: ''
    """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        fnFs <- sort(list.files(".", pattern = "_1.filt.fastq.gz", full.names = TRUE))
        fnRs <- sort(list.files(".", pattern = "_2.filt.fastq.gz", full.names = TRUE))

        sink(file = "${project}.err.log")
        errF <- learnErrors(fnFs, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(errF, "${project}_1.err.rds")
        errR <- learnErrors(fnRs, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(errR, "${project}_2.err.rds")
        sink(file = NULL)

        pdf("${project}_1.err.pdf")
        plotErrors(errF, nominalQ = TRUE)
        dev.off()

        pdf("${project}_2.err.pdf")
        plotErrors(errR, nominalQ = TRUE)
        dev.off()

        sink(file = "${project}_1.err.convergence.txt")
        dada2:::checkConvergence(errF)
        sink(file = NULL)

        sink(file = "${project}_2.err.convergence.txt")
        dada2:::checkConvergence(errR)
        sink(file = NULL)

        write.table('learnErrors\t$args', file = "learnErrors.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    """
}
