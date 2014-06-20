//
//  Book.m
//  PDF Exporter
//
//  Created by Chris Karr on 2/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "Book.h"


@implementation Book

- (void) setValue:(NSObject *) value forKey:(NSString *) key
{
	if (values == nil)
		values = [[NSMutableDictionary dictionary] retain];
		
	[values setValue:value forKey:key];
}

- (NSObject *) valueForKey:(NSString *) key
{
	if (values != nil)
		return [values objectForKey:key];
		
	return nil;
}

- (NSArray *) allKeys
{
	if (values == nil)
		values = [[NSMutableDictionary dictionary] retain];

	return [values allKeys];
}	

@end
