//
//  JNXKeyChainPassword.m
//  JNXPasswordPanel
//
//  Created by Patrick Stein on 31/12/08.
//  Copyright 2008 Jinx.de. All rights reserved.
//

#import "JNXKeyChainPassword.h"

#import <Security/Security.h>
#import <JNXFree/JNXFree.h>
#import "JNXPasswordPanel.h"
#import <NSDictionary+KeyValueStringEncoding.h>


static int	passwordpanelcount = 0;

enum {
	CONDITION_NO_CREDENDIALS	= 0,
	CONDITION_HAS_CREDENDIALS	= 1,
};

#define bezelheight			3.0f
#define	horizontalmargin	15.0f
#define verticalmargin		10.0f
#define fieldheight			15.0f

@implementation JNXKeyChainPassword

- initWithItem:(NSString*)anItemName title:(NSString*)aTitle credentialTypes:(NSArray *)aCredentialTypesArray showPanel:(BOOL)shouldshowpanel;
{
	DJLOG
	if( !(self=[super init]) )
		return nil;

	conditionLock			= nil;
	credentialsDictionary	= nil;
	visibleCredentialFields	= nil;
	credentialTypesArray	= nil;
	itemName				= nil;
	titleString				= nil;

	if( !anItemName || !aCredentialTypesArray || ![aCredentialTypesArray count] )
	{
		return nil;
	}

	{
		NSString	*errorString;
		NSData		*pListData;
		
		if(! (pListData		= [NSPropertyListSerialization dataFromPropertyList:aCredentialTypesArray format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString])  )
		{
			JLog(@"Could not deep copy credential Types (plist creation failed due to %@).",errorString);
			return nil;
		}
		if( ! (credentialTypesArray	= [NSPropertyListSerialization propertyListFromData:pListData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:&errorString]) )
		{
			JLog(@"Could not deep copy credential Types (plist extraction failed due to %@).",errorString);
			return nil;
		}
	}

	
	conditionLock			= [[NSConditionLock alloc] initWithCondition:CONDITION_NO_CREDENDIALS];
	itemName				= [anItemName copy];
	showpanel				= shouldshowpanel;
	visibleCredentialFields	= [[NSMutableArray alloc] init];
	
	if( titleString )
	{
		titleString		= aTitle;
	}
	else
	{
		titleString		= [NSString stringWithFormat:NSLocalizedString(@"Authenticate for %@",@"Default JNXPassword Panel title ( argument is itemName )"),itemName];
	}
	
	[self performSelectorOnMainThread:@selector(retrieveCredentialsOnMainThread) withObject:nil waitUntilDone:NO];
	return self;
}


- (void)dealloc
{
	DJLOG
}	

// discussion:
// retrieves credentials from keychain for the given item
// if it finds some - if !showpanel - unlock with has credentials
//					show panel



- (void)retrieveCredentialsOnMainThread;
{
	DJLOG

	const char				*processname		= [[NSString stringWithFormat:@"%@: %@",[[NSProcessInfo processInfo] processName],itemName] UTF8String];
	const char				*itemname			= [itemName UTF8String];
	SecKeychainItemRef		keychainItemRef		= nil;
	UInt32					keychainitemlength;
	void					*keychainitemdata;
	OSStatus				error;
		
	if( noErr == (error = SecKeychainFindGenericPassword( NULL, (uint32_t) strlen(processname), processname, (uint32_t)strlen(itemname), itemname, &keychainitemlength, &keychainitemdata,NULL)) )
	{	
		NSMutableData *keychainItemData = [NSMutableData dataWithBytes:keychainitemdata length:keychainitemlength];
		if( (error = SecKeychainItemFreeContent ( NULL,  keychainitemdata )) )
		{
			JLog(@"Could not release keychain item - just leaking");
		}
		
		
		[keychainItemData increaseLengthBy:1];				// appends NULL byte !
		NSString *itemDataString = [NSString stringWithUTF8String:[keychainItemData bytes]];
		
		if(		itemDataString	
			&& (strlen([itemDataString UTF8String]) == ([keychainItemData length] -1) )
			&& (credentialsDictionary	= [NSMutableDictionary JNXdictionaryFromKeyValueString:itemDataString]) )
		{

			NSString *selectedProtocol = [credentialsDictionary objectForKey:JNXPasswordPanel_CredentialKey_Protocol];
			
			if( selectedProtocol )
			{
				NSEnumerator	*arrayEnumerator			= [credentialTypesArray objectEnumerator];
				NSDictionary	*availableTypeDictionary;
				
				BOOL	hasfoundprotocol = NO;
				
				while( !hasfoundprotocol && (availableTypeDictionary=[arrayEnumerator nextObject]) )
				{
					NSString	*availableType = [availableTypeDictionary objectForKey:JNXPasswordPanel_Credential_Protocol];
					
					if( availableType && [availableType isEqual:selectedProtocol] )
					{
						hasfoundprotocol = YES;
					}
				}
				if( !hasfoundprotocol )
				{
					DJLog(@"saved credentials do contain a protocol that's not available any longer");
					[credentialsDictionary removeObjectForKey:JNXPasswordPanel_CredentialKey_Protocol];
					showpanel = YES;
				}
			}
			else if( [credentialTypesArray count] >1 )
			{
				DJLog(@"saved credentials do not contain the Protocol but we have multiple choices now");
				[credentialsDictionary removeObjectForKey:JNXPasswordPanel_CredentialKey_Protocol];
				showpanel = YES;
			}


			if( NO == showpanel )
			{
				[conditionLock lock];
				[conditionLock unlockWithCondition:CONDITION_HAS_CREDENDIALS];
				return;
			}
		}
		else
		{
			credentialsDictionary = [[NSMutableDictionary alloc] init];
			JLog(@"Weird keychainItem with name:%@",itemName);
			DJLog(@"broken keychainItemData %@",itemDataString);
		}

	}
	else if( errSecItemNotFound == error )
	{
		DJLog(@"did not find item with Name:%@",itemName);
		keychainItemRef			= nil;
		credentialsDictionary	= [[NSMutableDictionary alloc] init];
	}
	else
	{
		JLog(@"could not access the keychain: %d",error);
		keychainItemRef			= nil;
		credentialsDictionary	= [[NSMutableDictionary alloc] init];
	}
	
	// now create the window with the popupbutton, close and cancle button without credentials though.
	
	{
		if( ! [NSBundle loadNibNamed:@"JNXPasswordPanel" owner:self] )
		{
			JLog(@"Could not load nib file for JNXPassword Panel");
			[conditionLock lock];
			[conditionLock unlockWithCondition:CONDITION_HAS_CREDENDIALS];
			return;
		}
		
		NSRect windowrect = [credentialsWindow frame];
				
		windowrect.origin.x +=  ((passwordpanelcount%10)*20);
		windowrect.origin.y -=  ((passwordpanelcount%10)*20);
		
		passwordpanelcount++;
	
		[credentialsWindow setFrame:windowrect display:NO];
		[credentialsWindow setTitle:titleString];
		[credentialsWindow setHidesOnDeactivate:YES];
		[credentialsWindow setDelegate:self];
		
		if( 1 == [credentialTypesArray count] )
		{
			[credentialTypeButton removeFromSuperview];
			credentialTypeButton = nil;
			NSRect	contentframe	= [[credentialsWindow contentView] frame];
			NSRect	boxframe		= [credentialsBox frame];
			boxframe.size.height = contentframe.size.height-boxframe.origin.y;
			[credentialsBox setFrame:boxframe];
			[credentialsBox setBorderType:NSNoBorder];
		}
		else
		{
			[credentialTypeButton removeAllItems];
			
			for( int i=0 ; i< [credentialTypesArray count]; i++ )
			{
				NSDictionary *singleTypeDictionary = [credentialTypesArray objectAtIndex:i];
				
				NSString	*typeName = [singleTypeDictionary objectForKey:JNXPasswordPanel_Credential_Protocol];
				
				if( typeName )
				{
					[credentialTypeButton addItemWithTitle:typeName];
				}
				else
				{
					[credentialTypeButton addItemWithTitle:NSLocalizedString(@"unnamed protocol","credential protocol name not known")];
				}
			}
			NSString *selectedTitle = [credentialsDictionary objectForKey:JNXPasswordPanel_CredentialKey_Protocol];
			
			if( selectedTitle && [credentialTypeButton indexOfItemWithTitle:selectedTitle] > -1 )
			{
				[credentialTypeButton selectItemWithTitle:selectedTitle];
			}
		}
	}
	[self credentialTypeHasChanged:self];
}


+ (NSSize)findSizeForString:(NSString *)aString font:(NSFont *)aFont width:(float)width;
{
	NSTextStorage	*textStorage	= [[NSTextStorage alloc] initWithString:aString];
	NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(width, FLT_MAX)];
	NSLayoutManager *layoutManager	= [[NSLayoutManager alloc] init];

	[layoutManager	addTextContainer:textContainer];
	[textStorage	addLayoutManager:layoutManager];
	[textStorage	setFont:aFont];//addAttribute:NSFontAttributeName value:aFont range:NSMakeRange(0, [textStorage length])];

	[textContainer setLineFragmentPadding:30.0];		//  why do I need this high padding ?
	[layoutManager setUsesScreenFonts:YES];
	
	[layoutManager glyphRangeForTextContainer:textContainer];

	return [layoutManager usedRectForTextContainer:textContainer].size;
}


- (IBAction)credentialTypeHasChanged:(id)sender;
{
	DJLOG
	//DJLog(@"Credentials: %@",credentialsDictionary);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:nil];

//	[credentialsBox setContentView:[[NSView alloc] initWithFrame:[credentialsBox frame]]];
	
	NSView			*contentView	= [credentialsBox contentView] ;
	NSDictionary	*selectedType	= [credentialTypesArray objectAtIndex:0];

	
	if( [credentialTypesArray count] > 1 )
	{
		if( [credentialTypeButton indexOfSelectedItem] > - 1 && [credentialTypeButton indexOfSelectedItem] < [credentialTypesArray count] )
		{
			selectedType = [credentialTypesArray objectAtIndex:[credentialTypeButton indexOfSelectedItem]];
		}
		else
		{
			JLog(@"Weird selection - could not find credential type from button - using the first one");
			selectedType = [credentialTypesArray objectAtIndex:0];
		}
	}

	[visibleCredentialFields makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[visibleCredentialFields removeAllObjects];

	float	widthleft,widthright;
	float	completeheight;
	{
		NSSize size = [@"WWWWWWWWWWWW" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName,nil]];
		widthright = size.width;
		widthleft	= widthright;
	}
	#define innerwidth			(widthleft + horizontalmargin + widthright )
	#define completewidth		(innerwidth + 2*horizontalmargin)
	
	{
		NSArray		*inputFieldsArray	= [selectedType objectForKey:JNXPasswordPanel_Credential_Fields];
		int			count				= (int)[inputFieldsArray count];
		
		for( int i = 0 ; i< count -1 ; i+=2 )
		{
			NSSize size	= [[inputFieldsArray objectAtIndex:i] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName,nil]];
			if( size.width > widthleft ) widthleft = size.width;
		}

		completeheight = verticalmargin + ((fieldheight+verticalmargin)*(count/2));
		{
			NSString	*explanatoryString = [selectedType objectForKey:JNXPasswordPanel_Credential_Text];
			if( explanatoryString )
			{
				NSFont	*labelFont = [NSFont messageFontOfSize:0.0];
				NSSize size = [JNXKeyChainPassword findSizeForString:explanatoryString font:labelFont width:innerwidth];
				
				
				if( (size.height > 200.0) && (innerwidth < 300.0) )		// widen text when its much longer than wide
				{
					widthleft	+= 100.0;
					widthright	+= 100.0;
					size		= [JNXKeyChainPassword findSizeForString:explanatoryString font:labelFont width:innerwidth];
				}
				
				DJLog(@"Size now: %f %f",size.width,size.height);
				NSRect	explanatoryframe = { horizontalmargin, completeheight, innerwidth, size.height  };
				
				completeheight += size.height + verticalmargin;
				
				NSTextField *explanatoryField = [[NSTextField alloc] initWithFrame:explanatoryframe];
				
				[explanatoryField setFont:labelFont];
				[explanatoryField setStringValue:explanatoryString];
				[explanatoryField setSelectable:NO];
				[explanatoryField setEditable:NO];
				[explanatoryField setBezeled:NO];
				[explanatoryField setDrawsBackground:NO];
				[contentView addSubview:explanatoryField];
				[visibleCredentialFields addObject:explanatoryField];
			}
		}
		

		for( int i = 0 ; i< count -1 ; i+=2 )
		{
			NSString	*aLabel			= [inputFieldsArray objectAtIndex:count-2-i];
			NSString	*aType			= [inputFieldsArray objectAtIndex:count-2-i+1];
			
			{
				NSSize size = [aLabel sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor], NSForegroundColorAttributeName,nil]];
				NSRect	labelframe = { widthleft - size.width , verticalmargin + ((fieldheight+verticalmargin) * (i/2)) , size.width+horizontalmargin, fieldheight };
			
				NSTextField	*anLabelField	= [[NSTextField alloc] initWithFrame:labelframe];
				[anLabelField setStringValue:[NSString stringWithFormat:@"%@:",aLabel]];
				[anLabelField setEditable:NO];
				[anLabelField setBezeled:NO];
				[anLabelField setAlignment:  NSRightTextAlignment];
				[anLabelField setDrawsBackground:NO];
				[contentView addSubview:anLabelField];
				[visibleCredentialFields addObject:anLabelField];
			}
			
			
			{
				NSRect	labelframe = { horizontalmargin + widthleft + horizontalmargin , verticalmargin + ((fieldheight+verticalmargin) * (i/2)) - bezelheight, widthright, fieldheight+2*bezelheight };
			
				NSTextField	*anInputField;
				
				if( [JNXPasswordPanel_CredentialType_Text isEqual:aType] )
				{
					anInputField = [[NSTextField alloc] initWithFrame:labelframe];
				}
				else if( [JNXPasswordPanel_CredentialType_Password isEqual:aType] )
				{
					anInputField = [[NSSecureTextField alloc] initWithFrame:labelframe];
				}
				else
				{
					continue;
				}
				[contentView addSubview:anInputField];
				[anInputField setEditable:YES];
				[anInputField setBezeled:YES];
				[anInputField setAlignment:NSLeftTextAlignment];
				[anInputField setDrawsBackground:YES];

				[credentialTypeButton setNextKeyView:anInputField];
				[okButton setNextKeyView:credentialTypeButton];
				
				if( i > 1 )
				{
					[anInputField setNextKeyView:[visibleCredentialFields objectAtIndex:i]];
				}
				else
				{
					[anInputField setNextKeyView:saveToKeyChainButton];
				}
				
				
				NSString	*contentString = [credentialsDictionary objectForKey:aLabel];	
				if( contentString ) [anInputField setStringValue:contentString];
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification  object:anInputField];
				
				[visibleCredentialFields addObject:anInputField];
			}
		}
	}

	{
		NSRect	contentframe	= [contentView frame];
		NSRect	windowframe		= [credentialsWindow frame];
		
		NSRect	newwindowframe;
		
		newwindowframe.size.width	= (windowframe.size.width - contentframe.size.width)	+ completewidth;
		newwindowframe.size.height	= (windowframe.size.height - contentframe.size.height)	+ completeheight;
		
		newwindowframe.origin.x		= windowframe.origin.x + (windowframe.size.width/2.0) - (newwindowframe.size.width/2.0);
		newwindowframe.origin.y		= windowframe.origin.y + windowframe.size.height - newwindowframe.size.height;
		
		[credentialsWindow setFrame:newwindowframe display:YES animate:YES];
	}
	[[credentialsWindow contentView] setNeedsDisplay:YES];
	if( ![credentialsWindow isKeyWindow] ) [credentialsWindow makeKeyAndOrderFront:self];
}


- (void)textDidChange:(NSNotification *)aNotification
{
	// DJLog(@"Notification: %@",aNotification);
	NSTextField		*endedTextField = [aNotification object];
	
	if( ! endedTextField )
	{
		JLog(@"Internal weirdness - Textfield could not be found");
		return;
	}
	
	NSInteger		fieldindex = [visibleCredentialFields indexOfObject:endedTextField];
	
	if( (NSNotFound == fieldindex) || (fieldindex < 1) )
	{
		JLog(@"Internal weirdness - index could not be found");
		return;
	}
	
	NSString *keyWithColon	= [[visibleCredentialFields objectAtIndex:fieldindex - 1] stringValue];
	NSString *newKey		= [keyWithColon substringToIndex:[keyWithColon length] -1];
	NSString *newValue		= [endedTextField stringValue];

	// DJLog(@"newKey %@ newValue %@ %@",newKey,newValue,credentialsDictionary);

	if( newKey && newValue )
	{
		[credentialsDictionary setObject:newValue forKey:newKey];
	}
}
	


- (IBAction)buttonOkHasBeenPressed:(id)sender;
{
	DJLOG

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if( credentialTypeButton && [[credentialTypeButton selectedItem] title] )
	{
		[credentialsDictionary setObject:[[credentialTypeButton selectedItem] title] forKey:JNXPasswordPanel_CredentialKey_Protocol];
	}
	
	NSString  *passwordString = nil;

	if( (NSOnState == [saveToKeyChainButton state]) && (passwordString = [credentialsDictionary JNXkeyValueStringEncoded]) )
	{
		// DJLog(@"saving values to keychain :%@",passwordString);

		const char				*processname		= [[NSString stringWithFormat:@"%@: %@",[[NSProcessInfo processInfo] processName],itemName] UTF8String];
		const char				*itemname			= [itemName UTF8String];
		SecKeychainItemRef		keychainItemRef		= nil;
		UInt32					keychainitemlength;
		void					*keychainitemdata;

		OSStatus				error;
		const char				*passwordstring		= [passwordString UTF8String];
		
		
		if( noErr == (error = SecKeychainFindGenericPassword( NULL, (uint32_t)strlen(processname), processname,(uint32_t) strlen(itemname), itemname,  &keychainitemlength, &keychainitemdata,	&keychainItemRef)) )
		{
			if(		(keychainitemlength != strlen(passwordstring))
				||	(NULL==keychainitemdata)
				||	(memcmp(keychainitemdata,passwordstring,keychainitemlength)) )
			{
				if( noErr != (error = SecKeychainItemModifyAttributesAndData(keychainItemRef, NULL, (uint32_t)strlen(passwordstring),passwordstring )) )
				{
					JLog(@"Could not modify password in KeyChain %d",error);
				}
			}
			else
			{
				DJLog(@"Item has not changed");
			}
			if( (error = SecKeychainItemFreeContent( NULL,  keychainitemdata) ) )
			{
				JLog(@"Could not release keychain item - just leaking");
			}

		}
		else if( errSecItemNotFound == error )
		{
			if( noErr != (error = SecKeychainAddGenericPassword( NULL,(uint32_t) strlen(processname), processname, (uint32_t)strlen(itemname), itemname,(uint32_t) strlen(passwordstring), passwordstring, NULL)) )
			{
				JLog(@"Could not save new password to KeyChain %d",error);
			}
		}
		else
		{
			JLog(@"could not access the keychain: %d",error);
		}
	}
	
	[credentialsWindow setDelegate:nil];
	[credentialsWindow close];

	[conditionLock lock];
	[conditionLock unlockWithCondition:CONDITION_HAS_CREDENDIALS];
}

- (void)windowWillClose:(NSNotification *)aNotification;
{
	DJLOG
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	

	credentialsDictionary = nil;
	[conditionLock lock];
	[conditionLock unlockWithCondition:CONDITION_HAS_CREDENDIALS];
}


- (NSDictionary *)credentials;
{
	[conditionLock lockWhenCondition:CONDITION_HAS_CREDENDIALS];
	[conditionLock unlock];
	
	if( ![credentialsDictionary objectForKey:JNXPasswordPanel_CredentialKey_Protocol] )
	{
		id value = [[credentialTypesArray objectAtIndex:0] objectForKey:JNXPasswordPanel_Credential_Protocol];
		DJLog(@"Credentials dictionary has no Key_Protocol set - using %@",value);
		if( value ) [credentialsDictionary setObject:value forKey:JNXPasswordPanel_CredentialKey_Protocol];
	}
	//DJLog(@"%@",credentialsDictionary);
	
	return (NSDictionary *)credentialsDictionary;
}

@end
