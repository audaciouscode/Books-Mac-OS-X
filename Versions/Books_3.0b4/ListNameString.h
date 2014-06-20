//
//  ListNameString.h
//  Books
//
//  Created by Chris Karr on 1/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ListNameString : NSString 
{
	NSString * store;
}

- (NSComparisonResult) compare: (NSString *) string;

@end
