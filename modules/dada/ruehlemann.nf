process DADA2_RUEHLEMANN {

	container 'ikmb/ngs-qc:devel'

	publishDir "${params.outdir}/${project}/AmpliconQC", mode: 'copy'

	input:
	tuple val(project),val(meta),path(reads)

	output:
	tuple val(project),path(rtable), emit: rtable

	script:
	results = project + "_dada"
	rtable = "${project}_tracked_reads_mqc.out"
	def profile = meta.AmpliconProtocol

	"""
		dada2_workflow.R $profile $project ${task.cpus}
		cp ${project}/track_reads.txt $rtable
	"""
}

