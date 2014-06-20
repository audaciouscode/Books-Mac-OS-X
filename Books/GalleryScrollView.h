//
//  GalleryScrollView.h
//  Books
//
//  Created by Chris Karr on 8/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GalleryScrollView : NSScrollView
{
	BOOL shouldDrawFocusRing;
	NSResponder *lastResp;
}

@end
