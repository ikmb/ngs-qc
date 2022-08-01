process BIOBLOOM_CATEGORIZER {

	tag "${project}|${library}"

	input:
	tuple val(project),val(library),path(left),path(right)

	output:
	tuple val(project),path(results), emit: results

	script:
	results = library + "_summary.tsv"

	"""
		biobloomcategorizer -p $library -t ${task.cpus} -e -f "${params.bloomfilter}" $left $right
	"""	
}
