//
//  PluginManager.m
//  Books
//
//  Created by Chris Karr on 4/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PluginManager.h"
#import "BooksAppDelegate.h"

@implementation PluginManager

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
	
		[[column dataCell] setFont:[NSFont systemFontOfSize:11]];
	}
}

- (NSDictionary *) getPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];

	NSString * path;
 
	NSMutableDictionary * plugins = [[NSMutableDictionary alloc] init];
 
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
	[((BooksAppDelegate *) [NSApp delegate]) startProgressWindow:NSLocalizedString (@"Downloading and installing plugin...", nil)];

	NSBundle * bundle = [NSBundle mainBundle];
	
	NSString * path = [bundle pathForResource:@"plugin-installer" ofType:@"sh"];

	NSTask * task = [NSTask launchedTaskWithLaunchPath:path arguments:[NSArray arrayWithObject:url]];
	
	[task waitUntilExit];
	
	[((BooksAppDelegate *) [NSApp delegate]) endProgressWindow];

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
		[pluginManagerWindow makeKeyAndOrderFront:sender];
}

- (IBAction) fetchOnlineList: (id) sender
{
	[arrayController removeObjects:[arrayController arrangedObjects]];
	
	[managedPlugins release];
	managedPlugins = nil;
	
	[arrayController addObjects:[self getManagedPlugins]];
}

@end
