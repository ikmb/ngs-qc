process CUTADAPT {
 
   tag "${project}|${reads[0]}"

    //publishDir "${params.outdir}/${project}/cutadapt", mode: 'copy'

    container 'quay.io/biocontainers/cutadapt:3.4--py39h38f01e4_1'

    input:
    tuple val(project),val(meta), path(reads)

    output:
    tuple val(project),val(meta), path('*.trim.fastq.gz'), emit: reads
    tuple val(meta), path('*.log')          , emit: log

    script:
    def prefix = reads[0].getSimpleName().split("_R[1,2]")[0]
    def trimmed  = "-o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz"
    def args = ""
      
    if ( meta.primers.contains("V1-V2") || meta.primers.contains("Fungi") ) {
       args = "-g ${meta.FWD} -G ${meta.REV}"
    } else if ( meta.primers.contains("V3-V4") || meta.primers.contains("archaea") ) {
       args = "-g ${meta.FWD} -a ${meta.REV_RC} -G ${meta.REV} -A ${meta.FWD_RC}"
    }
	
    """
    cutadapt \\
        --cores $task.cpus \\
        $args \\
        $trimmed \\
        $reads \\
        > ${prefix}.cutadapt.log
    """
}

