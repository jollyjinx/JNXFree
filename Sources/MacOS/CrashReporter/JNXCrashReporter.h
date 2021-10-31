//
//  JNXCrashReporter.h
//  JollysFastVNC
//
//  Created by Patrick  Stein on 23.11.07.
//  Copyright 2007 jinx.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define JNX_CRASHREPORTER_SUBJECTKEY			@"JNXCrashReporter.subject"
#define JNX_CRASHREPORTER_MAILTOKEY				@"JNXCrashReporter.mailto"

@interface JNXCrashReporter : NSObject 
{

}
+ (NSString *)logFileName;
+ (void)testForCrashWithBodyString:(NSString *)mailbodyString;
+ (NSString*) lastCrashReportFilename;

@end
