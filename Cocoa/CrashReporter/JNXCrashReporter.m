//
//  JNXCrashReporter.m
//  JollysFastVNC
//
//  Created by Patrick  Stein on 23.11.07.
//  Copyright 2007 jinx.de. All rights reserved.
//

#import "JNXCrashReporter.h"
#include <unistd.h>

#define JNX_CRASHREPORTER_DEFAULTS_DATEKEY		@"JNXCrashReporter.lastCrashTestDate"
#define JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY	@"JNXCrashReporter.lastCrashVersion"
#define JNX_CRASHREPORTER_SUBJECTKEY			@"JNXCrashReporter.subject"
#define JNX_CRASHREPORTER_MAILTOKEY				@"JNXCrashReporter.mailto"

@implementation JNXCrashReporter

+ (void)testForCrashWithBodyString:(NSString *)mailbodyString
{
	#if !defined(NDEBUG) || (DEBUG >0)
		#warning not using Crashreporter in debug compiles 
		return;
	#endif
	NSDate	*lastReportedDate;
	NSString *logfileName			=  [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] processName] stringByAppendingPathExtension:@"log"]];
	NSString *previousLogfileName	= [logfileName stringByAppendingPathExtension:@"1"];

	[[NSFileManager defaultManager] removeFileAtPath:previousLogfileName handler:nil];
	if( [[NSFileManager defaultManager] movePath:logfileName toPath:previousLogfileName handler:nil] )
	{
		int filenumber = open([logfileName fileSystemRepresentation],O_CREAT| O_APPEND|O_TRUNC| O_WRONLY, 0666);
		if( filenumber >= 0 )
		{
			close(STDERR_FILENO);
			dup2(filenumber, STDERR_FILENO);
			close(filenumber);
		}
	}
	else
	{
		JLog(@"Could not move logfile %@ %@",logfileName,previousLogfileName);
	}
	
	if( nil == mailbodyString )
	{
		mailbodyString	= [NSString stringWithFormat:@"Hello Jolly,\n\n%@ crashed on me the last time while\nI was connecting my .... server.\nI was doing .... at the time.\n\nRegards %@\n\n\n\n\n\n\n\nCrashlog follows:\n",[[NSProcessInfo processInfo] processName],NSFullUserName()];
	}
	
	if(		(![[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_MAILTOKEY])
		||	(![[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_SUBJECTKEY]) )
	{
		JLog(@"did not find %@ or %@",JNX_CRASHREPORTER_MAILTOKEY,JNX_CRASHREPORTER_SUBJECTKEY);
		return;
	}
	
	if( ![[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey: JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY]] )
	{
		JLog(@"did not find correct version.");
		
		[[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] forKey: JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY];
		[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY];
		return;
	}
	
	
	
	if( nil == (lastReportedDate = [[NSUserDefaults standardUserDefaults] objectForKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY]) )
	{
		lastReportedDate = [NSDate distantPast];
	}

  
	NSString	*lastCrashReportFilename = [self lastCrashReportFilename];
	NSDate		*lastCrashReportDate;
 	DJLog(@"%@",lastCrashReportFilename);
 
	if(		(nil != lastCrashReportFilename)
		&&	(nil != (lastCrashReportDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[self lastCrashReportFilename] traverseLink: YES] fileModificationDate]) )
		&&  (NSOrderedAscending == [lastReportedDate compare: lastCrashReportDate]))
	{
		DJLog(@"has a new crashreport: %@",lastCrashReportFilename);
		
		NSString *alertString = [NSString stringWithFormat:@"%@ has crashed the last time.\nTo improve %@ send the developer a mail.\n",[[NSProcessInfo processInfo] processName],[[NSProcessInfo processInfo] processName]];
		int alertreturn = [[NSAlert alertWithMessageText:@"Crashlog detected" defaultButton:@"Send Mail" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:alertString] runModal];
				
		switch( alertreturn )
		{
			case NSAlertDefaultReturn	:
			{
				NSString *mailString = [NSString stringWithFormat:@"mailto:%@?subject=%@ (%@ %@ %s %@)&body=%@\n%@\nLogfilecontents:\n%@\n",[[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_MAILTOKEY]
																											,[[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_SUBJECTKEY]
																											,[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"]
																											,[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"]
																											,((CFByteOrderBigEndian==CFByteOrderGetCurrent())?"PPC":"i386")
																											,[[NSProcessInfo processInfo] operatingSystemVersionString]
																											,mailbodyString
																											,[NSString stringWithContentsOfFile:lastCrashReportFilename]
																											,[NSString stringWithContentsOfFile:previousLogfileName]];
													
				NSURL *url = [NSURL URLWithString:[(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailString, NULL, NULL, kCFStringEncodingISOLatin1) autorelease]];
				[[NSWorkspace sharedWorkspace] openURL:url];
			};break;
		}
		[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY];
	}
}



+ (NSString*) lastCrashReportFilename
{
	DJLOG;
		
	NSString				*crashlogFilename		= nil;
	NSDate					*crashlogDate			= [NSDate distantPast];
	
	NSString				*crashlogPathname		= [[[NSHomeDirectory() stringByAppendingPathComponent: @"Library"] stringByAppendingPathComponent: @"Logs"] stringByAppendingPathComponent:@"CrashReporter"];
	NSDirectoryEnumerator	*directoryEnumerator	= [[NSFileManager defaultManager]  enumeratorAtPath:crashlogPathname];
	
	NSString				*intermediateCrashlogFilename;
	
	while( intermediateCrashlogFilename = [directoryEnumerator nextObject] ) 
	{
		NSDictionary	*fileAttributes = [directoryEnumerator fileAttributes];
		
		//DJLog(@"testing: %@",intermediateCrashlogFilename);
		
		if( NSFileTypeDirectory == [fileAttributes objectForKey:NSFileType] )
		{
			[directoryEnumerator skipDescendents];
			continue;
		}
		
		if(		[intermediateCrashlogFilename hasPrefix:[NSString stringWithFormat:@"%@_",[[NSProcessInfo processInfo] processName]]]
			&&	[[intermediateCrashlogFilename pathExtension] isEqualToString:@"crash"]
			&&	(NSOrderedAscending == [(NSDate *)crashlogDate compare:[fileAttributes objectForKey:NSFileModificationDate]] ) )
		{
			//DJLog(@"Found newer crashlog: %@",intermediateCrashlogFilename);
			
			crashlogFilename	= intermediateCrashlogFilename;
			crashlogDate		= [fileAttributes objectForKey:NSFileModificationDate];
		}
    }

	if( ! crashlogFilename )
	{
		//DJLog(@"Did not find crashlog");
		return nil;
	}
	
	return [crashlogPathname stringByAppendingPathComponent:crashlogFilename];
}



@end
