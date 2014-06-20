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


#import "CheckOutManagedObject.h"
#import "BooksAppDelegate.h"
#import <AddressBook/AddressBook.h>

@implementation CheckOutManagedObject

- (void) didChangeValueForKey: (NSString *) key
{
	[super didChangeValueForKey:key];
	
	[((BooksAppDelegate *) [NSApp delegate]) updateMainPane];
}

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
