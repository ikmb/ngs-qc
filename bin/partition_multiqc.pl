#!/usr/bin/env perl

use strict;
use Getopt::Long;

my $usage = qq{
perl my_script.pl
  Getting help:
    [--help]

  Input:
    [--chunk int]
		Size of each chunk

    [--title STR]
		Title of the report

    [--config FILE]
		Name of the config 

    [--name STR]
		LIMS Project name

};

my $outfile = undef;
my $chunk = 100;
my $title = undef;
my $name = undef;
my $config = undef;

my $help;

GetOptions(
    "help" => \$help,
    "chunk=i" => \$chunk,
    "title=s" => \$title,
    "config=s" => \$config,
    "name=s" => \$name);

# Print Help and exit
if ($help) {
    print $usage;
    exit(0);
}


my @files = glob("*.tsv *.zip *_mqc.out") ;
my %bucket;

die "Must provide a name (--name) and title (--title)!\n" unless (defined $name && defined $title);
my @general;

foreach my $file (@files) {

	my $trunk = "";

	if ($file =~ /.*_mqc.out/) {
		push(@general,$file);
	} elsif ($file =~ /.*_summary.tsv/) {
		$trunk = (split /_summary/, $file)[0];
	} elsif ($file =~ /.*_[RI][0-9]_001.*/) {
		$trunk = (split /_[RI][0-9]_001/, $file)[0] ;
	} else {
		$trunk = (split /\./, $file)[0];
	}	
	next if ($trunk eq "");

	if (exists $bucket{$trunk}) {
		push( @{ $bucket{$trunk} }, $file )
	} else {
		$bucket{$trunk} = [ $file ];
	}

}

my @output;
my $counter = 0;
my $first_key = undef;
my $this_key = undef;

foreach my $key (sort keys %bucket ) {

	unless (defined $first_key) {
		$first_key = $key ;
	}

	my @entries = @{ $bucket{$key} } ;

	if ($counter > $chunk) {
	
		foreach my $g (@general) {
                	push(@output,$g);
        	}
		printf STDERR "Counter is: " .  $counter . "\n";
		my $file_name = "multiqc_report_" . $name . "_" . $first_key . "-" . $this_key . ".html" ;
		
		run_multiqc($file_name,$title,$config,@output);

		@output = ();
		$counter = 0;
		$first_key = $key ;

	}

	$counter += 1;

	foreach my $e (@entries) {
		push(@output,$e);
	}

	$this_key = $key;

}

my $file_name = "multiqc_report_" . $name . "_" . $first_key . "-" . $this_key . ".html";
run_multiqc($file_name,$title,$config,@output);

sub run_multiqc {

	my($file_name,$title,$config,@entries) = @_ ;

	open(FILE,'>', "files.txt");

	foreach my $e (@entries) {
		printf FILE $e . "\n";
	}

	close(FILE);

	my $command = "multiqc -n $file_name -b \"" . $title . "\" -c $config --file-list files.txt" ;
	system($command);

}	

