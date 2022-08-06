//
//  NSString+PercentEscape.h
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 06/01/09.
//  Copyright 2009 Jinx.de. All rights reserved.
//

@import Foundation;


@interface  NSString (JNXKeyValueStringEncoding)

/*
- (NSString*)encodePercentEscapesPerRFC2396 ;
- (NSString*)encodePercentEscapesStrictlyPerRFC2396 ;
   // Decodes any existing percent escapes which should not be encoded per RFC 2396 sec. 2.4.3
   // Encodes any characters which should be encoded per RFC 2396 sec. 2.4.3.
- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso ;
- (NSString*)decodeAllPercentEscapes ;
   // I did an experiment to find out which ASCII characters are encoded,
   // by encoding a string with all the nonalphanumeric characters available on the
   // Macintosh keyboard, with and without the shift key down.  There were fourteen:
   //      ` # % ^ [ ] { } \ | " < >
   // You only see thirteen because the fourtheenth one is the space character, " ".
   // This agrees with the lists of "space" "delims" and "unwise" in by RFC 2396 sec. 2.4.3
   // Also, I found that all of the non-ASCII characters available on the Macintosh
   // keyboard by using option or shift+option are also encoded.  Some of these have
   // two bytes of unicode to encode, for example %C2%A4 for 0xC2A4
*/
- (NSString *)JNXdecodeFromKeyValueStringEncoding;
- (NSString *)JNXencodeForKeyValueStringEncoding;

@end
