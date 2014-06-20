/*
   Copyright (c) 2006 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/


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