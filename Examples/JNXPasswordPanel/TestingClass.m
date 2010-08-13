//
//  TestingClass.m
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 07/01/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

#import "TestingClass.h"

#import <JNXFree/JNXFree.h>

@implementation TestingClass

- init
{
	[JNXCrashReporter testForCrashWithBodyString:@"Hello Jolly,\nPasswordPanel has crashed the last time I used it.\n Here are the results:\n"];

	DJLOG
	if( !(self=[super init]) )
		return nil;
	
	NSString *fasel = nil;
	if( [fasel isEqual:fasel] )
	{
		JLog(@"It's equal");
	}
	
	[NSThread detachNewThreadSelector:@selector(testingThread) toTarget:self withObject:nil];
	[NSThread detachNewThreadSelector:@selector(testingThread2) toTarget:self withObject:nil];
//	[NSThread detachNewThreadSelector:@selector(testingThread) toTarget:self withObject:nil];
//	[NSThread detachNewThreadSelector:@selector(testingThread) toTarget:self withObject:nil];
	return self;
}

- (void)testingThread;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	DJLOG
	[JNXPasswordPanel passwordForItem:@"single" title:@"Title" text:@"Explanatory text" showPanel:YES];
	[pool release];
}

- (void)testingThread2;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	DJLOG
	
	NSArray	*myArray =	[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestPanel1" ofType:@"plist" inDirectory:nil]];
	
	[JNXPasswordPanel credentialsForItem:@"choice" title:@"Title" credentialTypes:myArray showPanel:YES];
	[pool release];

}

@end
