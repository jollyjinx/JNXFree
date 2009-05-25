//
//  NSThread+LeopardAdditions.m
//  JollysFastVNC
//
//  Created by Patrick Stein on 29/04/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//


#import "NSThread+LeopardAdditions.h"
#import <pthread.h>

@implementation NSThread(NSThread_LeopardAdditions)

+ (BOOL)jnxIsMainThread
{
#if    MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
	return (0==pthread_main_np()?NO:YES);
#else
	return [self isMainThread];
#endif
}

@end


