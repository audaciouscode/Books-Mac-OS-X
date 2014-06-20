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


#import "ExportMenuDelegate.h"
#import "ExportPluginInterface.h"
#import "BooksDataFolder.h"
#import "BooksAppDelegate.h"

@implementation ExportMenuDelegate

- (void) findPlugins
{
	NSString * appSupport = @"Library/Application Support/Books/Plugins/";
	NSString * appPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
	
	NSString * userPath = [[BooksDataFolder booksDataFolder] stringByAppendingPathComponent:@"/Plugins"];
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
				
				if ([[pluginDict objectForKey:@"BooksPluginType"] isEqual:@"Export"])
				{
					NSString * pluginName = (NSString *) [[pluginDict objectForKey:@"BooksPluginName"] copy];

					[plugins setObject:plugin forKey:pluginName];
					[pluginName release];
				}
			}
		}
	}

	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		pluginKeys = [[plugins allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	else
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
	[item setAction:NSSelectorFromString (@"exportFromMenuItem:")];
	
	return YES;
}

- (IBAction) exportFromMenuItem:(NSMenuItem *) menuItem
{
	NSBundle * exportPlugin = (NSBundle *) [menuItem representedObject];
	
	ExportPluginInterface * export = [[ExportPluginInterface alloc] init];
	
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"exportToBundle:") toTarget:export withObject:exportPlugin];
	
	[export release];
}

- (void) dealloc
{
	if (plugins != nil)
		[plugins release];
	
	if (pluginKeys != nil)
		[pluginKeys release];
	
	[super dealloc];
}


@end
