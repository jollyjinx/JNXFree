//
//  NSData+RSAStringAdditions.h
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 Patrick Stein Jinx� jinx.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <openssl/pem.h>			// defines NID_ripemd160 and NID_sha1

@interface NSData (RSAAddition)

- (NSData *)	RSAencryptWithPublicKey:(NSString *)publicKeyString padding:(int)padding;
- (bool)		RSAcheckSignature:(NSData *)signature withPublicKey:(NSString *)publicKeyString type:(int)type;

@end

