//
//  NSData+ZlibAddition.h
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 Patrick Stein Jinx® jinx.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <zlib.h>



@interface NSData (sha1Addition)
- (NSString *)sha1String;
- (NSData *)	sha1Data;
@end
