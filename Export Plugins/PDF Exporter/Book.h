//
//  Book.h
//  PDF Exporter
//
//  Created by Chris Karr on 2/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Book : NSObject 
{
	NSMutableDictionary * values;
}


- (void) setValue:(NSObject *) value forKey:(NSString *) key;
- (NSObject *) valueForKey:(NSString *) key;
- (NSArray *) allKeys;

@end
