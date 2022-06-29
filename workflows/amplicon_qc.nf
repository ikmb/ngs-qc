include { CUTADAPT } from "./../modules/cutadapt"
include { DADA2_FILTNTRIM as DADA_TRIM } from "./../modules/dada/trim"
include { DADA2_ERR as DADA_ERROR } from "./../modules/dada/error"  
include { FASTQC_DADA } from "./../modules/fastqc"
include { MULTIQC_DADA } from "./../modules/multiqc"

workflow AMPLICON_QC {

	take: 
	// project,meta,[reads]
	reads

	main:
	CUTADAPT(
		reads
	)
	DADA_TRIM(
		CUTADAPT.out.reads
	)

	DADA_TRIM.out.reads.map { p,m,files ->
		def meta = [:]
		meta.protocol = m.protocol
		meta.primers = m.primers
		meta.trunclenf = m.trunclenf
		meta.trunclenr = m.trunclenr
		[p,meta,files]
	}
	.groupTuple(by: [0,1])
	.map { p,meta,reads ->
		[ p, meta, reads.flatten().sort() ]
	}
	.set { ch_filt_reads }

	FASTQC_DADA(
		DADA_TRIM.out.reads
	)

	MULTIQC_DADA(
		FASTQC_DADA.out.zip.flatten().groupTuple(by: [0]).map { project,zips ->
			tuple(project, zips.flatten().sort())
		}
	)

	emit:
	qc = CUTADAPT.out.log
	
}
