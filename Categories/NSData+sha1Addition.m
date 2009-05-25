//
//  NSData+ZlibAddition.m
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 jinx.de. All rights reserved.
//

#import "NSData+sha1Addition.h"
#include <openssl/sha.h>

        unsigned char *SHA1(const unsigned char *d, unsigned long n,
                         unsigned char *md);


@implementation NSData (sha1Addition)

#if SHA_DIGEST_LENGTH != 20
#warning SHA1 is not 20 bytes NSData+sha1addition only uses the first 20 bytes
#endif

- (NSString *)sha1String;
{
	uint8_t	 digest[SHA_DIGEST_LENGTH];
	
	bzero(digest,sizeof(digest));
	
	SHA1([self bytes], [self length], digest);

    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        digest[0],digest[1],digest[2],digest[3],
        digest[4],digest[5],digest[6],digest[7],
        digest[8],digest[9],digest[10],digest[11],
        digest[12],digest[13],digest[14],digest[15],
        digest[16],digest[17],digest[18],digest[19]] ;
}

- (NSData *)sha1Data;
{
	uint8_t	 digest[SHA_DIGEST_LENGTH];
	
	bzero(digest,sizeof(digest));
	
	SHA1([self bytes], [self length], digest);

    return [NSData dataWithBytes:digest length:SHA_DIGEST_LENGTH];
}

@end


