//
//  BookTitleString.h
//  Books
//
//  Created by Chris Karr on 1/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BookTitleString : NSString 
{
	NSString * store;
	NSString * sortString;
}

- (NSComparisonResult) compare: (BookTitleString *) string;
- (NSString *) getSortString;

@end
