process FASTQ_SCREEN {

	tag "${project}|${fastq}"

	input:
	tuple val(project),path(fastq)

	output:
	tuple val(project),path("*_screen.txt"), emit: qc

	script:

	"""
		fastq_screen --force --subset 200000 --conf ${params.fastq_screen_config} --aligner bowtie2 $fastq
	"""

}
