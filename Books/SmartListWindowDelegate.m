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

#import "SmartListWindowDelegate.h"
#import "SmartListRuleView.h"

@implementation SmartListWindowDelegate

- (NSPredicate *) getPredicate
{
	NSArray * ruleViews = [[rulesBox contentView] subviews];

	NSMutableArray * predicates = [NSMutableArray array];

	int i = 0;
	for (i = 0; i < [ruleViews count]; i++)
	{
		SmartListRuleView * view = (SmartListRuleView *) [ruleViews objectAtIndex:i];
		
		NSComparisonPredicate * p = (NSComparisonPredicate *) [view getPredicate];
		
		if (p != nil)
			[predicates addObject:p];
	}

	if ([predicates count] == 0)
		return nil;
		
	NSString * joinerValue = [joiner titleOfSelectedItem];

	if ([joinerValue isEqualToString:NSLocalizedString (@"Any", nil)])
		return [[NSCompoundPredicate orPredicateWithSubpredicates:predicates] retain];
	else
		return [[NSCompoundPredicate andPredicateWithSubpredicates:predicates] retain];
}

- (void) resetViews
{
	NSArray * ruleViews = [[rulesBox contentView] subviews];

	int i = 0;
	for (i = 0; i < [ruleViews count]; i++)
	{
		SmartListRuleView * view = (SmartListRuleView *) [ruleViews objectAtIndex:i];
		[view setPredicate:nil];
	}
}

- (void) setPredicate: (NSPredicate *) predicate
{
	NSCompoundPredicate * compPredicate = nil;
	
	if (![predicate isKindOfClass:[NSCompoundPredicate class]] && predicate != nil)
		compPredicate = (NSCompoundPredicate *) [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObject:predicate]];
	else
		compPredicate = (NSCompoundPredicate *) predicate;

	[self resetViews];
	
	if (predicate == nil)
		return;

	NSArray * ruleViews = [[rulesBox contentView] subviews];
	NSArray * subs = [compPredicate subpredicates];

	if ([subs count] == 1)
	{
		SmartListRuleView * view = (SmartListRuleView *) [ruleViews objectAtIndex:0];

		[view setPredicate:compPredicate];
	}
	else
	{
		int i = 0;
		for (i = 0; i < [subs count]; i++)
		{
			SmartListRuleView * view = (SmartListRuleView *) [ruleViews objectAtIndex:i];
			NSComparisonPredicate * p = [subs objectAtIndex:i];

			[view setPredicate:p];
		}
	}
	
	if ([compPredicate compoundPredicateType] == NSAndPredicateType)
		[joiner selectItemWithTitle:NSLocalizedString (@"All", nil)];
	else
		[joiner selectItemWithTitle:NSLocalizedString (@"Any", nil)];
}

@end
