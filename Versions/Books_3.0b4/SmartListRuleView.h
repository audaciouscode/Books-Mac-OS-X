//
//  SmartListRuleView.h
//  Books
//
//  Created by Chris Karr on 10/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SmartListRuleView : NSView 
{
	IBOutlet NSPopUpButton * field;
	IBOutlet NSPopUpButton * operation;
	IBOutlet NSTextField * value;
}

- (NSPredicate *) getPredicate;
- (void) setPredicate: (NSPredicate *) predicate;

@end
