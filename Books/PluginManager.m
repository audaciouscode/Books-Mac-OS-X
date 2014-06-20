/*
   Copyright (c) 2006 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/

#import "PluginManager.h"
#import "BooksAppDelegate.h"
#import "BooksDataFolder.h"

@implementation PluginManager

- (void) dealloc
{
	[super dealloc];
}

- (NSArray *) getManagedPlugins
{
	if (managedPlugins == nil)
	{
		managedPlugins = [[NSMutableArray alloc] init];
		
		NSDictionary * plugins = [self getPlugins];
		NSArray * keys = [plugins allKeys];
		
		int i = 0;
		for (i = 0; i < [keys count]; i++)
		{
			NSString * key = [keys objectAtIndex:i];
			NSDictionary * pluginInfo = [plugins valueForKey:key];

			NSString * type = [pluginInfo valueForKey:@"BooksPluginType"];
			
			if (type != nil)
			{
				NSMutableDictionary * plugin = [NSMutableDictionary dictionary];
				[plugin setValue:key forKey:@"name"];

				NSString * version = [pluginInfo valueForKey:@"CFBundleVersion"];
			
				if (version != nil)
					[plugin setValue:version forKey:@"version"];

				NSString * desc = [pluginInfo valueForKey:@"PluginDescription"];
			
				if (desc == nil)
					desc = [NSString stringWithFormat:NSLocalizedString (@"%@ plugin. (No description provided.)", nil), type, nil];

				[plugin setValue:desc forKey:@"description"];
			
				if ([pluginInfo valueForKey:@"URL"] == nil)
					[plugin setValue:NSLocalizedString (@"Installed", nil) forKey:@"status"];
				else
					[plugin setValue:[pluginInfo valueForKey:@"URL"] forKey:@"URL"];
					
				[plugin setValue:type forKey:@"type"];

				[managedPlugins addObject:plugin];
			}
		}
	}
	
	return managedPlugins;
}

- (void) setManagedPlugins: (NSArray *) plugins
{

}

- (void) awakeFromNib
{
	NSArray * columns = [pluginListTable tableColumns];
	
	int i = 0;
	for (i = 0; i < [columns count]; i++)
	{
		NSTableColumn * column = [columns objectAtIndex:i];
	
		NSString * name = [[[column headerCell] stringValue] lowercaseString];

		NSSortDescriptor * descriptor = nil;
		
		if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
			descriptor = [[NSSortDescriptor alloc] initWithKey:name ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
		else
			descriptor = [[NSSortDescriptor alloc] initWithKey:name ascending:YES selector:@selector(caseInsensitiveCompare:)];
			
		[column setSortDescriptorPrototype:descriptor];
		
		[descriptor release];
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}

	NSSortDescriptor * descriptor = nil;
	
	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" 
												 ascending:YES 
												  selector:@selector(localizedCaseInsensitiveCompare:)];
	else
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" 
												 ascending:YES 
												  selector:@selector(caseInsensitiveCompare:)];

	[pluginListTable setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	
	[descriptor release];
	
	[pluginListTable setAllowsEmptySelection:YES];
	[pluginListTable deselectAll:self];
	[pluginListTable scrollRowToVisible:0];
}

- (NSDictionary *) getPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingPathComponent:@"/Plugins"];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	NSMutableDictionary * plugins = [NSMutableDictionary dictionary];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
			NSDictionary * pluginDict = [plugin infoDictionary];
			NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];
			
			if ([pluginDict objectForKey:@"BooksPluginType"] != nil && pluginName != nil)
				[plugins setObject:[plugin infoDictionary] forKey:pluginName];
			
			[pluginName release];
		}
	}
	
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"Online plugin lookup"] == nil ||
		[[NSUserDefaults standardUserDefaults] boolForKey:@"Online plugin lookup"])
	{
		NSArray * remotePlugins = [NSPropertyListSerialization propertyListFromData:[NSData 
				dataWithContentsOfURL:[NSURL URLWithString:@"http://books.aetherial.net/downloads/plugins.xml"]]
				mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];

		int i = 0; 
		for (i = 0; remotePlugins != nil && i < [remotePlugins count]; i++)
		{
			NSMutableDictionary * plugin = [NSMutableDictionary dictionaryWithDictionary:[remotePlugins objectAtIndex:i]];
		
			NSString * name = [plugin valueForKey:@"BooksPluginName"];
			NSString * version = [plugin valueForKey:@"CFBundleVersion"];
		
			NSDictionary * info = [plugins objectForKey:name];
		
			if (info != nil)
			{
				if (![version isEqualToString:[info valueForKey:@"CFBundleVersion"]])
					[plugins setObject:plugin forKey:name];
			}
			else
				[plugins setObject:plugin forKey:name];
		}
	}
	
	return plugins;
}

- (void) installFromUrl:(NSString *) url
{
	NSNotification * msg = [NSNotification notificationWithName:BOOKS_START_PROGRESS_WINDOW object:NSLocalizedString (@"Downloading and installing plugin...", nil)];
	[[NSNotificationCenter defaultCenter] postNotification:msg];

	NSBundle * bundle = [NSBundle mainBundle];
	
	NSString * path = [bundle pathForResource:@"plugin-installer" ofType:@"sh"];

	NSTask * task = [NSTask launchedTaskWithLaunchPath:path arguments:[NSArray arrayWithObject:url]];
	
	[task waitUntilExit];
	
	msg = [NSNotification notificationWithName:BOOKS_END_PROGRESS_WINDOW object:nil];
	[[NSNotificationCenter defaultCenter] postNotification:msg];

	NSRunAlertPanel (NSLocalizedString (@"Plugin Installed", nil), NSLocalizedString (@"The new plugin has been installed. Please restart Books to use the new plugin.", nil), NSLocalizedString (@"OK", nil), nil, nil);
}	

- (IBAction) installSelectedPlugin: (id) sender;
{
	NSArray * selectedPlugins = [arrayController selectedObjects];
	
	int i = 0; 
	for (i = 0; i < [selectedPlugins count]; i++)
	{
		NSDictionary * plugin = [selectedPlugins objectAtIndex:i];
		
		NSString * url = [plugin valueForKey:@"URL"];

		if (url != nil)
		{
			int choice = NSRunAlertPanel (NSLocalizedString (@"Install Plugin?", nil), NSLocalizedString (@"Are you sure you want to download and install the selected plugin? It may take several minutes.", nil), NSLocalizedString (@"No", nil), NSLocalizedString (@"Yes", nil), nil);
				
			if (choice == NSAlertAlternateReturn)
			{
				[self installFromUrl:url];
			
				[plugin setValue:NSLocalizedString (@"Installed", nil) forKey:@"status"];
			}
		}
	}
}

- (IBAction) toggleVisible: (id) sender
{
	if (![pluginManagerWindow isVisible])
	{
		[pluginManagerWindow center];
		[pluginManagerWindow makeKeyAndOrderFront:sender];
	}
}

- (IBAction) fetchOnlineList: (id) sender
{
	[arrayController removeObjects:[arrayController arrangedObjects]];
	
	[managedPlugins release];
	managedPlugins = nil;
	
	[arrayController addObjects:[self getManagedPlugins]];
}

@end
