process FASTQ_SCREEN {

	tag "${project}|${left}"

	input:
	tuple val(project),path(left),path(right)

	output:
	tuple val(project),path("*_screen.txt"), emit: qc

	script:

	"""
		fastq_screen --threads ${task.cpus} --force --subset 100000 --conf ${params.fastq_screen_config} --aligner bowtie2 $left
	"""

}
