process FASTQC {

        label 'fastqc'

        tag "${project}|${fastq}"

        publishDir "${params.outdir}/${project}/fastqc", mode: 'copy' , overwrite: true

        scratch true

        stageOutMode 'rsync'

        input:
        tuple val(project),path(fastq)

        output:
        tuple val(project), path("*.zip"), emit: zip
        path("*.html"), emit: html

        script:

        """
                fastqc -t 1 $fastq
        """

}

process FASTQC_DADA {

	publishDir "${params.outdir}/${project}/dada2/fastqc", mode: 'copy'

        label 'fastqc'

        tag "${project}|${fastqs[0]}"

        scratch true

        stageOutMode 'rsync'

        input:
        tuple val(project),val(meta),path(fastqs)

        output:
        tuple val(project), path("*.zip"), emit: zip
        path("*.html"), emit: html

        script:

        """
                fastqc -t 2 $fastqs
        """

}
