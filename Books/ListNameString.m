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


#import "ListNameString.h"
#import "SmartListNameString.h"
#import "BooksAppDelegate.h"

@implementation ListNameString

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
	
	return self;
}

- (void) dealloc
{
	[store release];

	[super dealloc];
}

- (NSComparisonResult) compare: (NSString *) string
{
	if ([string isMemberOfClass:[SmartListNameString class]])
		return NSOrderedAscending;
	
	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		return [[@"" stringByAppendingString:self] localizedCaseInsensitiveCompare:string];

	return [[@"" stringByAppendingString:self] caseInsensitiveCompare:string];
}

@end
