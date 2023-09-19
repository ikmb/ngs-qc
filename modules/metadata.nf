process METADATA {

	tag "${project}"

	container 'ikmb/ngs-qc:devel'

        publishDir "${prams.outdir}/${project}", mode: 'copy'

	input:
	val(project)

	output:
	val("*.xlsx"), emit: xlsx

	script:

	"""
		/work_ifs/ikmb_repository/development/project_to_metadata.rb -p $project -s 1 
	"""
}
