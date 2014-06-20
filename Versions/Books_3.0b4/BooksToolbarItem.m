//
//  BooksToolbarItem.m
//  Books
//
//  Created by Chris Karr on 10/17/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BooksToolbarItem.h"

@implementation BooksToolbarItem

- (BooksToolbarItem *) initWithItemIdentifier: (NSString *) itemIdentifier
{
	self = [super initWithItemIdentifier:itemIdentifier];
	
	enableBool = YES;
	
	return self;
}

- (void) setEnabled:(BOOL) enable
{
	enableBool = enable;

	if (!enableBool)
		[self setAction:itemAction];
	else
	{
		itemAction = [self action];
		[self setAction:nil];
	}
}

- (BOOL) isEnabled
{
	return enableBool;
}

@end
