//
//  Smart"ListManagedObject.h"
//  Books
//
//  Created by Chris Karr on 10/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ListManagedObject.h"

@interface SmartList : ListManagedObject
{
	NSPredicate * predicate;

	NSSet * listItems;
	NSDate * nextFetch;
}

- (NSPredicate *) getPredicate;
- (void) setPredicate:(NSPredicate *) newPredicate; 

- (NSData *) getIcon;

- (BOOL) getCanAdd;
- (void) setCanAdd: (BOOL) canAdd;

@end
