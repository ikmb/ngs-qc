process METADATA {

	tag "${project}"

	container 'ikmb/ngs-qc:1.7'

        publishDir "${params.outdir}/${project}", mode: 'copy'

	input:
	tuple val(project),path(fastqs)

	output:
	path("*.xlsx"), emit: xlsx

	script:

	"""
		/work_ifs/ikmb_repository/development/project_to_metadata.rb -p $project -s 1 
	"""
}
