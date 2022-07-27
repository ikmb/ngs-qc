process BIOBLOOM_CATEGORIZER {

	container "docker://ikmb/outbreak-monitoring:latest"

	tag "${project}|${library}"

	input:
	tuple val(project),val(library),path(reads)

	output:
	tuple val(project),path(results), emit: results

	script:
	results = library + "_summary.tsv"

	"""
		zcat $reads[0] | head -n 400000 | gzip -c > left.fq.gz
		zcat $reads[1] | head -n 400000 | gzip -c > right.fq.gz

		biobloomcategorizer -p $library -t ${task.cpus} -e -f "${params.bloomfilter}" left.fq.gz right.fq.gz
		rm left.fq.gz right.fq.gz
	"""	
}
