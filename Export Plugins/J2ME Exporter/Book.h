//
//  Book.h
//  J2ME Exporter
//
//  Created by Chris Karr on 2/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Book : NSObject 
{
	NSMutableDictionary * dict;
}

- (Book *) init;
- (NSString *) getTitle;
- (void) setTitle: (NSString *) t;
- (NSString *) getAuthors;
- (void) setAuthors: (NSString *) t;
- (NSString *) getIsbn;
- (void) setIsbn: (NSString *) t;
- (NSString *) getPublisher;
- (void) setPublisher: (NSString *) t;
- (NSString *) getGenre;
- (void) setGenre: (NSString *) t;
- (NSDate *) getPublishDate;
- (void) setPublishDate: (NSDate *) d;

@end
