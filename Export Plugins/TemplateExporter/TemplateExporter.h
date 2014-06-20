//
//  TemplateExporter.h
//  TemplateExporter
//
//  Created by Chris Karr on 10/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TemplateExporter : NSObject 
{
    IBOutlet id menu;
    IBOutlet id quitMenuItem;
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;

@end
