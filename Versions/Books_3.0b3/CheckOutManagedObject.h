//
//  CheckOutManagedObject.h
//  Books
//
//  Created by Chris Karr on 4/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CheckOutManagedObject : NSManagedObject 
{
	NSData * image;
}

- (NSData *) getImage;
- (void) setImage:(NSData *) data;

- (NSString *) getBorrower;
- (void) setBorrower:(NSString *) borrower;

@end
