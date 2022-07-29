process DADA2_RUEHLEMANN {

	tag "${project}"

	container 'ikmb/ngs-qc:devel'

	publishDir "${params.outdir}/${project}/AmpliconQC", mode: 'copy'

	input:
	tuple val(project),val(meta),path(reads)

	output:
	tuple val(project),path(rtable), emit: rtable
	path(results)

	script:
	results = "dada2"
	rtable = "amplicon_qc_mqc.out"
	def profile = meta.AmpliconProtocol

	"""
		dada2_workflow.R $profile $results ${task.cpus}
		cp ${results}/track_reads.txt $rtable
		sed -i.bak 's/^raw/\traw/' $rtable
	"""
}

	
