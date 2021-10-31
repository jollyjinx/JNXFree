//
//  JNXKeyChainPassword.h
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 31/12/08.
//  Copyright 2008 Jinx.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JNXKeyChainPassword : NSObject <NSWindowDelegate>
{
	NSConditionLock		*conditionLock;
	
	NSString			*itemName;
	NSString			*titleString;
	NSMutableArray		*credentialTypesArray;
	BOOL				showpanel;

	NSMutableDictionary	*credentialsDictionary;
	NSMutableArray		*visibleCredentialFields;

	IBOutlet NSWindow			*credentialsWindow;
	IBOutlet NSBox				*credentialsBox;
	IBOutlet NSPopUpButton		*credentialTypeButton;
	IBOutlet NSButton			*saveToKeyChainButton;
	IBOutlet NSButton			*okButton;
}

- initWithItem:(NSString*)anItemName title:(NSString*)aTitle credentialTypes:(NSArray *)aCredentialTypesArray showPanel:(BOOL)shouldshowpanel;
- (void)dealloc;
- (void)retrieveCredentialsOnMainThread;
+ (NSSize)findSizeForString:(NSString *)aString font:(NSFont *)aFont width:(float)width;
- (IBAction)credentialTypeHasChanged:(id)sender;
- (IBAction)buttonOkHasBeenPressed:(id)sender;
- (void)windowWillClose:(NSNotification *)aNotification;
- (NSDictionary *)credentials;

@end
