//
//  ExportPluginInterface.h
//  Books
//
//  Created by Chris Karr on 7/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ExportPluginInterface : NSObject 
{
	NSTask * exportTask;
}

- (void) exportToBundle: (NSBundle *) bundle;

@end
