//
//  GalleryCoverView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryCoverView.h"
#import "GalleryView.h"
#import "BooksAppDelegate.h"
#import "SmartListManagedObject.h"
#import "GalleryTextView.h"

@implementation GalleryCoverView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];

    if (self) 
	{
		margin = 6;

		imageView = [[NSImageView alloc] init];
		[imageView setImageScaling:NSScaleToFit];
		[imageView setImageFrameStyle:NSImageFramePhoto];
 		[self addSubview:imageView];
		[imageView setHidden:NO];

		titleView = [[GalleryTextView alloc] init];

		[titleView setDrawsBackground:NO];
		[titleView setEditable:NO];
		[titleView setHidden:YES];
			
		[self addSubview:titleView positioned:NSWindowAbove relativeTo:imageView];
		
		cachedData = nil;
		currentBook = nil;
		
		timer = nil;
		click = false;
		
		prefs = [NSUserDefaults standardUserDefaults];
		[prefs addObserver:self forKeyPath:@"Gallery Show Title" options:NSKeyValueObservingOptionNew context:NULL];
	}
  
	return self;
}

- (void) dealloc
{
	[imageView release];
	[titleView release];
	
	[super dealloc];
}

- (NSRect) getBorder:(float) borderWidth
{
	NSSize borderSize = [imageView frame].size;
	
	NSSize viewSize = [self frame].size;

	borderSize.width += borderWidth;
	borderSize.height += borderWidth;
	
	float x = (viewSize.width - borderSize.width) / 2;
	float y = (viewSize.height - borderSize.height) / 2;

	NSRect rect = NSMakeRect (x, y, borderSize.width, borderSize.height); 

	return rect;
}

- (void) setImageViewFrame
{
	NSSize frameSize = [self frame].size;
	
	NSImage * img = [imageView image];
	NSSize imageSize = [img size];
	NSSize viewSize = [self frame].size;
	
	viewSize.width -= margin * 2;
	viewSize.height -= margin * 2;
	
	if (imageSize.width > viewSize.width || imageSize.height > viewSize.height)
	{
		float ratio = imageSize.height / imageSize.width;
		
		if (ratio < 1)
		{
			ratio = viewSize.width / imageSize.width;
			viewSize.width = viewSize.width;
			viewSize.height = imageSize.height * ratio;
		}
		else
		{
			ratio = viewSize.height / imageSize.height;
			viewSize.width = imageSize.width * ratio;
			viewSize.height = viewSize.height;
		}
	}
	else
	{
		viewSize = imageSize;
	}
	
	viewSize.width = (float) ((int) viewSize.width) + 2;
	viewSize.height = (float) ((int) viewSize.height) + 2;

	float x = (frameSize.width - viewSize.width) / 2;
	float y = (frameSize.height - viewSize.height) / 2;

	[imageView setFrame:NSMakeRect (x, y, viewSize.width, viewSize.height)];

	[titleView setMaxSize:viewSize];
	
	if (![titleView isHidden])
	{
		NSRect frame = [titleView frame];
		frame.origin.x = x;
		frame.origin.y = y;
		frame.size.width = viewSize.width;

		[titleView setFrame:frame];
		[titleView setAlignment:NSCenterTextAlignment];
		[titleView setNeedsDisplay:YES];
	}
}

- (void) drawSelectedBackground
{
	NSRect rect = [self getBorder:margin];
	
	float radius = 0.0;

	[[NSColor alternateSelectedControlColor] setStroke];

	NSBezierPath * path = [NSBezierPath bezierPath];
	[path setLineWidth:(margin / 2) - 1];
	
	rect = NSInsetRect(rect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	
	[path stroke];
}

- (void)drawRect:(NSRect)rect
{
	[self setImageViewFrame];

	GalleryView * gv = (GalleryView *) [self superview];
	
	if ([gv isSelected:currentBook])
		[self drawSelectedBackground];
}

- (void) updateImage
{
	if (currentBook != nil)
	{
		[titleView setString:[currentBook valueForKey:@"title"]];
		[titleView setHidden:![prefs boolForKey:@"Gallery Show Title"]];

		NSData * data = [currentBook valueForKey:@"coverImage"];

		NSImage * image = [[NSImage alloc] initWithData:data];
		
		NSSize size = [image size];
		
		BOOL bigEnough = size.width > 64 && size.height > 64;
		
		// if ((cachedData == nil || ![cachedData isEqualToData:data]) && data != nil && bigEnough)
		if (data != nil && bigEnough)
		{
			[imageView setImage:image];
			[imageView setImageFrameStyle:NSImageFramePhoto];
			
			if (cachedData != nil)
				[cachedData release];
				
			cachedData = [[NSData alloc] initWithData:data];
			
		}
		else
		{
			[imageView setImage:[NSImage imageNamed:@"no-cover"]];
			[imageView setImageFrameStyle:NSImageFrameNone];
			
			[titleView setHidden:NO];
		}
		
		[image release];
		
		NSString * title = [currentBook valueForKey:@"title"];
		
		if (title == nil)
			title = @"";
			
		NSMutableString * string = [NSMutableString stringWithString:title];
		NSString * authors = [currentBook valueForKey:@"authors"];
		
		if (authors != nil && ![authors isEqual:@""])
		{
			[string appendString:@"\n("];
			[string appendString:authors];
			[string appendString:@")"];
		}
		
		[imageView setToolTip:string];
	}
	else
	{
		[imageView setImage:nil];
		[titleView setHidden:YES];
	}
	
	[self setImageViewFrame];
}

- (void) setBook:(BookManagedObject *) book
{
	if (currentBook == book)
		return;

	if (cachedData != nil)
		[cachedData release];

	cachedData = nil;

	[currentBook removeObserver:self forKeyPath:@"coverImage"];
	[currentBook removeObserver:self forKeyPath:@"title"];
	
	currentBook = [book retain];
	
	if (currentBook != nil)
	{
		[currentBook addObserver:self forKeyPath:@"coverImage" options:0 context:NULL];
		[currentBook addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
	}

	[self updateImage];
	[self setNeedsDisplay:YES];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
    if ([keyPath isEqual:@"coverImage"])
	{
		if (currentBook != nil)
			[self updateImage];
	}
	else if ([keyPath isEqual:@"Gallery Show Title"])
	{
		if (![[imageView image] isEqual:[NSImage imageNamed:@"no-cover"]])
		{
			[titleView setHidden:![prefs boolForKey:@"Gallery Show Title"]];
			[titleView setNeedsDisplay:YES];
		}
	}
	else if ([keyPath isEqual:@"title"])
	{
		NSString * title = [currentBook valueForKey:@"title"];
		
		if (title == nil)
			title = @"";

		NSMutableString * string = [NSMutableString stringWithString:title];
		
		if ([currentBook valueForKey:@"authors"] != nil)
		{
			[string appendString:@"\n"];
			[string appendString:[currentBook valueForKey:@"authors"]];
		}
		
		[imageView setToolTip:string];
		[titleView setString:[currentBook valueForKey:@"title"]];
		
		[self setNeedsDisplay:YES];
		[titleView setNeedsDisplay:YES];
	}
}


- (NSView *) hitTest:(NSPoint)aPoint
{
	NSPoint p = [[self superview] convertPoint:aPoint toView:self];
	
	NSSize myFrame = [self frame].size;
	
	if (p.x >= 0 && myFrame.width >= p.x && p.y >= 0 && myFrame.height >= p.y)
		return self;
	
	return [super hitTest:aPoint];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void) resetClick:(NSTimer*) theTimer
{
	click = false;

	[timer invalidate];
	[timer release];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	if (currentBook != nil)
	{
		NSPasteboard * pboard = [NSPasteboard generalPasteboard];
	
		NSString * type = @"Books Book Type";
		NSArray * types = [NSArray arrayWithObjects:type, nil];
	
		[pboard declareTypes:types owner:self];

		NSMutableArray * urls = [NSMutableArray array];    
	
		NSURL * url = [[currentBook objectID] URIRepresentation];
		[urls addObject:[url description]];

		[pboard setData:[NSArchiver archivedDataWithRootObject:urls] forType:type];

		NSImage * dragImage = [[NSImage alloc] initWithData:[[imageView image] TIFFRepresentation]];

		NSSize size = [dragImage size];
	
		float ratio = size.width / size.height;
	
		if (ratio > 1)
		{
			size.height = 96 / ratio;
			size.width = 96;
		}
		else
		{
			size.width = 96 * ratio;
			size.height = 96;
		}
		
		[dragImage setScalesWhenResized:YES];
		[dragImage setSize:size];

		[self dragImage:dragImage at:NSMakePoint(size.width / 2, size.height / 2) offset:NSMakeSize(0.0, 0.0) event:theEvent 
			pasteboard:pboard source:self slideBack:YES];

		[dragImage release];
	}
	
	[super mouseDragged:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	GalleryView * gv = (GalleryView *) [self superview];
	
	[gv setSelectedView:self];

	if (click)
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];

		[self resetClick:timer];
		click = false;
	}
	else
	{
		timer = [[NSTimer scheduledTimerWithTimeInterval:(GetDblTime() / 60.0) target:self 
					selector:NSSelectorFromString(@"resetClick:") userInfo:nil repeats:NO] retain];
		
		click = true;
	}
	
	[super mouseUp:theEvent];
}


- (NSMenu *) menuForEvent:(NSEvent *)theEvent
{
	GalleryView * gv = (GalleryView *) [self superview];
	
	[gv setSelectedView:self];

	ListManagedObject * obj = [[[((GalleryView *) [self superview] ) listController] selectedObjects] objectAtIndex:0];

	NSMenu * menu = [[NSMenu alloc] init];

	if ([obj isKindOfClass:[SmartListManagedObject class]])
		[menu addItemWithTitle:NSLocalizedString (@"No operations available", nil) action:nil keyEquivalent:@""];
	else
	{
		[menu addItemWithTitle:NSLocalizedString (@"Duplicate", nil) action:NSSelectorFromString(@"duplicateRecords:") keyEquivalent:@""];
		[menu addItemWithTitle:NSLocalizedString (@"Delete", nil) action:NSSelectorFromString(@"removeBook:") keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];

		[menu addItemWithTitle:NSLocalizedString (@"New Book", nil) action:NSSelectorFromString(@"newBook:") keyEquivalent:@""];
	}

	return [menu autorelease];
}

@end
