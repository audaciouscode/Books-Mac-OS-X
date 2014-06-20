//
//  SmartList.m
//  Books
//
//  Created by Chris Karr on 10/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SmartList.h"
#import "SmartListNameString.h"

@implementation SmartList

- (NSPredicate *) getPredicate
{
	if (predicate == nil)
	{
	    [self willAccessValueForKey:@"predicateString"];
		NSString * p = [self primitiveValueForKey:@"predicateString"];
		[self didAccessValueForKey:@"predicateString"];

		predicate = [[NSPredicate predicateWithFormat:p] retain];
	}

	return predicate;
}

- (void) setPredicateString: (NSString *) newRules
{
	NSPredicate * rules = [NSPredicate predicateWithFormat:newRules];
	
	[self setPredicate:rules];
}

- (void )setPredicate:(NSPredicate *) newPredicate
{
	NSString * p = [newPredicate predicateFormat];

    [self willChangeValueForKey:@"items"];

	predicate = newPredicate;

    [self willChangeValueForKey:@"predicateString"];
    [self setPrimitiveValue:p forKey:@"predicateString"];
    [self didChangeValueForKey:@"predicateString"];

	[listItems release];
	listItems = nil;

    [self didChangeValueForKey:@"items"];
}

- (NSSet *) getItems
{
	if (predicate == nil)
		predicate = [self getPredicate];
		
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[self managedObjectContext]]];
	[fetch setPredicate:predicate];

	NSMutableSet * set = [[NSMutableSet alloc] init];
	
	NSError * error = nil;
	NSArray * results = [[self managedObjectContext] executeFetchRequest:fetch error:&error];
	
	if (results != nil)
		[set addObjectsFromArray:results];

	listItems = set;

	return listItems;
}

/* - (NSString *) getName
{
	return [SmartListNameString stringWithString:[self primitiveValueForKey:@"name"]];
} */

- (void) setItems: (NSSet *) set
{

}

- (NSData *) getIcon
{
	if (iconData == nil)
		iconData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"smartlist-small" ofType:@"png"]] retain];

	return iconData;	
}

- (BOOL) getCanAdd
{
	return NO;
}

- (void) setCanAdd: (BOOL) canAdd
{

}

@end