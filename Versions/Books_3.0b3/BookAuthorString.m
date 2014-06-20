//
//  BookAuthorString.m
//  Books
//
//  Created by Chris Karr on 1/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BookAuthorString.h"

@implementation BookAuthorString

- (NSComparisonResult) compare: (BookAuthorString *) string
{
	if (sortAuthors == nil)
	{
		sortAuthors = [[NSUserDefaults standardUserDefaults] stringForKey:@"Sort People Names"];

		if (sortAuthors == nil)
			sortAuthors = @"No";
	}

	if (![sortAuthors isEqual:@"Yes"])
		return [self caseInsensitiveCompare:string];
	else
		return [[self getSortString] caseInsensitiveCompare:[string getSortString]];
}

- (NSString *) getSortString
{
	if (sortString != nil)
		return sortString;
		
	NSArray * separators = [NSArray arrayWithObjects:@";", @",", @"/", nil];
	
	sortString = self;

	NSRange range;

	int i = 0;
	for (i = 0; i < [separators count]; i++)
	{
		range = [sortString rangeOfString:[separators objectAtIndex:i]];
	
		if (range.location != NSNotFound)
			sortString = [sortString substringToIndex:range.location];
	}

	range = [sortString rangeOfString:@" " options:NSBackwardsSearch];
	
	if (range.location != NSNotFound)
		sortString = [sortString substringFromIndex:range.location];

	return sortString;
}

@end
