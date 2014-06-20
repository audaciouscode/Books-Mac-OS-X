//
//  ViewControls.h
//  Books
//
//  Created by Chris Karr on 8/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ViewControls : NSObject 
{
	IBOutlet NSView * view;
}

- (NSView *) view;
- (NSString *) title;

@end
