//
//  GalleryCoverView.h
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookManagedObject.h";

@interface GalleryCoverView : NSView 
{
	NSImageView * imageView;
	BookManagedObject * currentBook;
	
	NSTextView * titleView;
	float margin;
	NSData * cachedData;
	NSTimer * timer;
	BOOL click;
	
	NSUserDefaults * prefs;
}

- (void) setBook:(BookManagedObject *) book;

@end
