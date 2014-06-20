//
//  CoverImageDelegate.h
//  Books
//
//  Created by Chris Karr on 3/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CoverWindowDelegate : NSObject 
{
	NSWindow * target;
}

- (void) setTarget:(NSWindow *) window;
- (BOOL) windowShouldClose:(id) sender;
@end
