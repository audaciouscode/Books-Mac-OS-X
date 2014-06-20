//
//  BooksToolbarItem.h
//  Books
//
//  Created by Chris Karr on 10/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BooksToolbarItem : NSToolbarItem 
{
	BOOL enableBool;
	SEL itemAction;
}

- (void) setEnabled:(BOOL) enable;
- (BOOL) isEnabled;

@end
