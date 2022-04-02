//
//  NSData+ZlibAddition.h
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 Patrick Stein Jinx® jinx.de. All rights reserved.
//

@import Foundation;

@interface NSData (ZlibAddition)
- (NSData *)	compressWithLevel:(int)level;
- (NSData *)	uncompress;
@end
