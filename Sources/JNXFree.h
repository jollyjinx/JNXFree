//
//  JNXFree.h
//  JNXFree
//
//  Created by Patrick Stein on 22.10.21.
//

#import <Foundation/Foundation.h>

//! Project version number for JNXFree.
FOUNDATION_EXPORT double JNXFreeVersionNumber;

//! Project version string for JNXFree.
FOUNDATION_EXPORT const unsigned char JNXFreeVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <JNXFree/PublicHeader.h>

#import <JNXFree/JNXLog.h>
#import <JNXFree/NSData+ZlibAddition.h>
#import <JNXFree/NSDictionary+KeyValueStringEncoding.h>
#import <JNXFree/NSString+PercentEscape.h>
#import <JNXFree/JNXMTQueue.h>


//#ifdef TARGET_OS_MACOSX
#import <JNXFree/osversion.h>
#import <JNXFree/JNXPasswordPanel.h>
#import <JNXFree/JNXKeyChainPassword.h>
#import <JNXFree/JNXCrashReporter.h>
//#endif
