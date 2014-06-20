//
//  Book.m
//  J2ME Exporter
//
//  Created by Chris Karr on 2/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Book.h"

@implementation Book

- (Book *) init
{
	dict = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (NSString *) getTitle
{
	return [dict valueForKey:@"title"];
}

- (void) setTitle: (NSString *) t
{
	[dict setValue:t forKey:@"title"];
}

- (NSString *) getAuthors
{
	return [dict valueForKey:@"authors"];
}

- (void) setAuthors: (NSString *) t
{
	[dict setValue:t forKey:@"authors"];
}

- (NSString *) getIsbn
{
	return [dict valueForKey:@"isbn"];
}

- (void) setIsbn: (NSString *) t
{
	[dict setValue:t forKey:@"isbn"];
}

- (NSString *) getPublisher
{
	return [dict valueForKey:@"publisher"];
}

- (void) setPublisher: (NSString *) t
{
	[dict setValue:t forKey:@"publisher"];
}

- (NSString *) getGenre
{
	return [dict valueForKey:@"genre"];
}

- (void) setGenre: (NSString *) t
{
	[dict setValue:t forKey:@"genre"];
}

- (NSDate *) getPublishDate
{
	return [dict valueForKey:@"publishDate"];
}

- (void) setPublishDate: (NSDate *) d
{
	[dict setValue:d forKey:@"publishDate"];
}

@end
