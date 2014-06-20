//
//  PluginManager.h
//  Books
//
//  Created by Chris Karr on 4/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PluginManager : NSObject 
{
	NSMutableArray * managedPlugins;
	
	IBOutlet NSWindow * pluginManagerWindow;
	IBOutlet NSTableView * pluginListTable;
	IBOutlet NSArrayController * arrayController;
}

- (NSArray *) getManagedPlugins;
- (void) setManagedPlugins: (NSArray *) plugins;
- (void) awakeFromNib;
- (NSDictionary *) getPlugins;

- (IBAction) toggleVisible: (id) sender;
- (IBAction) installSelectedPlugin: (id) sender;

- (void) installFromUrl:(NSString *) url;

- (IBAction) fetchOnlineList: (id) sender;

@end
