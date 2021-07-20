# == USAGE
# ./partition_multiqc.rb [ -h | --help ]
#[ -i | --infile ] |[ -o | --outfile ] |
# == DESCRIPTION
# Run MultiQC on subset of files based on common grouping variable
#
# == OPTIONS
# -h,--help Show help
# -i,--infile=INFILE input file
# -o,--outfile=OUTFILE : output file

#
# == EXPERT OPTIONS
#
# == AUTHOR
#  Marc Hoeppner, mphoeppner@gmail.com

require 'optparse'
require 'ostruct'

### Define modules and classes here

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "A script description here"
opts.separator ""
opts.on("-c","--chunk", "=CHUNK","Chunk size") {|argument| options.chunk = argument }
opts.on("-b","--title", "=TITLE","Report title") {|argument| options.title = argument }
opts.on("-k","--config", "=CONFIG","QC config") {|argument| options.config = argument }
opts.on("-n","--name", "=NAME","Name of project") {|argument| options.name = argument }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse!

files = Dir["*_001*"]

grouped = files.group_by {|f| f.split(/_[RI][0-9]_/)[0] }

options.chunk ? chunk = options.chunk.to_i : chunk = 100

grouped.each_slice(chunk) do |slice|

	all_reports = []
	groups = []
	slice.each do |g,reports|
		groups << g
		reports.each {|r| all_reports << r }		
	end
	first_lib = groups.sort[0]
	last_lib = groups.sort[-1]
	command = "multiqc -n multiqc_report_#{first_lib}-#{last_lib}_#{options.name}.html -b #{options.title} -c #{options.config} #{all_reports.join(' ')}"
	system(command)
end
