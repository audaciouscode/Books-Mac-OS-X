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
