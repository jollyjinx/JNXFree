//
//  NSData+RSAStringAdditions.m
//  LicenseTest
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSData+RSAAddition.h"

#include <openssl/bn.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>


@implementation NSData (RSAAddition)

-(NSData *)RSAencryptWithPublicKey:(NSString *)publicKeyString padding:(int)padding
{
	DJLog(@"%@",[self description]);
	
	RSA *newRSA = NULL;
	BIO *publickeymemory  = BIO_new_mem_buf((void *)[publicKeyString cString], [publicKeyString cStringLength] );
	
	if( NULL == publickeymemory )
	{
		JLog(@"couldn't create bignum");
		return nil;
	}
	BIO_reset(publickeymemory);
	
	PEM_read_bio_RSAPublicKey(publickeymemory,&newRSA,0,NULL);
	if( NULL == newRSA )
	{
		BIO_reset(publickeymemory);
		PEM_read_bio_RSA_PUBKEY(publickeymemory,&newRSA,0,NULL);
		if( NULL == newRSA )
		{
			JLog(@"couldn't create rsa object");
			return nil;
		}
	}
	
	
	NSMutableData *completeData = [NSMutableData data];
	
	unsigned int	currentposition		= 0;
	unsigned int	encryptedpadding	= 0;RSA_size(newRSA) - 11;

	switch( padding )
	{
		case	RSA_PKCS1_PADDING:			encryptedpadding = RSA_size(newRSA) - 11; break;
		case	RSA_PKCS1_OAEP_PADDING:		encryptedpadding = RSA_size(newRSA) - 41; break;
		case	RSA_SSLV23_PADDING:			encryptedpadding = RSA_size(newRSA) - 11; break;
		default:							encryptedpadding = INT32_MAX;
	}
	
	NSMutableData	*encryptedData		= [NSMutableData dataWithLength:RSA_size(newRSA)];
	while( currentposition < [self length] )
	{
		int length = RSA_public_encrypt( ([self length] - currentposition)%encryptedpadding, [self bytes]+currentposition ,(unsigned char *)[encryptedData bytes], newRSA, padding);
		if( 0 == length )
		{
			JLog(@"Encryption error");
			return nil;
		}
		
		[completeData appendData:[NSData dataWithBytesNoCopy:(unsigned char *)[encryptedData bytes] length:length freeWhenDone:NO]];
		currentposition += encryptedpadding;
	}
	DNSLog(@"Encryption end:%@",[completeData description]);
	return (NSData *)completeData;
}

int verify_ripemd160(unsigned char *msg, unsigned int mlen, unsigned char *sig,
               unsigned int siglen, RSA *r) {
  unsigned char hash[20];
  BN_CTX        *c;
  int           ret;

  if (!(c = BN_CTX_new())) return 0;
  if (!RIPEMD160(msg, mlen, hash) || !RSA_blinding_on(r, c)) {
    BN_CTX_free(c);
    return 0;
  }
  ret = RSA_verify(NID_ripemd160, hash, 20, sig, siglen, r);
  RSA_blinding_off(r);
  BN_CTX_free(c);
  return ret;
}
int verify_sha1(unsigned char *msg, unsigned int mlen, unsigned char *sig,
               unsigned int siglen, RSA *r) {
  unsigned char hash[20];
  BN_CTX        *c;
  int           ret;

  if (!(c = BN_CTX_new())) return 0;
  if (!SHA1(msg, mlen, hash) || !RSA_blinding_on(r, c)) {
    BN_CTX_free(c);
    return 0;
  }
  ret = RSA_verify(NID_sha1, hash, 20, sig, siglen, r);
  RSA_blinding_off(r);
  BN_CTX_free(c);
  return ret;
}


- (bool)		RSAcheckSignature:(NSData *)signature withPublicKey:(NSString *)publicKeyString type:(int)type
{
	DJLog(@"%@",[self description]);
	
	RSA *newRSA = NULL;
	BIO *publickeymemory  = BIO_new_mem_buf((void *)[publicKeyString cString], [publicKeyString cStringLength] );
	
	if( NULL == publickeymemory )
	{
		JLog(@"couldn't create bignum");
		return NO;
	}
	BIO_reset(publickeymemory);
	
	PEM_read_bio_RSAPublicKey(publickeymemory,&newRSA,0,NULL);
	if( NULL == newRSA )
	{
		BIO_reset(publickeymemory);
		PEM_read_bio_RSA_PUBKEY(publickeymemory,&newRSA,0,NULL);
		if( NULL == newRSA )
		{
			JLog(@"couldn't create rsa object");
			return nil;
		}
	}

	switch( type )
	{
		case NID_ripemd160:	{
								if( 1 == verify_ripemd160( (unsigned char *)[self bytes], [self length],(unsigned char *)[signature bytes], [signature length],newRSA) )
								{
									return YES;
								}
							}break;
		case NID_sha1:		{
								if( 1 == verify_sha1( (unsigned char *)[self bytes], [self length],(unsigned char *)[signature bytes], [signature length],newRSA) )
								{
									return YES;
								}
						}break;
		default:		JLog(@"type %d not supported.",type);
	}
	DJLog(@"signature did not match");
	return NO;
}

@end
