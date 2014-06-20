//
//  ImportMenuDelegate.h
//  Books
//
//  Created by Chris Karr on 7/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImportMenuDelegate : NSObject 
{
	NSMutableDictionary * plugins;
	NSArray * pluginKeys;
}

- (void) findPlugins;
- (int) numberOfItemsInMenu:(NSMenu *) menu;
- (BOOL) menu:(NSMenu *) menu updateItem:(NSMenuItem *) item atIndex:(int) index shouldCancel:(BOOL) shouldCancel;
- (IBAction) importFromMenuItem:(NSMenuItem *) menuItem;

@end
