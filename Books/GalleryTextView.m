//
//  GalleryTextView.m
//  Books
//
//  Created by Chris Karr on 8/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryTextView.h"


@implementation GalleryTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) drawTitleBackground
{
	NSRect rect = [self frame];
	
	rect.origin.x = 0.0;
	rect.origin.y = 0.0;
	
	float radius = 7;

	[[NSColor colorWithDeviceRed:0.25 green:0.25 blue:0.25 alpha:0.75] setFill];

	NSBezierPath * path = [NSBezierPath bezierPath];
	// [path setLineWidth:(margin / 2) - 1];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path fill];
}

- (void)drawRect:(NSRect)rect 
{
	[self setTextColor:[NSColor whiteColor]];
	[self drawTitleBackground];
	
	[super drawRect:rect];
}

@end
