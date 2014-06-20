//
//  CheckOutManagedObject.m
//  Books
//
//  Created by Chris Karr on 4/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CheckOutManagedObject.h"
#import <AddressBook/AddressBook.h>

@implementation CheckOutManagedObject

- (NSData *) getImage
{
	if (image == nil)
	{
		NSString * borrower = [self valueForKey:@"borrower"];

		NSArray * abPeople = [[ABAddressBook sharedAddressBook] people];
		
		int i = 0;
		for (i = 0; i < [abPeople count]; i++)
		{
			ABPerson * person = [abPeople objectAtIndex:i];
			
			NSString * firstName = [person valueForProperty:kABFirstNameProperty];
			NSString * lastName = [person valueForProperty:kABLastNameProperty];
			
			NSString * name = [NSString stringWithFormat:@"%@ %@", firstName, lastName, nil];

			if (firstName != nil && lastName != nil)
			{
				if ([borrower isEqual:name])
					image = [person imageData];
			}
		}
	}
	
	if (image == nil)
		image = [NSData data];
	
	[image retain];
	
	return image;
}

- (void) setImage:(NSData *) data
{
	[self willChangeValueForKey:@"image"];

	image = data;

	[self didChangeValueForKey:@"image"];
}

- (NSString *) getBorrower
{
	return [self primitiveValueForKey:@"borrower"];
}

- (void) setBorrower:(NSString *) borrower
{
	[self willChangeValueForKey:@"borrower"];

	[self setPrimitiveValue:borrower forKey:@"borrower"];

	[self setValue:nil forKey:@"image"];

	[self didChangeValueForKey:@"borrower"];
}




@end
