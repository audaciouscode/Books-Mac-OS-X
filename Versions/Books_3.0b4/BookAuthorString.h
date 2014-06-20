//
//  BookAuthorString.h
//  Books
//
//  Created by Chris Karr on 1/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookTitleString.h"

@interface BookAuthorString : BookTitleString 
{
	NSString * sortAuthors;
}

-(NSString *) getSortString;

@end
