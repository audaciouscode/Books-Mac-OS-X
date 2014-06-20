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
#import "BooksAppDelegate.h"

@implementation BookAuthorString

/* - (NSComparisonResult) localizedCaseInsensitiveCompare: (BookAuthorString *) string
{
	
	
	if (!sortAuthors)
		return [[NSString stringWithString:self] localizedCaseInsensitiveCompare:string];
	else
		return [[self getSortString] localizedCaseInsensitiveCompare:[string getSortString]];
}

- (NSComparisonResult) caseInsensitiveCompare: (BookAuthorString *) string
{
	return [self localizedCaseInsensitiveCompare:string];
}

- (NSComparisonResult) compare: (BookAuthorString *) string
{
	BOOL sortAuthors = [[NSUserDefaults standardUserDefaults] boolForKey:@"Sort People Names"];
	
	if (!sortAuthors && [((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		return [self localizedCaseInsensitiveCompare:string];
	else
		return [[self getSortString] caseInsensitiveCompare:[string getSortString]];
} */

- (NSString *) getSortString
{
	if (sortString != nil)
		return sortString;

	BOOL sortAuthors = [[NSUserDefaults standardUserDefaults] boolForKey:@"Sort People Names"];

	if (sortAuthors)
	{
		NSArray * separators = [NSArray arrayWithObjects:@";", @",", @"/", nil];
	
		sortString = [[NSMutableString alloc] initWithString:self];

		NSRange range;

		int i = 0;
		for (i = 0; i < [separators count]; i++)
		{
			range = [sortString rangeOfString:[separators objectAtIndex:i]];
		
			if (range.location != NSNotFound)
				[sortString setString:[self substringToIndex:range.location]];
		}

		range = [sortString rangeOfString:@" " options:NSBackwardsSearch];
	
		if (range.location != NSNotFound)
		{
			NSString * lastName = [sortString substringFromIndex:range.location + 1];
			[sortString deleteCharactersInRange:NSMakeRange (range.location, [lastName length])];
			[sortString insertString:@" " atIndex:0];
			[sortString insertString:lastName atIndex:0];
		}
	}
	else
		sortString = [self description];

	return sortString;
}

@end
