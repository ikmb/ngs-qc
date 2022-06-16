process FASTQC {

        label 'fastqc'

        tag "${project}|${fastq}"

        publishDir "${params.outdir}/${project}/fastqc", mode: 'copy' , overwrite: true

        scratch true

        stageOutMode 'rsync'

        input:
        set val(project),path(fastq)

        output:
        set val(project), path("*.zip"), emit: zip
        path("*.html"), emit: html

        script:

        """
                fastqc -t 1 $fastq
        """

}
