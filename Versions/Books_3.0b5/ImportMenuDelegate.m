//
// ImportMenuDelegate.m
// Books
//
// Created by Chris Karr on 7/26/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ImportMenuDelegate.h"
#import "ImportPluginInterface.h"

@implementation ImportMenuDelegate

- (void) findPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [NSHomeDirectory () stringByAppendingPathComponent:appSupport];
	NSString * sysPath = [@"/" stringByAppendingPathComponent:appSupport];

	NSArray * paths = [NSArray arrayWithObjects:appPath, sysPath, userPath, nil];

	NSEnumerator * pathEnum = [paths objectEnumerator];
	
	NSString * path;
 
	plugins = [[NSMutableDictionary alloc] init];
 
	while (path = [pathEnum nextObject])
	{
		NSEnumerator * e = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];

		NSString * name;

		while (name = [e nextObject])
		{
			if ([[name pathExtension] isEqualToString:@"app"])
			{
				NSBundle * plugin = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:name]];
				
				NSDictionary * pluginDict = [plugin infoDictionary];
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Import"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[plugins setObject:plugin forKey:pluginName];
				}
			}
		}
	}

	pluginKeys = [[plugins allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	[pluginKeys retain];
}

- (int) numberOfItemsInMenu:(NSMenu *) menu;
{
	if (plugins == nil)
		[self findPlugins];

	return [plugins count];
}

- (BOOL) menu:(NSMenu *) menu updateItem:(NSMenuItem *) item atIndex:(int) index shouldCancel:(BOOL) shouldCancel;
{
	if (plugins == nil)
		[self findPlugins];

	NSString * title = (NSString *) [pluginKeys objectAtIndex:index];

	NSBundle * bundle = (NSBundle *) [plugins objectForKey:title];

	[item setTitle:title];
	[item setRepresentedObject:bundle];

	[item setTarget:self];
	[item setAction:NSSelectorFromString (@"importFromMenuItem:")];
	
	return YES;
}

- (IBAction) importFromMenuItem:(NSMenuItem *) menuItem
{
	NSBundle * importPlugin = (NSBundle *) [menuItem representedObject];
	
	ImportPluginInterface * import = [[ImportPluginInterface alloc] init];
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"importFromBundle:") toTarget:import withObject:importPlugin];
}

@end
