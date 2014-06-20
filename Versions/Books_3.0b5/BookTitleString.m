//
//  BookTitleString.m
//  Books
//
//  Created by Chris Karr on 1/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "BookTitleString.h"

@implementation BookTitleString

- (unsigned int) length
{
	return [store length];
}

- (unichar)characterAtIndex:(unsigned)index
{
	return [store characterAtIndex:index];
}

- (id) initWithCharactersNoCopy: (unichar *) characters length: (unsigned) length freeWhenDone: (BOOL) flag
{
	store = [[NSString alloc] initWithCharactersNoCopy:characters length:length freeWhenDone:flag];
	
	if (sortString != nil)
	{
		[sortString release];
		
		sortString = nil;
	}
	
	return self;
}

- (NSString *) getSortString
{
	if (sortString != nil)
		return sortString;

	NSArray * ignoreWords = [NSArray arrayWithObjects:@"the ", @"an ", @"a ", nil];
	
	int i = 0; 
	for (i = 0; i < [ignoreWords count]; i++)
	{
		NSString * ignore = (NSString *) [ignoreWords objectAtIndex:i];

		if ([self length] > [ignore length])
		{
			NSRange range = [self rangeOfString:ignore options:NSCaseInsensitiveSearch range:NSMakeRange (0, [ignore length])];

			if (range.location == 0)
			{
				sortString = [[self substringFromIndex:[ignore length]] retain];
				
				return sortString;
			}
		}
	}
	
	sortString = [self description];
	
	return sortString;
}

- (NSComparisonResult) compare: (BookTitleString *) string
{
	return [[self getSortString] caseInsensitiveCompare:[string getSortString]];
}

@end