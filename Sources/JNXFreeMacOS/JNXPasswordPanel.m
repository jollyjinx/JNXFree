//
//  JNXPasswordPanel.m
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 30/12/08.
//  Copyright 2008 Jinx.de. All rights reserved.
//

#import "JNXLog.h"
#import "JNXPasswordPanel.h"
#import "JNXKeyChainPassword.h"

NSString *JNXPasswordPanel_Credential_Protocol			= @"JNXPasswordPanel_Credential_Protocol";
NSString *JNXPasswordPanel_Credential_Text				= @"JNXPasswordPanel_Credential_Text";
NSString *JNXPasswordPanel_Credential_Fields			= @"JNXPasswordPanel_Credential_Fields";

NSString *JNXPasswordPanel_CredentialType_Text			= @"JNXPasswordPanel_CredentialType_Text";
NSString *JNXPasswordPanel_CredentialType_Password		= @"JNXPasswordPanel_CredentialType_Password";
NSString *JNXPasswordPanel_CredentialType_Number		= @"JNXPasswordPanel_CredentialType_Number";

NSString *JNXPasswordPanel_CredentialKey_Protocol		= @"Protocol";
NSString *JNXPasswordPanel_CredentialKey_Password		= @"Password";

// NSString *JNXPasswordPanel_HasPasswordNotification		= @"JNXPasswordPanel_HasPasswordNotification";

@implementation JNXPasswordPanel

+ (NSString *)       passwordForItem:(NSString*)itemName title:(NSString*)title text:(NSString *)explanationText showPanel:(BOOL)showpanel;
{
	DJLOG
	
	NSMutableArray	*credentialArray = [NSMutableArray arrayWithObjects:JNXPasswordPanel_CredentialKey_Password,JNXPasswordPanel_CredentialType_Password,nil];
	
	NSMutableDictionary	*credentialsDictionary = [NSMutableDictionary dictionaryWithObject:credentialArray forKey:JNXPasswordPanel_Credential_Fields];
	
	if( explanationText )
	{
		[credentialsDictionary setObject:explanationText forKey:JNXPasswordPanel_Credential_Text];
	}
	NSDictionary *returnDictionary = [JNXPasswordPanel credentialsForItem:itemName 
																	title:title 
														  credentialTypes:[NSArray arrayWithObject:credentialsDictionary]
														        showPanel:showpanel];
	
	if( returnDictionary )
	{
		NSString *passwordString = [returnDictionary objectForKey:JNXPasswordPanel_CredentialKey_Password];
		return passwordString?passwordString:@"";
	}
	return nil;
}


+ (NSMutableDictionary *)credentialsForItem:(NSString*)itemName title:(NSString*)title credentialTypes:(NSArray *)credentialTypesArray showPanel:(BOOL)showpanel;
{
	DJLOG
	JNXKeyChainPassword *keyChainPassword = [[JNXKeyChainPassword alloc] initWithItem:itemName
																				title:title 
																	  credentialTypes:credentialTypesArray
																			showPanel:showpanel];
	
	NSMutableDictionary *theCredentials = [[keyChainPassword credentials] mutableCopy];

	return theCredentials;
}

@end
