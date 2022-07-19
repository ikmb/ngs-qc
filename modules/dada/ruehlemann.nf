process DADA2_RUEHLEMANN {

	container 'ikmb/ngs-qc:latest'

	input:
	tuple val(project),val(meta),path(reads)

	output:
	tuple val(project),path(results)

	script:
	results = project + "_dada"

	def profile = meta.protocol

	"""
		dada2_workflow.R $profile $project ${task.cpus}
	"""

}

