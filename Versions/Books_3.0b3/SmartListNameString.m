//
//  SmartListNameString.m
//  Books
//
//  Created by Chris Karr on 1/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SmartListNameString.h"


@implementation SmartListNameString

- (NSComparisonResult) compare: (NSString *) string
{
	if ([string isMemberOfClass:[ListNameString class]])
		return NSOrderedDescending;

	return [[@"" stringByAppendingString:self] caseInsensitiveCompare:string];
}

@end
