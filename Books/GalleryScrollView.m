//
//  GalleryScrollView.m
//  Books
//
//  Created by Chris Karr on 8/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryScrollView.h"

@implementation GalleryScrollView

- (BOOL)needsDisplay;
{
    NSResponder *resp = nil;
    if ([[self window] isKeyWindow])
    {
        resp = [[self window] firstResponder];
        if (resp == lastResp) return [super needsDisplay];
    }
    else if (lastResp == nil)
    {
        return [super needsDisplay];
    }
   
	shouldDrawFocusRing = (resp != nil && [resp isKindOfClass: [NSView class]] && [
		(NSView *)resp isDescendantOf: self]);
		
    lastResp = resp;
    [self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return YES;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect: rect];

    if (shouldDrawFocusRing)
    {
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill(rect);
    }
}

- (void) dealloc
{
	[super dealloc];
}


@end
