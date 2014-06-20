//
//  ExportMenuDelegate.h
//  Books
//
//  Created by Chris Karr on 7/26/05.
//  Copyright 2005 Chris Karr. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ExportMenuDelegate : NSObject 
{
	NSMutableDictionary * plugins;
	NSArray * pluginKeys;
}

- (void) findPlugins;
- (int) numberOfItemsInMenu:(NSMenu *) menu;
- (BOOL) menu:(NSMenu *) menu updateItem:(NSMenuItem *) item atIndex:(int) index shouldCancel:(BOOL) shouldCancel;
- (IBAction) exportFromMenuItem:(NSMenuItem *) menuItem;

@end
