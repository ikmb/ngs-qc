include { DADA2_RUEHLEMANN } from "./../modules/dada/ruehlemann"

workflow AMPLICON_QC {

	take: 
	// project,meta,[reads]
	reads

	main:
	DADA2_RUEHLEMANN(
		reads
	)
	
}
