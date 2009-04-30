//
//  NSDictionary+KeyValueStringEncoding.m
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 06/01/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

#import "NSDictionary+KeyValueStringEncoding.h"
#import "NSString+PercentEscape.h"

@implementation  NSMutableDictionary (JNXKeyValueStringEncoding)

+ (NSMutableDictionary *)JNXdictionaryFromKeyValueString:(NSString *)givenKeyValueString;
{
	NSMutableDictionary *outputDictionary	= [NSMutableDictionary dictionary];
	NSArray				*inputArray			= [givenKeyValueString componentsSeparatedByString:@"&"];
	NSEnumerator		*inputEnumerator	= [inputArray objectEnumerator];
	NSString			*keyValueString;
	
	while( keyValueString = [inputEnumerator nextObject] )
	{
		NSArray	*keyValuePairArray	= [keyValueString componentsSeparatedByString:@"="];
		
		if( keyValuePairArray && 2 == [keyValuePairArray count] )
		{
			NSString	*aKey	= [[keyValuePairArray objectAtIndex:0] JNXdecodeFromKeyValueStringEncoding];
			NSString	*aValue = [[keyValuePairArray objectAtIndex:1] JNXdecodeFromKeyValueStringEncoding];
			
			if( aKey && aValue )
			{
				[outputDictionary setObject:aValue forKey:aKey];
			}
			else
			{
				JLog(@"Could not convert keyValuePairArray from %@",keyValueString);
			}
		}
		else
		{
			JLog(@"Could not convert keyValuePairArray from %@",keyValueString);
		}
	}
	return outputDictionary;
}

- (NSString *)JNXkeyValueStringEncoded;
{
	NSMutableArray	*outputArray	= [NSMutableArray array];
	NSEnumerator	*keyEnumerator	= [self keyEnumerator];
	

	NSString		*aKey;
	
	while( aKey = [keyEnumerator nextObject] )
	{
		NSString *aValue = [self objectForKey:aKey];
		
		if( !aValue || ![aValue length] )
		{
			continue;
		}
		
		NSString *keyValueString = [NSString stringWithFormat:@"%@=%@",[aKey JNXencodeForKeyValueStringEncoding],[aValue JNXencodeForKeyValueStringEncoding]];
		
		if( keyValueString )
		{
			[outputArray addObject:keyValueString];
		}
		else
		{
			JLog(@"Can't convert %@ or %@ to percent encoding",aKey,[self objectForKey:aKey]);
		}
	}
	return [outputArray componentsJoinedByString:@"&"];
}





 
@end
