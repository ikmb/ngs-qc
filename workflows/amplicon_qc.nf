include { FASTP } from "./../modules/fastp"
include { DADA2 } from "./../modules/dada"
  
workflow AMPLICON_QC {

	take: 
	reads

	main:
	FASTP(
		reads
	)
	DADA2(
		FASTP.out.fastq
	)

	emit:
	qc = DADA2.out.qc
	
}
