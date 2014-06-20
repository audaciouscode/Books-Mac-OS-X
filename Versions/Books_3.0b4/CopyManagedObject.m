//
//  CopyManagedObject.m
//  Books
//
//  Created by Chris Karr on 4/18/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CopyManagedObject.h"
#import <AddressBook/AddressBook.h>

@implementation CopyManagedObject

- (void) awakeFromInsert
{
	[super awakeFromInsert];
	
	ABPerson * me = [[ABAddressBook sharedAddressBook] me];
	
	NSString * name = [NSString stringWithFormat:@"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty], nil];
	
	[self setValue:name forKey:@"owner"];
}

@end
