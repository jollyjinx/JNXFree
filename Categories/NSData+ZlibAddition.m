//
//  NSData+ZlibAddition.m
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 jinx.de. All rights reserved.
//

#import "NSData+ZlibAddition.h"


@implementation NSData (ZlibAddition)
- (NSData *)	compressWithLevel:(int)level
{
		if( ![self length] )
			return nil;
		
		z_stream				zstream;
		
		zstream.total_in	= 0;
		zstream.total_out	= 0;
		zstream.zalloc		= Z_NULL;
		zstream.zfree		= Z_NULL;
		zstream.opaque		= Z_NULL;

		deflateInit2( &zstream,	level, Z_DEFLATED, MAX_WBITS, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY );	
		
		NSMutableData *outputData	=	[NSMutableData dataWithLength:[self length]];
		
		zstream.total_out	= 0;
			
		zstream.next_in		= ( Bytef * )[self bytes];
		zstream.avail_in	= [self length];
		zstream.next_out	= ( Bytef * )[outputData bytes];
		zstream.avail_out	= [outputData length];
		zstream.data_type	= Z_BINARY;

		if( Z_OK != deflate( &zstream, Z_SYNC_FLUSH ) )
		{
			JLog(@"Zlib deflate error");
			return nil;
		}
		
		[outputData setLength:zstream.total_out];
		
		return outputData;
}





- (NSData *)	uncompress;
{
		if( ![self length] )
			return nil;
		
		z_stream				zstream;
		
		zstream.next_in		= Z_NULL;
		zstream.avail_in	= Z_NULL;
		zstream.total_in	= 0;
		zstream.total_out	= 0;
		zstream.zalloc		= Z_NULL;
		zstream.zfree		= Z_NULL;
		zstream.opaque		= Z_NULL;

		if(  Z_OK != inflateInit( &zstream) )
		{
			JLog(@"Error initializing Zlib");
			return nil;
		}
		
		NSMutableData *outputData	=	[NSMutableData dataWithLength:[self length]*10];
		
		zstream.total_out	= 0;
			
		zstream.next_in		= ( Bytef * )[self bytes];
		zstream.avail_in	= [self length];
		zstream.next_out	= ( Bytef * )[outputData bytes];
		zstream.avail_out	= [outputData length];
		zstream.data_type	= Z_BINARY;

		if( Z_STREAM_END != inflate( &zstream, Z_SYNC_FLUSH ) )
		{
			JLog(@"Zlib inflate error %d",zstream.total_out);
			return nil;
		}
		
		[outputData setLength:zstream.total_out];
		
		return outputData;
}


@end


