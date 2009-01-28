//
//  NSString+PercentEscape.m
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 06/01/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

#import "NSString+PercentEscape.h"



@implementation NSString (JNXKeyValueStringEncoding)

/*
- (NSString*)encodePercentEscapesPerRFC2396 
{
	return (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes (NULL, (CFStringRef)self, NULL, NULL, kCFStringEncodingUTF8)  autorelease] ;
}

- (NSString*)encodePercentEscapesStrictlyPerRFC2396 
{
   CFStringRef decodedString = (CFStringRef)[self  decodeAllPercentEscapes];
   // The above may return NULL if url contains invalid escape  sequences like %E8me, %E8fe, %E800 or %E811,
   // because CFURLCreateStringByReplacingPercentEscapes() isn't smart enough to ignore them.
   CFStringRef recodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, decodedString, NULL, NULL, kCFStringEncodingUTF8);
   // And then, if decodedString is NULL, recodedString will be NULL too.
   // So, we recover from this rare but possible error by returning the original self
   // because it's "better than nothing".
   NSString* answer = (recodedString != NULL) ? [(NSString*)recodedString autorelease] : self ;
   // Note that if recodedString is NULL, we don't need to CFRelease() it.
   // Actually, unlike [nil release], CFRelease(NULL) causes a crash. Thanks, Apple!
   return answer ;
}

- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso 
{
   return (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, (CFStringRef)butNot, (CFStringRef)butAlso, kCFStringEncodingUTF8) autorelease];
}

- (NSString*)decodeAllPercentEscapes
{
   // Unfortunately, CFURLCreateStringByReplacingPercentEscapes() seems to only replace %[NUMBER] escapes
   return (NSString*)[(NSString*)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, CFSTR("")) autorelease];
}

*/

- (NSString *)JNXdecodeFromKeyValueStringEncoding
{
	return [[[[[[self componentsSeparatedByString:@"%26"] componentsJoinedByString:@"&"]componentsSeparatedByString:@"%3D"] componentsJoinedByString:@"="]componentsSeparatedByString:@"%25"] componentsJoinedByString:@"%"];
//	return [[[self stringByReplacingOccurrencesOfString:@"%26" withString:@"&"]stringByReplacingOccurrencesOfString:@"%3D" withString:@"="]stringByReplacingOccurrencesOfString:@"%25" withString:@"%"];
}

- (NSString *)JNXencodeForKeyValueStringEncoding
{
	return [[[[[[self componentsSeparatedByString:@"%"] componentsJoinedByString:@"%25"]componentsSeparatedByString:@"="] componentsJoinedByString:@"%3D"]componentsSeparatedByString:@"&"] componentsJoinedByString:@"%26"];
	
	//return [[[self stringByReplacingOccurrencesOfString:@"%" withString:@"%25"]stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"]stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
}

@end
