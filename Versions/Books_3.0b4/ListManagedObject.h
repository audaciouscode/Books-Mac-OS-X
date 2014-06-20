//
//  "ListManagedObject.h"
//  Books
//
//  Created by Chris Karr on 10/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ListManagedObject : NSManagedObject 
{
	NSData * iconData;
}

- (NSData *) getIcon;
- (void) setIcon: (NSData *) icon;

- (NSArray *) getBooks;

- (BOOL) getCanAdd;
- (void) setCanAdd: (BOOL) canAdd;

@end
