process MULTIQC_RUN {

        publishDir "${params.outdir}/MultiQC", mode: 'copy', overwrite: true

	tag "Run-Level"

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
        tuple val(project),file('*')

        output:
        path("multiqc_*.html")

        script:
        """
                cp ${baseDir}/assets/multiqc_config.yaml .
                cp ${baseDir}/assets/ikmblogo.png .
                partition_multiqc.pl --name ${project} --chunk ${params.chunk_size} --title "QC for ${project} ${params.run_dir}" --config multiqc_config.yaml
        """
}

process MULTIQC_DADA {

        label 'multiqc'

        tag "${project}"

        publishDir "${params.outdir}/${project}/dada2/MultiQC", mode: 'copy', overwrite: true

        stageOutMode 'rsync'

        when:
        !params.skip_multiqc

        input:
        tuple val(project),file('*')

        output:
        path("multiqc_*.html")

        script:
        """
                cp ${baseDir}/assets/multiqc_config.yaml .
                cp ${baseDir}/assets/ikmblogo.png .
		multiqc -n multiqc_${project}_AmpliconQC -c multiqc_config.yaml -b "Amplicon QC ${project}" *
        """
}

