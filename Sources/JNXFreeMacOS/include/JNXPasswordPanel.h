//
//  JNXPasswordPanel.h
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 30/12/08.
//  Copyright 2008 Jinx.de. All rights reserved.
//

@import AppKit;

extern NSString *JNXPasswordPanel_Credential_Protocol;
extern NSString *JNXPasswordPanel_Credential_Text;
extern NSString *JNXPasswordPanel_Credential_Fields;

extern NSString *JNXPasswordPanel_CredentialType_Text;
extern NSString *JNXPasswordPanel_CredentialType_Password;
extern NSString *JNXPasswordPanel_CredentialType_Number;

extern NSString *JNXPasswordPanel_CredentialKey_Protocol;
extern NSString *JNXPasswordPanel_CredentialKey_Password;

//extern NSString *JNXPasswordPanel_HasPasswordNotification;

@interface JNXPasswordPanel : NSObject 
{
	
}


+ (NSString *)       passwordForItem:(NSString*)itemName title:(NSString*)title text:(NSString *)explanationText showPanel:(BOOL)showpanel;
+ (NSMutableDictionary *)credentialsForItem:(NSString*)itemName title:(NSString*)title credentialTypes:(NSArray *)credentialTypesArray showPanel:(BOOL)showpanel;

@end
