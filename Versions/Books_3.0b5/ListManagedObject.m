//
//  List.m
//  Books
//
//  Created by Chris Karr on 10/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ListManagedObject.h"
#import "BooksAppDelegate.h"
#import "ListNameString.h"

@implementation ListManagedObject

- (NSData *) getIcon
{
	if (iconData == nil)
		iconData = [[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"list-small" ofType:@"png"]] retain];

	return iconData;	
}

- (void) setIcon: (NSData *) icon
{

}

- (NSArray *) getBooks
{
	return [[self valueForKey:@"items"] allObjects];
}

- (NSScriptObjectSpecifier *) objectSpecifier
{
	BooksAppDelegate * delegate = [[NSApplication sharedApplication] delegate];
	
	NSIndexSpecifier * specifier = [[NSIndexSpecifier alloc] 
										initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:[delegate class]] 
										containerSpecifier:[delegate objectSpecifier]
										key:@"booklists"];
	
	return specifier;
}

- (BOOL) getCanAdd
{
	return YES;
}

- (void) setCanAdd: (BOOL) canAdd
{

}

/* - (NSString *) getName
{
	return [ListNameString stringWithString:[self primitiveValueForKey:@"name"]];
}*/

@end
