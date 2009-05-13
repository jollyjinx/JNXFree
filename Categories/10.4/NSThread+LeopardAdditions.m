//
//  NSThread+LeopardAdditions.m
//  JollysFastVNC
//
//  Created by Patrick Stein on 29/04/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

#if    MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5

#import "NSThread+LeopardAdditions.h"
#import <pthread.h>

@implementation NSThread(NSThread_LeopardAdditions)

+ (BOOL)isMainThread
{
	return (0==pthread_main_np()?NO:YES);
}

@end


#endif