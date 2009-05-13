//
//  NSThread+LeopardAdditions.h
//  JollysFastVNC
//
//  Created by Patrick Stein on 29/04/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//


#if    MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5

#import <Cocoa/Cocoa.h>


@interface NSThread(NSThread_LeopardAdditions)

+ (BOOL)isMainThread;

@end

#endif