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
#import "BooksAppDelegate.h"

@implementation BookTitleString

- (unsigned int) length
{
	return [store length];
}

- (unichar) characterAtIndex:(unsigned)index
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
				sortString = [[NSMutableString alloc] initWithString:[self substringFromIndex:[ignore length]]];
				
				[sortString replaceOccurrencesOfString:@": the " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
				[sortString replaceOccurrencesOfString:@": a " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
				[sortString replaceOccurrencesOfString:@": an " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
				
				return sortString;
			}
		}
	}
	
	sortString = [[NSMutableString alloc] initWithString:[self description]];
	[sortString replaceOccurrencesOfString:@": the " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
	[sortString replaceOccurrencesOfString:@": a " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
	[sortString replaceOccurrencesOfString:@": an " withString:@": " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sortString length])];
	
	return sortString;
}

- (NSComparisonResult) compare: (NSString *) string
{
	if ([string isKindOfClass:[BookTitleString class]])
		string = [((BookTitleString *) string) getSortString];
	
	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		return [[self getSortString] compare:string options:NSNumericSearch|NSCaseInsensitiveSearch 
									   range:NSMakeRange(0, [self length]) locale:[NSLocale currentLocale]];
	else
		return [[self getSortString] compare:string options:NSNumericSearch|NSCaseInsensitiveSearch];
}

- (void) dealloc
{
	[super dealloc];
}

@end