//
//  NoDPIImageView.m
//  Books
//
//  Created by Chris Karr on 10/3/08.
//  Copyright 2008 Northwestern University. All rights reserved.
//

#import "NoDPIImageView.h"


@implementation NoDPIImageView

- (void)setObjectValue:(id < NSCopying >)object
{
	NSImage * image = (NSImage *) object;
	
	if (image != nil)
	{
		NSImageRep * rep = [image bestRepresentationForDevice:nil];
	
		[image setSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
	}
	
	[super setObjectValue:image];
}

@end

