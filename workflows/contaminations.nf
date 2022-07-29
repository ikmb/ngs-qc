include { FASTP as FASTP_FILTER } from "./../modules/fastp"
include { BIOBLOOM_CATEGORIZER } from "./../modules/biobloom/categorizer"

workflow CONTAMINATIONS {

	take:
		reads

	main:

		FASTP_FILTER(
			reads.filter{ p,f -> f =~ /.*_R[1,2]_001.fastq.gz/ }.map { p,f ->
                                def m = f.getBaseName().split("_R[1,2]")[0]
                                tuple(p,m,f)
                        }.groupTuple(by: [0,1]).map { p,l,files -> tuple(p,l,files.sort()) }
		)
                BIOBLOOM_CATEGORIZER(
			FASTP_FILTER.out.reads
                )

                screens_by_project = BIOBLOOM_CATEGORIZER.out.results.groupTuple()

	emit:
	qc = screens_by_project
}
