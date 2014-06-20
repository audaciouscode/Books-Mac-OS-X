//
//  MainWindow.m
//  Books
//
//  Created by Chris Karr on 8/5/08.
//  Copyright 2008 Northwestern University. All rights reserved.
//

#import "MainWindow.h"


@implementation MainWindow

- (void)sendEvent:(NSEvent *)event
{
	if ([event type] == NSKeyDown && [event keyCode] == 3 && ([event modifierFlags] & NSCommandKeyMask))
	{
		NSToolbar * toolbar = [self toolbar];
		
		if ([toolbar isVisible])
		{
			NSArray * items = [toolbar visibleItems];
			
			NSEnumerator * e = [items objectEnumerator];
			NSToolbarItem * item = nil;
			
			while (item = [e nextObject])
			{
				if ([[item itemIdentifier] isEqual:@"search"])
				{
					[self makeFirstResponder:[[[item view] subviews] lastObject]];
					
					return;
				}
			}
		}
	}

	[super sendEvent:event];
}

@end
