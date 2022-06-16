process MULTIQC_RUN

        publishDir "${params.outdir}/MultiQC", mode: 'copy', overwrite: true

        label 'multiqc'

        stageOutMode 'rsync'

        input:
        file(json)

        output:
        file(multiqc)

        script:
        multiqc = "multiqc_demux.html"
        """
                multiqc -b "Run ${params.run_dir}" -n $multiqc .
        """

}

process MULTIQC_PROJECT {

        label 'multiqc'

        tag "${project}"

        publishDir "${params.outdir}/${project}/MultiQC", mode: 'copy', overwrite: true

        stageOutMode 'rsync'

        when:
        !params.skip_multiqc

        input:
        set val(project),file('*'),file('*')

        output:
        path("multiqc_*.html")

        script:
        """
                cp ${baseDir}/assets/multiqc_config.yaml .
                cp ${baseDir}/assets/ikmblogo.png .
                partition_multiqc.pl --name ${project} --chunk ${params.chunk_size} --title "QC for ${project} ${params.run_dir}" --config multiqc_config.yaml
        """
}
