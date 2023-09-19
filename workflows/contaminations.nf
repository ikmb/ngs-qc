include { BIOBLOOM_CATEGORIZER } from "./../modules/biobloom/categorizer"
include { FASTP } from "./../modules/fastp"

workflow CONTAMINATIONS {

	take:
		reads

	main:

		grouped_reads = reads.filter{ p,f -> f =~ /.*_R[1,2]_001.fastq.gz/ }.map { p,f ->
                                def m = f.getBaseName().split("_R[1,2]_")[0]
                                tuple(p,m,f)
                        }.groupTuple(by: [0,1]).map { p,l,files -> tuple(p,l,files.sort()) }

		FASTP(
			grouped_reads
		)
                BIOBLOOM_CATEGORIZER(
			FASTP.out.reads
                )

                //screens_by_project = BIOBLOOM_CATEGORIZER.out.results.groupTuple()

	emit:
	qc = BIOBLOOM_CATEGORIZER.out.results
	//qc = screens_by_project
}
