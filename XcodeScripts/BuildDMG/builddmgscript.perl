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


my %substitutiondictionary;

$substitutiondictionary{JNX_BUNDLE_IDENTIFIER} = $ENV{CODE_SIGN_IDENTITY};

{
	my %keyvaluedictionary = (	CFBundleShortVersionString	=>	'JNX_RELEASE_VERSION' ,
								CFBundleVersion				=>	'JNX_RELEASE_REVISION',
								JNXCommitDate				=>	'JNX_RELEASE_DATE',
								JNXCommitVersion			=>	'JNX_COMMIT_VERSION',
								JNXCommitRevision			=>	'JNX_COMMIT_REVISION',
								CFBundleIdentifier			=>	'JNX_BUNDLE_IDENTIFIER',
							);
							
	my $info = filecontentsasstring("$ENV{CONFIGURATION_BUILD_DIR}/$ENV{PROJECT_NAME}.app/Contents/Info.plist");

	while( my($key,$value) = each %keyvaluedictionary )
	{
		$substitutiondictionary{$value}=$1 if $info=~ m#<key>$key</key>\s*<string>\s*(.*?)\s*<\/string>#s
	}
	die "Can't find version in info file" if !defined $substitutiondictionary{JNX_RELEASE_VERSION};
}


my $volumename = $ENV{PROJECT_NAME}.'.'.$substitutiondictionary{JNX_RELEASE_VERSION}.'.('.$substitutiondictionary{JNX_RELEASE_REVISION}.')';

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



my $APP_WRAPPER_DIRECTORY		= $releasecopydirectory.'/'.$ENV{PROJECT_NAME}.'.app';
my $APP_RESOURCES_DIRECTORY		= $APP_WRAPPER_DIRECTORY.'/Contents/Resources';
my $SPARKLE_FILE_NAME			= $ENV{PROJECT_NAME}.'.update.xml';


my %filecontents;

foreach my $filename ( 'Release.txt', 'History.txt', 'SparkleWrapper.xml' )
{
	my $filecontent = filecontentsasstring($ENV{SOURCE_ROOT}.'/Other Resources/ReleaseHistory/'.$filename);
	
	$filecontents{$filename} = substituteStrings($filecontent,\%substitutiondictionary);
	
	unlink($APP_RESOURCES_DIRECTORY.'/'.$filename);
}


{
	my $releasetext			= $filecontents{'Release.txt'};
	my $releasehistorytext	= $filecontents{'History.txt'};

	$releasehistorytext =~ s#<body>(.*?)</body>#<body>$releasetext\n$1</body>#gs;

	writefile($APP_RESOURCES_DIRECTORY.'/ReleaseHistory.html',$releasehistorytext);
}

if( $substitutiondictionary{JNX_BUNDLE_IDENTIFIER} )
{
	system('codesign','-f','-s',$substitutiondictionary{JNX_BUNDLE_IDENTIFIER} ,$APP_WRAPPER_DIRECTORY);
}


system('hdiutil','create','-srcfolder',$releasecopydirectory,'-format','UDZO','-volname',$volumename,$intermediatedmg);


{
	my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($intermediatedmg);

	$substitutiondictionary{JNX_SPARKLE_SIGNATURE_ATTRIBUTE}	= sparkleSignatureAttribute($substitutiondictionary{JNX_BUNDLE_IDENTIFIER},$intermediatedmg);
	$substitutiondictionary{JNX_RELEASE_TEXT}					= $filecontents{'Release.txt'};;
	$substitutiondictionary{JNX_SPARKLE_SIZE}					= $size;

	writefile( $finaldirectory.'/'.$SPARKLE_FILE_NAME, substituteStrings($filecontents{'SparkleWrapper.xml'},\%substitutiondictionary) );
}


system('mv',$intermediatedmg,$finaldirectory.'/');
system('hdiutil','create','-srcfolder', $finaldirectory,'-format','UDBZ','-volname',$volumename.'.final',$finaldmg);



exit 0; # EXIT_SUCCESS;



sub writefile($$)
{
	my($filename,$content) = @_;
	
	local $\=undef;
	open(FILE,'>'.$filename) || die "Can't open file $filename for writing $!";
	print FILE $content;
	close(FILE);
}

sub filecontentsasstring($)
{	
	my($filename) = @_;

	local $/=undef;
	open(FILE,$filename) || die "Can't open file $filename for reading $!";
	my $filecontent = join('',<FILE>);
	close(FILE);
	
	return $filecontent;
}

sub substituteStrings($$)
{
	my($content,$substitutiondictionary) = @_;
	
	while( my($key,$value) = each %{$substitutiondictionary} )
	{
		$content	=~ s/$key/$value/g;
	}
	
	return $content;
}

sub substituteStringsInFile($$)
{
	my($filename,$substitutiondictionary) = @_;

	my $filecontent = filecontentsasstring($filename);
	
	writefile($filename,substituteStrings($filecontent,$substitutiondictionary));
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




