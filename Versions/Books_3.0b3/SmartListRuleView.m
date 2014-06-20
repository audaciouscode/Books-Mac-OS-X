//
//  SmartListRuleView.m
//  Books
//
//  Created by Chris Karr on 10/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

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
	NSString * fieldName = [[field titleOfSelectedItem] lowercaseString];
	NSString * fieldValue = [value stringValue];
	
	if ([fieldName isEqualToString:NSLocalizedString (@"title", nil)])
		fieldName = @"title";
	else if ([fieldName isEqualToString:NSLocalizedString (@"series", nil)])
		fieldName = @"series";
	else if ([fieldName isEqualToString:NSLocalizedString (@"summary", nil)])
		fieldName = @"summary";
	else if ([fieldName isEqualToString:NSLocalizedString (@"genre", nil)])
		fieldName = @"genre";
	else if ([fieldName isEqualToString:NSLocalizedString (@"keywords", nil)])
		fieldName = @"keywords";
	else if ([fieldName isEqualToString:NSLocalizedString (@"publisher", nil)])
		fieldName = @"publisher";
	else if ([fieldName isEqualToString:NSLocalizedString (@"length", nil)])
		fieldName = @"length";
	else if ([fieldName isEqualToString:NSLocalizedString (@"edition", nil)])
		fieldName = @"edition";
	else if ([fieldName isEqualToString:NSLocalizedString (@"date published", nil)])
		fieldName = @"publishDate";
	else if ([fieldName isEqualToString:NSLocalizedString (@"author(s)", nil)])
		fieldName = @"authors";
	else if ([fieldName isEqualToString:NSLocalizedString (@"editor(s)", nil)])
		fieldName = @"editors";
	else if ([fieldName isEqualToString:NSLocalizedString (@"illustrator(s)", nil)])
		fieldName = @"illustrators";
	else if ([fieldName isEqualToString:NSLocalizedString (@"translator(s)", nil)])
		fieldName = @"translators";
	else if ([fieldName isEqualToString:NSLocalizedString (@"list name", nil)])
		fieldName = @"listName";
	
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

	if (![fieldName isEqualToString:@"publishDate"])
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
		[field selectItemWithTitle:@"Title"];
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
	}

	NSArray * map = [NSArray arrayWithObjects:@"title", @"series", @"authors", @"summary", @"genre", 
					@"isbn", @"publishDate", @"keywords", @"publisher", @"translators", @"illustrators",
					@"editors", @"publishPlace", @"length", @"edition", @"format", @"listName", nil];

	[field selectItemAtIndex:[map indexOfObject:fieldName]];
	[value setStringValue:fieldValue];
}

@end
