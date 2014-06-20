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


#import "SmartListRuleView.h"

@implementation SmartListRuleView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];

    if (self) 
	{

    }
	
    return self;
}

- (void)drawRect:(NSRect)rect 
{

}

- (NSPredicate *) getPredicate
{
	NSString * operationValue = [operation titleOfSelectedItem];
	NSString * fieldName = [field titleOfSelectedItem]; /// [[field titleOfSelectedItem] lowercaseString];
	NSString * fieldValue = [value stringValue];
	
	if ([fieldName isEqualToString:NSLocalizedString (@"Title", nil)])
		fieldName = @"title";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Series", nil)])
		fieldName = @"series";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Summary", nil)])
		fieldName = @"summary";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Genre", nil)])
		fieldName = @"genre";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Keywords", nil)])
		fieldName = @"keywords";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Publisher", nil)])
		fieldName = @"publisher";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Length", nil)])
		fieldName = @"length";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Format", nil)])
		fieldName = @"format";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Edition", nil)])
		fieldName = @"edition";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Date Published", nil)])
		fieldName = @"publishDate";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Author(s)", nil)])
		fieldName = @"authors";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Editor(s)", nil)])
		fieldName = @"editors";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Illustrator(s)", nil)])
		fieldName = @"illustrators";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Translator(s)", nil)])
		fieldName = @"translators";
	else if ([fieldName isEqualToString:NSLocalizedString (@"List Name", nil)])
		fieldName = @"list.name";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Place Published", nil)])
		fieldName = @"publishPlace";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Date Lent", nil)])
		fieldName = @"dateLent";
	else if ([fieldName isEqualToString:NSLocalizedString (@"Returned On", nil)])
		fieldName = @"dateDue";
	else if ([fieldName isEqualToString:NSLocalizedString (@"ISBN", nil)])
		fieldName = @"isbn";

	if ([fieldValue isEqualToString:@""])
		return nil;

	if ([fieldValue isEqualToString:NSLocalizedString (@"<empty>", nil)])
		fieldValue = nil;

	NSPredicateOperatorType type = NSInPredicateOperatorType;

	if ([operationValue isEqualToString:NSLocalizedString (@"contains", nil)])
		type = NSInPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"does not contain", nil)])
		type = NSCustomSelectorPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"less than", nil)])
		type = NSLessThanPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"greater than", nil)])
		type = NSGreaterThanPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"is", nil)])
		type = NSEqualToPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"is not", nil)])
		type = NSNotEqualToPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"matches regexp", nil)])
		type = NSMatchesPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"starts with", nil)])
		type = NSBeginsWithPredicateOperatorType;
	else if ([operationValue isEqualToString:NSLocalizedString (@"ends with", nil)])
		type = NSEndsWithPredicateOperatorType;

	if (!([fieldName isEqualToString:@"publishDate"] || [fieldName isEqualToString:@"dateDue"] || 
		[fieldName isEqualToString:@"dateLent"]))
	{
		NSExpression * right = [NSExpression expressionForConstantValue:fieldValue];
		NSExpression * left = [NSExpression expressionForKeyPath:fieldName];

		if (type == NSInPredicateOperatorType)
		{
			return [NSComparisonPredicate predicateWithLeftExpression:right rightExpression:left
						modifier:NSDirectPredicateModifier type:type 
						options: (NSCaseInsensitivePredicateOption || NSDiacriticInsensitivePredicateOption)];
		}
		else if (type == NSCustomSelectorPredicateOperatorType)
		{
			NSPredicate * inPredicate = [NSComparisonPredicate predicateWithLeftExpression:right rightExpression:left
						modifier:NSDirectPredicateModifier type:NSInPredicateOperatorType 
						options:NSCaseInsensitivePredicateOption];

			return [NSCompoundPredicate notPredicateWithSubpredicate:inPredicate];
		}
		else
		{
			return [NSComparisonPredicate predicateWithLeftExpression:left rightExpression:right
						modifier:NSDirectPredicateModifier type:type 
						options: (NSCaseInsensitivePredicateOption || NSDiacriticInsensitivePredicateOption)];
		}
	}
	else
	{
		fieldValue = [fieldValue stringByAppendingString:@" 00:00"];

		NSDate * date = [NSDate dateWithNaturalLanguageString:fieldValue];
		
		return [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:fieldName]
								rightExpression:[NSExpression expressionForConstantValue:date] 
								modifier:NSDirectPredicateModifier type:type 
								options: (NSCaseInsensitivePredicateOption || NSDiacriticInsensitivePredicateOption)];
	}
}

- (void) setPredicate: (NSPredicate *) predicate
{
	if (predicate == nil)
	{
		[field selectItemWithTitle:NSLocalizedString (@"Title", nil)];
		[operation selectItemWithTitle:NSLocalizedString (@"contains", nil)];
		[value setStringValue:@""];
		
		return;
	}

	NSString * fieldName = nil;
	NSObject * fieldObject = nil;

	if ([predicate isKindOfClass:[NSComparisonPredicate class]])
	{
		NSComparisonPredicate * compPredicate = (NSComparisonPredicate *) predicate;

		if ([[compPredicate rightExpression] expressionType] == NSConstantValueExpressionType)
		{
			fieldObject = [[compPredicate rightExpression] constantValue];
			fieldName = [[compPredicate leftExpression] keyPath];
		}
		else
		{
			fieldObject = [[compPredicate leftExpression] constantValue];
			fieldName = [[compPredicate rightExpression] keyPath];
		}

		NSPredicateOperatorType type = [compPredicate predicateOperatorType];

		if (type == NSInPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"contains", nil)];
		else if (type == NSLessThanPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"less than", nil)];
		else if (type == NSGreaterThanPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"greater than", nil)];
		else if (type == NSEqualToPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"is", nil)];
		else if (type == NSNotEqualToPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"is not", nil)];
		else if (type == NSMatchesPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"matches regexp", nil)];
		else if (type == NSBeginsWithPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"starts with", nil)];
		else if (type == NSEndsWithPredicateOperatorType)
			[operation selectItemWithTitle:NSLocalizedString (@"ends with", nil)];
	}
	else if ([predicate isKindOfClass:[NSCompoundPredicate class]])
	{
		NSCompoundPredicate * compoundPredicate = (NSCompoundPredicate *) predicate;
		NSComparisonPredicate * compPredicate = [[(NSCompoundPredicate *) predicate subpredicates] objectAtIndex:0];

		[self setPredicate:compPredicate];
		
		if ([compoundPredicate compoundPredicateType] == NSNotPredicateType)
			[operation selectItemWithTitle:NSLocalizedString (@"does not contain", nil)];
		
		return;
	}

	if (fieldObject == nil)
		fieldObject = @"<empty>";
		
	NSString * fieldValue = [fieldObject description];

	if ([fieldObject isKindOfClass:[NSDate class]])
	{
		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		[formatter setDateStyle:NSDateFormatterLongStyle];

		fieldValue = [formatter stringFromDate:((NSDate *) fieldObject)];
		[formatter release];
	}

	NSArray * map = [NSArray arrayWithObjects:@"title", @"series", @"authors", @"summary", @"genre", 
					@"isbn", @"publishDate", @"keywords", @"publisher", @"translators", @"illustrators",
					@"editors", @"publishPlace", @"length", @"edition", @"format", @"list.name", @"dateLent", @"dateDue", nil];

	[field selectItemAtIndex:[map indexOfObject:fieldName]];
	[value setStringValue:fieldValue];
}

@end
