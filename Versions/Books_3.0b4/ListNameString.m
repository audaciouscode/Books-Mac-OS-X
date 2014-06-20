//
//  ListNameString.m
//  Books
//
//  Created by Chris Karr on 1/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ListNameString.h"
#import "SmartListNameString.h"

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

- (NSComparisonResult) compare: (NSString *) string
{
	if ([string isMemberOfClass:[SmartListNameString class]])
		return NSOrderedAscending;
	
	return [[@"" stringByAppendingString:self] caseInsensitiveCompare:string];
}

@end
