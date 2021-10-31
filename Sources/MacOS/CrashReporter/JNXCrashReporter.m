//
//  JNXCrashReporter.m
//  JollysFastVNC
//
//  Created by Patrick  Stein on 23.11.07.
//  Copyright 2007 jinx.de. All rights reserved.
//
#import <JNXFree.h>

#import "JNXCrashReporter.h"

#import "osversion.h"
#include <unistd.h>
#include <unistd.h>

#define JNX_CRASHREPORTER_MAILTOKEY               @"JNXCrashReporter.mailto"

#define JNX_CRASHREPORTER_DEFAULTS_DATEKEY        @"JNXCrashReporter.lastCrashTestDate"
#define JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY     @"JNXCrashReporter.lastCrashVersion"
#define JNX_CRASHREPORTER_BODYTEXT                @"Please describe the circumstances leading to the crash and any other relevant information:\n\n\n\n\n\n\nCrashlog follows:\n"


@interface  NSObject(SharedLicenseClass)
+ sharedLicense;
- jnxLicense;
- isAppStoreVersion;
@end



@implementation JNXCrashReporter

static     BOOL         uselogfile = YES;

+ (void)load
{
    DJLOG

    #if DEBUG >0
    {
        char     hostname[1024];
        size_t    hostnamelength = sizeof( hostname );
    
        if( 0 == gethostname(hostname,hostnamelength) )
        {
            char *developmenthostname = "tinkerbell.";

            if( (strlen(hostname)>=strlen(developmenthostname) ) && (0 == strncmp(developmenthostname,hostname,strlen(developmenthostname)) ))
            {
                JLog(@"Using no logfile as hostname is %s",hostname);
                uselogfile = NO;
                return;
            }
        }
    }
    #endif
}

+ (NSString *)logFileName
{
    DJLOG
    
    if( !uselogfile )
    {
        return nil;
    }
    
    static    NSString        *logfileName    = nil;
    static    dispatch_once_t onceToken         = 0;
    
    dispatch_once(&onceToken,
    ^{
        Class    SharedLicenseClass    =  NSClassFromString(@"SharedLicense");

        logfileName                    = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] processName] stringByAppendingPathExtension:@"log"]];
        
        if( SharedLicenseClass )
        {
            id sharedLicense     = [SharedLicenseClass sharedLicense];
            id jnxLicense        = [sharedLicense jnxLicense];
            
            if( [jnxLicense isAppStoreVersion] )
            {
                NSString        *applicationSupportDirectory    = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
                NSFileManager    *fileManager                    = [NSFileManager defaultManager];
                if( ![fileManager fileExistsAtPath:applicationSupportDirectory])
                {
                    NSError *error;
                
                    if( ! [fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error] )
                    {
                        JLog(@"Could not create directory: %@",error);
                    }
                }
                logfileName = [applicationSupportDirectory stringByAppendingPathComponent:[[[NSProcessInfo processInfo] processName] stringByAppendingPathExtension:@"log"]];
            }
        }
        DJLog(@"logFileName: %@",logfileName);
    });
    return logfileName;
}

+ (void)startLogging
{
    DJLOG
    NSString    *logfileName    = [self logFileName];
    DJLog(@"uselogfile:%d logfileName:%@",uselogfile,logfileName);

    if(!logfileName)
    {
        return;
    }

    // logfile rotation
    {
        int maximumlogfilenumber = 9;

        for( int i=maximumlogfilenumber; i>0; i--)
        {
            NSString    *previousLogfileName    = [logfileName stringByAppendingPathExtension:[NSString stringWithFormat:@"%d",i-1]];
            NSString    *newLogFilename            = [logfileName stringByAppendingPathExtension:[NSString stringWithFormat:@"%d",i]];

            if( maximumlogfilenumber==i )
            {
                [[NSFileManager defaultManager] removeItemAtPath:newLogFilename error:nil];
            }
            if( 1 == i )
            {
                previousLogfileName    = logfileName;
            }

            NSError *error;
            if( [[NSFileManager defaultManager] fileExistsAtPath:previousLogfileName] && ![[NSFileManager defaultManager] moveItemAtPath:previousLogfileName toPath:newLogFilename error:&error] )
            {
                JLog(@"Could not move logfile %@ %@ %@",previousLogfileName,newLogFilename,error);
            }
        }
    }

    int filenumber = open([logfileName fileSystemRepresentation],O_CREAT| O_APPEND|O_TRUNC| O_WRONLY, 0666);
    if( filenumber >= 0 )
    {
        close(STDERR_FILENO);
        dup2(filenumber, STDERR_FILENO);
        close(filenumber);
    }
    else
    {
        JLog(@"Could not open logfile %@",logfileName);
    }
    JLog(@"Logfiles rotated, logging started.");
}


+ (void)testForCrashWithBodyString:(NSString *)givenMailbodyString
{
    DJLOG
    [self startLogging];

    dispatch_async(dispatch_get_main_queue(),
    ^{
        DJLOG
        
        NSString    *mailbodyString         = givenMailbodyString;
        NSDate      *lastReportedDate;
        NSString    *logFilename            = [self logFileName];
        NSString    *previousLogfileName    = [logFilename stringByAppendingPathExtension:@"1"];

        if( nil == mailbodyString )
        {
            mailbodyString    = JNX_CRASHREPORTER_BODYTEXT;
        }
        
        if(    ![[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_MAILTOKEY] )
        {
            JLog(@"Did not find mail address for crashreports in Info.plist: %@",JNX_CRASHREPORTER_MAILTOKEY);
            return;
        }
        
        if( ![[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey: JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY]] )
        {
            JLog(@"Did not find crashreport for this program version. - that's good.");
        
            [[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"] forKey: JNX_CRASHREPORTER_DEFAULTS_VERSIONKEY];
            [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY];
            if( ! [[NSUserDefaults standardUserDefaults] synchronize] )
            {
                JLog(@"Could not synchronize defaults.");
            }
            return;
        }
        
        
        if( nil == (lastReportedDate = [[NSUserDefaults standardUserDefaults] objectForKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY]) )
        {
            lastReportedDate = [NSDate distantPast];
        }

      
        NSString    *lastCrashReportFilename = [self lastCrashReportFilename];
        NSDate        *lastCrashReportDate;
        DJLog(@"lastCrashReportFilename: %@",lastCrashReportFilename);
     
        if(        (nil != lastCrashReportFilename)
            &&    (nil != (lastCrashReportDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[self lastCrashReportFilename] error:nil] fileModificationDate]) )
            &&  (NSOrderedAscending == [lastReportedDate compare: lastCrashReportDate]))
        {
            DJLog(@"has a new crashreport: %@ lastReportDate:%@ lastCrashReportDate:%@",lastCrashReportFilename,lastReportedDate,lastCrashReportDate);
        
            NSString *alertString = [NSString stringWithFormat:@"%@ has crashed the last time.\nTo improve %@ send the developer a mail.\n",[[NSProcessInfo processInfo] processName],[[NSProcessInfo processInfo] processName]];
            NSInteger alertreturn = [[NSAlert alertWithMessageText:NSLocalizedString(@"Crashlog detected",nil) defaultButton:@"Send Mail" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"%@",alertString] runModal];
        
            switch( alertreturn )
            {
                case NSAlertDefaultReturn    :
                {
                    NSString    *mailToString    = [[[NSBundle  mainBundle] infoDictionary] objectForKey: JNX_CRASHREPORTER_MAILTOKEY];
                
                    if( mailToString )
                    {
                        NSError        *nsError        = nil;
                        NSString    *subjectString    = [NSString stringWithFormat:@"%@ Crashlog (%@ %@ %@ %@)",[[NSProcessInfo processInfo] processName]
                                                                                                                ,[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"]
                                                                                                                ,[[[NSBundle  mainBundle] infoDictionary] objectForKey: @"JNXCommitRevision"]
                                                                                                                #if defined(__LP64__)
                                                                                                                    ,@"x86_64"
                                                                                                                #elif defined(__ARM__)
                                                                                                                    ,@"x86_64"
                                                                                                                #elif defined(__i386__)
                                                                                                                    ,@"i386"
                                                                                                                #elif defined(__PPC__)
                                                                                                                    ,@"PPC"
                                                                                                                #else
                                                                                                                    ,@"unknown arch"
                                                                                                                #endif
                                                                                                                ,[[NSProcessInfo processInfo] operatingSystemVersionString]];
                    
                        NSString *mailString = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@\n%@\nLogfilecontents:\n%@\n"    ,mailToString
                                                                                                                                        ,subjectString
                                                                                                                                        ,mailbodyString
                                                                                                                                        ,[NSString stringWithContentsOfFile:lastCrashReportFilename encoding:NSUTF8StringEncoding error:&nsError]
                                                                                                                                        ,[NSString stringWithContentsOfFile:previousLogfileName encoding:NSUTF8StringEncoding error:&nsError]];
                    
                        NSURL *url = [NSURL URLWithString:(__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)mailString, NULL, NULL, kCFStringEncodingISOLatin1)];
                        [[NSWorkspace sharedWorkspace] openURL:url];
                    }
                    else
                    {
                        JLog(@"Info plist has no mailto key - won't send crashreport");
                    }
                };break;
            }
            [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: JNX_CRASHREPORTER_DEFAULTS_DATEKEY];
        }
        if( ! [[NSUserDefaults standardUserDefaults] synchronize] )
        {
            JLog(@"Could not synchronize defaults.");
        }
    });
}




+ (NSString*)lastCrashReportFilename
{
    DJLOG
    
    NSString                *crashlogFilename        = nil;
    NSDate                    *crashlogDate            = [NSDate distantPast];
    
    NSString                *crashlogPathname        = [[NSHomeDirectory() stringByAppendingPathComponent: @"Library"] stringByAppendingPathComponent: @"Logs"];
    
    
    NSString                *logfileExtension    = @"crash";
    NSString                *logfilePrfix        = [NSString stringWithFormat:@"%@_",[[NSProcessInfo processInfo] processName]];
    
    if( 0x080000 == (0xFF0000&osversion()) )
    {
        crashlogPathname    = [crashlogPathname stringByAppendingPathComponent:@"CrashReporter"];
        logfileExtension    = @"log";
        logfilePrfix        = [NSString stringWithFormat:@"%@",[[NSProcessInfo processInfo] processName]];
    }
    
    NSDirectoryEnumerator    *crashLogDirectoryEnumerator    = [[NSFileManager defaultManager]  enumeratorAtPath:crashlogPathname];
    NSString                *intermediateCrashlogFilename;

    while( intermediateCrashlogFilename = [crashLogDirectoryEnumerator nextObject] )
    {
        if( ![[intermediateCrashlogFilename pathExtension] isEqualToString:logfileExtension] )
        {
            continue;
        }
    
        NSDictionary    *fileAttributes = [crashLogDirectoryEnumerator fileAttributes];

        if( NSFileTypeRegular == [[crashLogDirectoryEnumerator fileAttributes] objectForKey:NSFileType] )
        {
            NSString *currentFileName =  [intermediateCrashlogFilename lastPathComponent];
            DJLog(@"testing: %@",intermediateCrashlogFilename);
        
            if(        [currentFileName hasPrefix:logfilePrfix]
                &&    (NSOrderedAscending == [(NSDate *)crashlogDate compare:[fileAttributes objectForKey:NSFileModificationDate]] ) )
            {
                //DJLog(@"Found newer crashlog: %@",intermediateCrashlogFilename);
            
                crashlogFilename    = intermediateCrashlogFilename;
                crashlogDate        = [fileAttributes objectForKey:NSFileModificationDate];
            }
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


