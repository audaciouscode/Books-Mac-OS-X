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