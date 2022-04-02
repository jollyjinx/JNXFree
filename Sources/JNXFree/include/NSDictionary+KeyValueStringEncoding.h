//
//  NSDictionary+KeyValueStringEncoding.h
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 06/01/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

@import Foundation;

@interface  NSMutableDictionary (JNXKeyValueStringEncoding)

+ (NSMutableDictionary *)JNXdictionaryFromKeyValueString:(NSString *)keyValueString;
- (NSString *)JNXkeyValueStringEncoded;

@end
