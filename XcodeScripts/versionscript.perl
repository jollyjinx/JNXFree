#!/usr/bin/perl
#
# author: 	Patrick Stein aka Jolly
# purpose:	This used to create my Info.plist files via git when I build.
# 			the info panel whill show then something like: 0.96.76 (901415) 
#			also the sparkleversion is used for the sparkle file
use strict;

use POSIX;
$ENV{PATH}.=':/usr/local/git/bin';


####
# create $commitrevision variable via GIT
####

my $commitrevision;		# something like '96b4e3e' in git
my $commitversion;	 	# something like '901415M' ( meaning 2009 = 9, 014 = day forteen of year, 15'th commit of that day, if a M is appended than the last diffs are not committed
my $commitdate;	 		# something like 
{
	die "$0: Source directory not git backed" unless $ENV{SOURCE_ROOT};
	use Cwd;
	my $currentdir = Cwd::getcwd();

	chdir($ENV{SOURCE_ROOT});
	{
		my ($gitshortrevision,$gitseconds,$gitshortdate)	= split(/\s/, `git log -1 --pretty='format:%h %ct %cd' --date=short .` );

		
		my $gitcountofday	= `git log --since="$gitshortdate" --pretty=oneline . |wc -l`;
		chomp $gitcountofday;

		my $modifiedoutput 	= `git ls-files -t -m -d -o --exclude-standard`;
		
		$commitrevision 	= $gitshortrevision.($modifiedoutput !~ m/^\s*$/?'M':'');
		$commitversion		= sprintf("%d%02d",POSIX::strftime("%g%j",localtime($gitseconds)),$gitcountofday).($modifiedoutput !~ m/^\s*$/?'M':'');
		$commitdate			= POSIX::strftime("%+",localtime($gitseconds))
	}

	chdir($currentdir);
}
print STDERR "Revision: $commitrevision\n";
print STDERR "Version: 	$commitversion\n";
print STDERR "Date: 	$commitdate\n";


####
# rewrite Info.plist
####
my $version;	# something like 1.00

{
	die "$0: Source directory not git backed" unless $commitrevision || $commitversion || $ENV{BUILT_PRODUCTS_DIR} || $ENV{INFOPLIST_PATH};

	# Get the current subversion revision number and use it to set the CFBundleVersion value

	my $infoplistfilename 	= $ENV{BUILT_PRODUCTS_DIR}.'/'.$ENV{INFOPLIST_PATH};
	
	open(FH, $infoplistfilename) || die "$0: $infoplistfilename: $!";
	my $infofilecontent = join('', <FH>);
	close(FH);
	
	my $JNXSpecialKeys;
	$JNXSpecialKeys		.= "\n<key>JNXCommitDate</key><string>$commitdate</string>\n";
	$JNXSpecialKeys		.= "\n<key>JNXCommitRevision</key><string>$commitrevision</string>\n";
	$JNXSpecialKeys		.= "\n<key>JNXCommitVersion</key><string>$commitversion</string>\n";
	
	$version = $1 if $infofilecontent =~ m#<key>CFBundleShortVersionString</key>\s*<string>\s*(.*?)\s*<\/string>#s;
	$infofilecontent =~ s/([\t ]+<key>CFBundleVersion<\/key>\n[\t ]+<string>).*?(<\/string>)/$1$commitversion$2$JNXSpecialKeys/;
	
	open(FH, '>'. $infoplistfilename ) or die "$0: $infoplistfilename: $!";
	print FH $infofilecontent;
	close(FH);
}
print STDERR "Version: $version\n";
