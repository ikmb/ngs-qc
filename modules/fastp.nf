process FASTP {

	tag "${project}|${reads[0]}"

	label 'fastp'

	input:
	tuple val(project),val(lib),path(reads)

	output:
	tuple val(project),path(ltrim),path(rtrim), emit: reads
	path(json), emit: json

	script:
	def lreads = reads[0]
	def rreads = reads[1]
	def lib = lreads.getName().split("_R")[0]
	ltrim = file(lreads).getSimpleName() + "_trimmed.fastq.gz"
        rtrim = file(rreads).getSimpleName() + "_trimmed.fastq.gz"
        json = file(lreads).getSimpleName() + ".fastp.json"
        html = file(lreads).getSimpleName() + ".fastp.html"
	
	"""
		fastp -c --in1 $lreads --in2 $rreads --out1 $ltrim --out2 $rtrim --detect_adapter_for_pe -w ${task.cpus} -j $json -h $html --length_required 35 --reads_to_process 150000
	"""

}
