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


my $info = filecontentsasstring("$ENV{CONFIGURATION_BUILD_DIR}/$ENV{PROJECT_NAME}.app/Contents/Info.plist");

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

my %substitutiondictionary = (	JNX_RELEASE_DATE		=> $jnxcommitdate,
								JNX_RELEASE_REVISION	=> $revision,
								JNX_RELEASE_VERSION		=> $version
							);
foreach my $filename ('/Other Resources/ReleaseHistory/Release.txt','/Other Resources/ReleaseHistory/History.txt' )
{
	substituteStringsInFile($ENV{SOURCE_ROOT}.$filename, \%substitutiondictionary);
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

if( $bundleid )
{
	system('codesign','-f','-s',$bundleid,$releasecopydirectory.'/'.$ENV{PROJECT_NAME}.'.app');
}


system('hdiutil','create','-srcfolder',$releasecopydirectory,'-format','UDZO','-volname',$volumename,$intermediatedmg);


{
	my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($intermediatedmg);

	$substitutiondictionary{JNX_SPARKLE_SIGNATURE_ATTRIBUTE}	= sparkleSignatureAttribute($bundleid,$intermediatedmg);
	$substitutiondictionary{JNX_SPARKLE_TEXT}					= filecontentsasstring($ENV{SOURCE_ROOT}.'/Other Resources/ReleaseHistory/Release.txt');
	$substitutiondictionary{JNX_SPARKLE_SIZE}					= $size;


	substituteStringsInFile($finaldirectory.'/'.$ENV{PROJECT_NAME}.'.update.xml', \%substitutiondictionary);
}




system('mv',$intermediatedmg,$finaldirectory.'/');
system('hdiutil','create','-srcfolder', $finaldirectory,'-format','UDBZ','-volname',$volumename.'.final',$finaldmg);



exit 0; # EXIT_SUCCESS;





sub filecontentsasstring($)
{	
	my($filename) = @_;

	local $/=undef;
	open(FILE,$filename) || die "Can't open file $filename for reading $!";
	my $filecontent = join('',<FILE>);
	close(FILE);
	
	return $filecontent;
}



sub substituteStringsInFile($$)
{
	my($filename,$substitutiondictionary) = @_;

	my $filecontent = filecontentsasstring($filename);
	
	while( my($key,$value) = each %{$substitutiondictionary} )
	{
		$filecontent	=~ s/$key/$value/g;
	}
	
	local $\=undef;
	open(FILE,'>'.$filename) || die "Can't open file $filename for writing $!";
	print FILE $filecontent;
	close(FILE);
}



sub sparkleSignatureAttribute($$)
{
	my ($bundleid,$intermediatedmg) = @_;
	my $signature = undef;

	my $privatekeyfromkeychain = filecontentsasstring('security find-generic-password -g -l "'.$bundleid.'.sparkle" 2>&1 |');

	my $privatekey = undef;

	if( $privatekeyfromkeychain =~ m/(-----BEGIN DSA PRIVATE KEY-----.*-----END DSA PRIVATE KEY-----)/s )
	{
		$privatekey = $1;
		$privatekey =~s/\\012/\n/g;	
	}
	else
	{
		print "Can't extract private key from keychain. Name we looked for is $bundleid.sparkle - assuming it should not be signed.";
		return undef;
	}

	use IPC::Open2;
	

	system('openssl dgst -sha1 -binary "'.$intermediatedmg.'" > "'.$intermediatedmg.'.digest"');
	local $/=undef;


	my($chld_out, $chld_in);
	open2($chld_out, $chld_in,'openssl dgst -dss1 -sign /dev/stdin -keyform PEM "'.$intermediatedmg.'.digest"') || die "can't create signature for $intermediatedmg";
	print $chld_in $privatekey."\n";
	close($chld_in);
	
	my $signaturehex;
	while( $_ = <$chld_out> )
	{
		$signaturehex .= $_;
	}
	close($chld_out);

	 my($chld_out, $chld_in);
	open2($chld_out, $chld_in,'openssl enc -base64') || die "can't create signature for $intermediatedmg";
	print $chld_in $signaturehex;
	close($chld_in);
	
	$signature = join('',<$chld_out>);
	$signature =~ s/\s+//gs;
	close($chld_out);


	if(length($signature)<1)
	{
		die "Signature empty";
	}
	print "Got signature: ".$signature."\n";
	
	return 'sparkle:dsaSignature="'.$signature.'"';
}




