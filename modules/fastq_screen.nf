process FASTQ_SCREEN {

	tag "${project}|${fastq}"

	input:
	set val(project),path(fastq)

	output:
	set val(project),path("*_screen.txt"), emit: text

	script:

	"""
		fastq_screen --force --subset 200000 --conf ${params.fastq_screen_config} --aligner bowtie2 $fastq
	"""

}
