#!/usr/bin/perl
#
# author: 	Patrick Stein aka Jolly
# purpose:	This used to create my dmg files via git when I build.
#
use strict;


use POSIX;
$ENV{PATH}.=':/usr/local/git/bin';


die "$0: Must be run from Xcode" unless $ENV{BUILT_PRODUCTS_DIR};

if( $ENV{BUILD_STYLE} ne 'Release' )
{
	print STDERR "$0: Only Release creates dmg\n";
	exit;
}
else
{
	print STDERR "Release Style\n\n\n";
}


my $INFO = "$ENV{CONFIGURATION_BUILD_DIR}/$ENV{PROJECT_NAME}.app/Contents/Info.plist";

open(FH, "$INFO") or die "$0: $INFO: $!";
my $info = join("", <FH>);
close(FH);

my $version 			= $1 if $info =~ m#<key>CFBundleShortVersionString</key>\s*<string>\s*(.*?)\s*<\/string>#s;
my $revision			= $1 if $info =~ m#<key>CFBundleVersion</key>\s*<string>\s*(.*?)\s*<\/string>#s;
my $jnxcommitdate 		= $1 if $info =~ m#<key>JNXCommitDate</key>\s*<string>\s*(.*?)\s*<\/string>#s;
my $jnxcommitrevision 	= $1 if $info =~ m#<key>JNXCommitRevision</key>\s*<string>\s*(.*?)\s*<\/string>#s;
my $jnxcommitversion 	= $1 if $info =~ m#<key>JNXCommitVersion</key>\s*<string>\s*(.*?)\s*<\/string>#s;

my $bundleid= $ENV{CODE_SIGN_IDENTITY};

if( !length($bundleid) )
{
	$bundleid=$1 if $info =~ m#<key>CFBundleIdentifier</key>\s*<string>\s*(.*?)\s*<\/string>#s;
}

die "Can't find version info" if ! $version;

{
	open(FILE,$ENV{SOURCE_ROOT}.'/Other Resources/ReleaseHistory/Release.txt') || die "Can't open Release file";
	my $JNX_RELEASE_TEXT = join('',<FILE>);
	close(FILE);


	open(FILE,$ENV{SOURCE_ROOT}.'/Other Resources/ReleaseHistory/SparkleWrapper.xml') || die "Can't open SparkleWrapper file";
	my $sparklewrappertext = join('',<FILE>);
	close(FILE);

	open(FILE,$ENV{SOURCE_ROOT}.'/Other Resources/ReleaseHistory/History.txt') || die "Can't open ReleaseHistory file";
	my $releasehistorytext = join('',<FILE>);
	close(FILE);


	my $JNX_RELEASE_DATE		= $jnxcommitdate;
	my $JNX_RELEASE_REVISION	= $revision;
	my $JNX_RELEASE_VERSION		= $version;

	$JNX_RELEASE_TEXT =~ s/JNX_RELEASE_DATE/$JNX_RELEASE_DATE/g;
	$JNX_RELEASE_TEXT =~ s/JNX_RELEASE_REVISION/$JNX_RELEASE_REVISION/g;
	$JNX_RELEASE_TEXT =~ s/JNX_RELEASE_VERSION/$JNX_RELEASE_VERSION/g;
	
	$sparklewrappertext =~ s/JNX_RELEASE_TEXT/$JNX_RELEASE_TEXT/g;
	$sparklewrappertext =~ s/JNX_RELEASE_DATE/$JNX_RELEASE_DATE/g;
	$sparklewrappertext =~ s/JNX_RELEASE_REVISION/$JNX_RELEASE_REVISION/g;
	$sparklewrappertext =~ s/JNX_RELEASE_VERSION/$JNX_RELEASE_VERSION/g;

	$releasehistorytext =~ s#<body>(.*?)</body>#<body>$JNX_RELEASE_TEXT\n$1</body>#gs;

	open(FILE,'>'.$ENV{BUILT_PRODUCTS_DIR}.'/'.$ENV{PROJECT_NAME}.'.update.xml') || die "Can't write SparkleWrapper file";
	print FILE $sparklewrappertext;
	close(FILE);

	open(FILE,'>'.$ENV{BUILT_PRODUCTS_DIR}.'/'.'ReleaseHistory.html') || die "Can't write ReleaseHistory file";
	print FILE $releasehistorytext;
	close(FILE);
}

my $volumename = $ENV{PROJECT_NAME}.'.'.$version.'.('.$revision.')';

my $DMG_DIRECTORY			= $ENV{TEMP_DIR}.'/dmg';
my $finaldirectory			= $DMG_DIRECTORY.'/final';
my $releasecopydirectory	= $DMG_DIRECTORY.'/release';

my $intermediatedmg	 		= $DMG_DIRECTORY.'/'.$volumename.'.dmg';
my $finaldmg				= $ENV{TEMP_ROOT}.'/'.$volumename.'.final.dmg';


# die "$DMG_DIRECTORY";

system('find',$ENV{TEMP_DIR},'-maxdepth','1','-type','d','-name','dmg','-exec','rm','-rf','{}',';');
system('rm','-rf',$finaldmg);

system('mkdir',$DMG_DIRECTORY);
system('mkdir',$finaldirectory);
system('mkdir',$releasecopydirectory);
`cd "$ENV{CONFIGURATION_BUILD_DIR}" ; tar -cf - . | ( cd "$releasecopydirectory"; tar -xf -) `;


system('find',$releasecopydirectory,'-maxdepth','1','-type','d','-name','*.dSYM','-exec','mv','{}',$finaldirectory.'/',';');
system('find',$releasecopydirectory,'-maxdepth','1','-type','f','-name','*.update.xml','-exec','mv','{}',$finaldirectory.'/',';');
system('find',$releasecopydirectory,'-type','f','-name','*.h','-exec','rm','-rf','{}',';');
system('find',$releasecopydirectory,'-type','f','-perm','0755','-name',$ENV{PROJECT_NAME},'-exec','strip','{}',';');
# system('find',$releasecopydirectory,'-maxdepth','1','-type','f','-perm','755','-exec','rm','-rf','{}',';');
system('codesign','-f','-s',$bundleid,$releasecopydirectory.'/'.$ENV{PROJECT_NAME}.'.app');


system('hdiutil','create','-srcfolder',$releasecopydirectory,'-format','UDZO','-volname',$volumename,$intermediatedmg);
system('mv',$intermediatedmg,$finaldirectory.'/');
system('hdiutil','create','-srcfolder', $finaldirectory,'-format','UDBZ','-volname',$volumename.'.final',$finaldmg);



