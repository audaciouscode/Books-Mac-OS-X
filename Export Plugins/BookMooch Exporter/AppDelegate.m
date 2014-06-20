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
		"BookMooch Exporter",											// service name
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
                "BookMooch Exporter",											// service name
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
			"BookMooch Exporter",											// service name
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
		NSString * urlString = [NSString stringWithFormat:@"http://www.bookmooch.com/m/inventory/%@", usernameString, nil];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
	}
}

- (IBAction)upload:(id)sender
{
	NSString * keychainPassword = [self getPasswordString];
	NSString * passwordString = [password stringValue];

	if (![keychainPassword isEqualTo:passwordString])
		[self setPasswordString:passwordString];
	
	NSMutableString * isbnStrings = [NSMutableString string];

	int i = 0;
	for (i = 0; i < [[tableArray arrangedObjects] count]; i++)
	{
		NSString * isbn = [[[tableArray arrangedObjects] objectAtIndex:i] valueForKey:@"isbn"];

		if (isbn != nil)
		{
			[isbnStrings appendString:isbn];
			[isbnStrings appendString:@"+"];
		}
	}
	
	NSMutableString * urlString = [NSMutableString stringWithString:@"http://"];
	[urlString appendString:[username stringValue]];
	[urlString appendString:@":"];
	[urlString appendString:[password stringValue]];
	[urlString appendString:@"@bookmooch.com/api/userbook?n=1&target=inventory&action=add&o=xml&asins="];
	[urlString appendString:isbnStrings];

	NSXMLDocument * xml = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:urlString] options:NSXMLDocumentTidyXML error:NULL];
	
	if (xml == nil)
        NSRunAlertPanel (@"Error", @"Unable to upload book data. Check your username and password.", @"OK", nil, nil);
	else
        NSRunAlertPanel (@"Success!", @"Your books have been successfully listed.", @"OK", nil, nil);
}

- (void)windowWillClose: (NSNotification *) aNotification
{
	[NSApp terminate:nil];
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
}

@end
