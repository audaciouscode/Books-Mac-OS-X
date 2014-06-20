#import "AppDelegate.h"

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@implementation AppDelegate

- (NSString *) getPasswordString
{
	NSString * usernameString = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	
	if (usernameString == nil)
		return nil;
		
	const char * userData = [usernameString cStringUsingEncoding:NSASCIIStringEncoding];
	UInt32 uLength = [usernameString lengthOfBytesUsingEncoding:NSASCIIStringEncoding];

	void * passwordData = nil;
	UInt32 pLength = nil;

	OSStatus status;

	status = SecKeychainFindGenericPassword (
		NULL,															// default keychain
		27,																// length of service name
		"WhatsOnMyBookshelf Exporter",									// service name
		uLength,														// length of account name
		userData,														// account name
		&pLength,														// length of password
		&passwordData,													// pointer to password data
		NULL															// the item reference
    );
	
	if (status == noErr)
	{
		char * buffer = (char *) malloc ((pLength + 1) * sizeof (char));
		strncpy (buffer, passwordData, pLength);
		buffer[pLength] = 0;
		NSString * passwordString = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
		free (buffer);

		return [passwordString retain];
	}

	return nil;
}

- (void) setPasswordString: (NSString *) passwordString
{
	NSString * usernameString = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];

	const char * userData = [usernameString cStringUsingEncoding:NSASCIIStringEncoding];
	UInt32 uLength = [usernameString lengthOfBytesUsingEncoding:NSASCIIStringEncoding];

	OSStatus status;

	const char * passwordData = [passwordString cStringUsingEncoding:NSASCIIStringEncoding];
	UInt32 pLength = [passwordString lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
	
	if ([self getPasswordString] == nil)
	{
		status = SecKeychainAddGenericPassword (
                NULL,															// default keychain
                27,																// length of service name
                "WhatsOnMyBookshelf Exporter",									// service name
                uLength,														// length of account name
                userData,														// account name
                pLength,														// length of password
                passwordData,													// pointer to password data
                NULL															// the item reference
		);
		
		return;
	}
	else
	{
		SecKeychainItemRef item = nil;
		
		status = SecKeychainFindGenericPassword (
			NULL,															// default keychain
			27,																// length of service name
			"WhatsOnMyBookshelf Exporter",									// service name
			uLength,														// length of account name
			userData,														// account name
			NULL,															// length of password
			NULL,															// pointer to password data
			&item															// the item reference
		);

		status = SecKeychainItemDelete (item);

		[self setPasswordString:passwordString];

		if (status == noErr)
			return;
		else
		{
			NSLog (@"Error saving password: %d", status);
			return;
		}
	}
}

- (IBAction) myInventory: (id) sender
{
	NSString * usernameString = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
	
	if (usernameString == nil || [usernameString isEqual:@""])
		NSRunAlertPanel (@"No Username Found!", @"Please enter a username in provided field.", @"OK", nil, nil);
	else
	{
		NSString * urlString = [NSString stringWithFormat:@"http://www.whatsonmybookshelf.com/users/%@", usernameString, nil];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
	}
}

- (IBAction)upload:(id)sender
{
	[progressBar startAnimation:sender];
	[NSApp beginSheet:progressWindow modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:NULL];
	
	NSString * passwordString = [password stringValue];

	NSString * usernameString = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];

	if (usernameString == nil || [usernameString isEqual:@""])
	{
		NSRunAlertPanel (@"No Username Found!", @"Please enter a username in provided field.", @"OK", nil, nil);
		return;
	}
	
	NSArray * books = [tableArray arrangedObjects];
	
	NSMutableString * isbnList = [NSMutableString string];
	
	int i = 0;
	for (i = 0; i < [books count]; i++)
	{
		NSString * isbn = [[books objectAtIndex:i] valueForKey:@"isbn"];
		
		if (isbn != nil)
		{
			NSString * tagString = [[books objectAtIndex:i] valueForKey:@"tags"];
			
			if (tagString == nil)
				tagString = @"";

			NSString * commentStr = [[books objectAtIndex:i] valueForKey:@"comment"];
			
			if (commentStr == nil)
				commentStr = @" ";

			NSMutableString * commentString = [NSMutableString stringWithString:commentStr];
			[commentString replaceOccurrencesOfString:@"\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange (0, [commentString length])];
			[commentString replaceOccurrencesOfString:@"\r" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange (0, [commentString length])];
				
			[isbnList appendString:[NSString stringWithFormat:@"%@\t%@\t%@\n", isbn, tagString, commentString, nil]];
		}
	}
	
	[isbnList writeToFile:@"/tmp/books-export/womb.txt" atomically:YES encoding:NSASCIIStringEncoding error:nil];

	NSBundle * bundle = [NSBundle mainBundle];

	NSString * scriptName = @"womb.py";
	NSString * scriptPath = [bundle pathForResource:[scriptName stringByDeletingPathExtension] 
		ofType:[scriptName pathExtension]];
	
	NSTask * task = [[NSTask alloc] init];
	
	[task setLaunchPath:scriptPath];
	[task setCurrentDirectoryPath:[scriptPath stringByDeletingLastPathComponent]];
	
	NSArray * arguments = [NSArray arrayWithObjects:usernameString, passwordString, nil];
	[task setArguments:arguments];
	
	[task launch];
	
	[task waitUntilExit];
	
	if ([task terminationStatus] == 255)
	{
		NSRunAlertPanel (@"Bad Password!", @"Your password is incorrect.", @"OK", nil, nil);
		return;
	}
	else
	{
		NSString * wombError = [NSString stringWithContentsOfFile:@"/tmp/books-export/womb.error" encoding:NSASCIIStringEncoding error:nil];

		if (!(wombError == nil || [wombError isEqualTo:@""]))
		{
			[errorText setString:wombError];
			[errorWindow makeKeyAndOrderFront:sender];
		}
	}
	
	[NSApp endSheet:progressWindow];
	[progressWindow orderOut:sender];
	
	[progressBar stopAnimation:sender];
}

- (void)windowWillClose: (NSNotification *) aNotification
{
	[NSApp terminate:nil];
}

- (void)applicationWillTerminate: (NSNotification *) aNotification
{
	NSString * passwordString = [password stringValue];
	NSString * keychainPassword = [self getPasswordString];

	if (keychainPassword == nil || ![keychainPassword isEqualTo:passwordString] )
		[self setPasswordString:passwordString];
}

- (void) awakeFromNib
{
	NSTableColumn * column = [[tableView tableColumns] objectAtIndex:0];
	
	[[column dataCell] setFont:[NSFont systemFontOfSize:11]];

	NSError * error;
	
	NSURL * url = [NSURL URLWithString:@"file:///tmp/books-export/books-export.xml"];
	
	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:url options:NSXMLDocumentTidyXML error:&error];

	if (xml != nil)
	{
		NSArray * books = [[xml rootElement] elementsForName:@"Book"];
		
		int i = 0;
		for (i = 0; i < [books count]; i++)
		{
			NSXMLElement * book = [books objectAtIndex:i];
			NSArray * fields = [book elementsForName:@"field"];

			NSMutableDictionary * bookObject = [NSMutableDictionary dictionary];

			int j = 0;
			for (j = 0; j < [fields count]; j++)
			{
				NSXMLElement * field = [fields objectAtIndex:j];
				
				NSString * key = [[field attributeForName:@"name"] stringValue];
				NSString * value = [field stringValue];
				
				[bookObject setValue:value forKey:key];
			}
			
			if ([bookObject valueForKey:@"isbn"] != nil)
				[tableArray addObject:bookObject];
		}
	}
	else
	{
        NSRunAlertPanel (@"Error", @"Unable to locate book data. Check your Books installation.", @"Quit", nil, nil);
		
		[NSApp terminate:self];
	}

	NSString * passwordString = [self getPasswordString];

	if (passwordString != nil)
		[password setStringValue:passwordString];
		
	[window makeKeyAndOrderFront:nil];
}

@end
