process DADA2_FILTNTRIM {
    tag "${project}|${reads[0]}"

    container 'quay.io/biocontainers/bioconductor-dada2:1.22.0--r41h399db7b_0'

    input:
    tuple val(project),val(meta), path(reads)

    output:
    tuple val(project),val(meta), path("*.filter_stats.tsv"), emit: log
    tuple val(project),val(meta), path("*.filt.fastq.gz")   , emit: reads

    script:
    def args        = task.ext.args ?: ''
    def prefix = reads[0].getName().split("_R[1,2]")[0]
    def in_and_out  = "\"${reads[0]}\", \"${prefix}_1.filt.fastq.gz\", \"${reads[1]}\", \"${prefix}_2.filt.fastq.gz\""
    def trunclenf   = meta.trunclenf
    def trunclenr   = meta.trunclenr

    def trunc_args  = "truncLen = c($trunclenf, $trunclenr)"
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    out <- filterAndTrim($in_and_out,
        $trunc_args,
        $args,
        compress = TRUE,
        multithread = $task.cpus,
        verbose = TRUE)
    out <- cbind(out, ID = row.names(out))

    write.table( out, file = "${prefix}.filter_stats.tsv", sep = "\\t", row.names = FALSE, quote = FALSE, na = '')
    write.table(paste('filterAndTrim\t$trunc_args','$args',sep=","), file = "filterAndTrim.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    """
}
