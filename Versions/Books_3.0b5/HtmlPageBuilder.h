//
//  HtmlPageBuilder.h
//  Books
//
//  Created by Chris Karr on 9/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookManagedObject.h"

@interface HtmlPageBuilder : NSObject 
{
	NSMutableDictionary * displayPlugins;
	NSDateFormatter * formatter;
}

- (NSString *) getCssPath;

// (String) getCssPath ()
- (NSString *) buildPageForObject: (BookManagedObject *) object;
- (NSString *) buildEmptyPage;
- (NSString *) buildPageForArray: (NSArray *) array;
- (NSDictionary *) getDisplayPlugins;
- (NSBundle *) getDisplayPlugin;

@end
