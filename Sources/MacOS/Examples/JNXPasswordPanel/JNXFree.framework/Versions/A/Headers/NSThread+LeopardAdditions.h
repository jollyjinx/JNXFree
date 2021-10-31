//
//  NSThread+LeopardAdditions.h
//  JollysFastVNC
//
//  Created by Patrick Stein on 29/04/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@interface NSThread(NSThread_LeopardAdditions)

+ (BOOL)jnxIsMainThread;

@end
