//
//  NSData+ZlibAddition.m
//  JNXLicense Framework
//
//  Created by Patrick Stein on 09.05.07.
//  Copyright 2007 jinx.de. All rights reserved.
//

#import "JNXLog.h"
#import "NSData+ZlibAddition.h"
#import <zlib.h>

@implementation NSData (ZlibAddition)
- (NSData *)    compressWithLevel:(int)level
{
    if( [self length] < 1)
        return nil;

    z_stream                zstream;

    zstream.total_in    = 0;
    zstream.total_out    = 0;
    zstream.zalloc        = Z_NULL;
    zstream.zfree        = Z_NULL;
    zstream.opaque        = Z_NULL;

    deflateInit2( &zstream,    level, Z_DEFLATED, MAX_WBITS, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY );

    NSMutableData *outputData    =    [NSMutableData dataWithLength:[self length]];

    zstream.total_out    = 0;
    
    zstream.next_in        = ( Bytef * )[self bytes];
    zstream.avail_in    = (unsigned int)[self length];
    zstream.next_out    = ( Bytef * )[outputData bytes];
    zstream.avail_out    = (unsigned int)[outputData length];
    zstream.data_type    = Z_BINARY;

    if( Z_OK != deflate( &zstream, Z_SYNC_FLUSH ) )
    {
        JLog(@"Zlib deflate error");
        return nil;
    }

    [outputData setLength:zstream.total_out];

    return outputData;
}


- (NSData *)    uncompress;
{
    if( [self length] < 1)
        return nil;
    
    z_stream    zstream;
    
    zstream.next_in        = Z_NULL;
    zstream.avail_in    = Z_NULL;
    zstream.total_in    = 0;
    zstream.total_out    = 0;
    zstream.zalloc        = Z_NULL;
    zstream.zfree        = Z_NULL;
    zstream.opaque        = Z_NULL;

    if(  Z_OK != inflateInit( &zstream) )
    {
        JLog(@"Error initializing Zlib");
        return nil;
    }
    
    unsigned int    originallength        = (unsigned int)[self length];
    unsigned int    goodsizelength        = ((originallength+1023)/1024)*1024;
    
    void            *uncompresseddata    = malloc(originallength+goodsizelength);
    
    unsigned int    uncompressedspace    = originallength+goodsizelength;
    
    zstream.total_out    = 0;
    zstream.next_in        = ( Bytef * )[self bytes];
    zstream.avail_in    = (unsigned int)[self length];
    zstream.next_out    = ( Bytef * )uncompresseddata;
    zstream.avail_out    = uncompressedspace;
    zstream.data_type    = Z_BINARY;
    
    while( Z_OK == inflate( &zstream, Z_SYNC_FLUSH ) )
    {
        if( zstream.total_out >= uncompressedspace )
        {
            uncompressedspace    += goodsizelength;
            if( NULL == (uncompresseddata = reallocf(uncompresseddata, uncompressedspace)) )
            {
                JLog(@"Can't realloc for uncompressing data.");
                return nil;
            }
        }
        zstream.next_out    = uncompresseddata    + zstream.total_out;
        zstream.avail_out    = uncompressedspace    - (unsigned int)zstream.total_out;
    }
    
    if( Z_OK != inflateEnd( &zstream) )
    {
        JLog(@"Zlib inflate error %ld",zstream.total_out);
        free(uncompresseddata);
        return nil;
    }
    
    NSData    *outputData    = [NSData dataWithBytes:uncompresseddata length:zstream.total_out];

    free(uncompresseddata);
    
    return outputData;
}

@end


