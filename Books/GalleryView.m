//
//  GalleryView.m
//  Books
//
//  Created by Chris Karr on 7/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GalleryView.h"
#import "GalleryCoverView.h"
#import "BooksAppDelegate.h"

@implementation GalleryView

- (void) updateGallerySize
{
	NSNumber * prefSize = [[NSUserDefaults standardUserDefaults] valueForKey:@"Gallery Size"];

	gallerySize = 128;
	
	if (prefSize != nil)
		gallerySize = [prefSize floatValue];
}

- (void) keyDown: (NSEvent *) event
{
	unichar arrow = [[event characters] characterAtIndex:0];
	
	if (arrow == ' ')
		arrow = NSDownArrowFunctionKey;
		
	if (arrow == 13 || arrow == 3)
	{
		NSNotification * notification = [NSNotification notificationWithName:BOOKS_SHOW_INFO object:nil];
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
	else if (arrow == NSBackspaceCharacter || arrow == NSDeleteCharacter)
	{
		[[NSApp delegate] removeBook:nil];
	}
	else if (arrow == NSRightArrowFunctionKey || arrow == NSLeftArrowFunctionKey || arrow == NSUpArrowFunctionKey ||
			 arrow == NSDownArrowFunctionKey || arrow == NSHomeFunctionKey || arrow == NSEndFunctionKey ||
			 arrow == NSPageUpFunctionKey || arrow == NSPageDownFunctionKey)
	{
		if ([[bookList selectedObjects] count] == 0)
			[bookList selectNext:self];
		else
		{
			int maxIndex = [arrangedBooks count] - 1;
			
			int position = [bookList selectionIndex];
		
			if (arrow == NSRightArrowFunctionKey)
				position++;
			else if (arrow == NSLeftArrowFunctionKey)
				position--;
			else if (arrow == NSUpArrowFunctionKey)
			{
				if (position - rowCount >= 0)
					position -= rowCount;
			}
			else if (arrow == NSDownArrowFunctionKey)
			{
				if (position + rowCount <= maxIndex)
					position += rowCount;
			}
			else if (arrow == NSHomeFunctionKey)
				position = 0;
			else if (arrow == NSEndFunctionKey)
				position = maxIndex;
			else if (arrow == NSPageUpFunctionKey || arrow == NSPageDownFunctionKey)
			{
				NSRect clipRect = [self visibleRect];

				if (arrow == NSPageUpFunctionKey)
					position -= rowCount * ((int) (clipRect.size.height / gallerySize));
				else
					position += rowCount * ((int) (clipRect.size.height / gallerySize));
			}
			
			if (position < 0)
				position = 0;
			if (position > maxIndex)
				position = maxIndex;
				
			[bookList setSelectionIndex:position];
		}
	}
	else
		[super keyDown:event];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
	{
		arrangedBooks = [[NSArray alloc] init];
		gallerySize = 128;
		inited = NO;
    }
    return self;
}

- (void) dealloc
{
	[arrangedBooks release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[bookList addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[bookList addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Gallery Size" options:NSKeyValueObservingOptionNew context:NULL];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"Show Gallery" options:NSKeyValueObservingOptionNew context:NULL];
	
	[self updateGallerySize];
	[self setNeedsDisplay:YES];
}

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
	context:(void *)context
{
	NSArray * subs = [self subviews];

    if ([keyPath isEqual:@"arrangedObjects"])
	{
		if (!([arrangedBooks isEqualToArray:[bookList arrangedObjects]]))
		{
			int i = 0;
		
			if (arrangedBooks != nil)
				[arrangedBooks release];
				
			arrangedBooks = [[[bookList arrangedObjects] copy] retain];

			int listSize = [arrangedBooks count];
			
			subs = [self subviews];
			
			if ([subs count] < listSize)
			{
				for (i = [subs count]; i < listSize; i++)
				{
					GalleryCoverView * gcv = [[GalleryCoverView alloc] init];
					[self addSubview:gcv];
					[gcv setHidden:YES];
					[gcv release];
				}
			}
			
			if (listSize > 0 && [[bookList selectedObjects] count] == 0)
				[self setSelectedView:[[self subviews] objectAtIndex:0]];
		}
	}
	else if ([keyPath isEqual:@"selectedObjects"])
	{
		int select = [bookList selectionIndex];
		
		if (select != NSNotFound && [subs count] > 0)
		{
			NSClipView * clip = (NSClipView *) [self superview];
			NSScrollView * scroll = (NSScrollView *) [clip superview];

			NSView * view = [subs objectAtIndex:select];

			NSRect frame = [view frame];
			NSRect clipRect = [clip documentVisibleRect];

			NSRect newFrame = [clip convertRect:frame fromView:self];

			NSRect intersect = NSIntersectionRect (frame, clipRect);
			
			if (abs(newFrame.size.height - intersect.size.height) > 1)
			{
				BOOL below = NO;
				
				if (intersect.origin.x == 0 && intersect.origin.y == 0 && newFrame.origin.y < clipRect.origin.y)
					below = YES;
				else if (frame.origin.y < intersect.origin.y)
					below = YES;

				if (below)
					[[scroll documentView] scrollPoint:NSMakePoint (0, frame.origin.y)];
				else 
					[[scroll documentView] scrollPoint:NSMakePoint (0, frame.origin.y + frame.size.height - clipRect.size.height)];
			}

			int i = 0;
			for (i = 0; i < [subs count]; i++)
				[[subs objectAtIndex:i] setNeedsDisplay:YES];
		}
	}
	else if ([keyPath isEqual:@"Gallery Size"])
	{
		[self updateGallerySize];
	}
	else if ([keyPath isEqual:@"Show Gallery"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Show Gallery"])
		{
			NSNotification * notification = [NSNotification notificationWithName:BOOKS_SET_CONTROL_VIEW object:controls];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}
		else
		{
			NSNotification * notification = [NSNotification notificationWithName:BOOKS_SET_CONTROL_VIEW object:nil];
			[[NSNotificationCenter defaultCenter] postNotification:notification];
		}
	}

	[self display];
}

- (void)drawRect:(NSRect)rect 
{
	NSRect clipRect = [self visibleRect];
	
	rect = [self frame];
	
	int listSize = [arrangedBooks count];
	
	if (gallerySize > [[[self superview] superview] frame].size.height)
		gallerySize = [[[self superview] superview] frame].size.height * 0.95;
	
	NSArray * subs = [self subviews];

	rowCount = ((int) rect.size.width / (int) gallerySize);
	
	colCount = (listSize / rowCount);
	
	if (listSize % rowCount != 0)
		colCount += 1;

	float xSpacing = (rect.size.width - (rowCount * gallerySize)) / (float) (rowCount + 1);
	float ySpacing = xSpacing; 
	
	float x = xSpacing;

	float y = ((gallerySize + ySpacing) * colCount); 

	if (y + ySpacing < [[self superview] frame].size.height)
		y = [[self superview] frame].size.height - ySpacing;

	[self setFrameSize:NSMakeSize (rect.size.width, y + ySpacing)];
	
	y = y - gallerySize;

	int i = 0;
	for (i = 0; i < [subs count]; i++)
	{
		GalleryCoverView * gcv = [subs objectAtIndex:i];
		
		if (i < [arrangedBooks count])
		{
			if (x + gallerySize > rect.size.width)
			{
				x = xSpacing;
				y = y - gallerySize - ySpacing;
			}

			NSRect gcvFrame = NSMakeRect(x, y, gallerySize, gallerySize);
			[gcv setFrame:gcvFrame];

			if (NSIntersectsRect (gcvFrame, clipRect))
			{
				BookManagedObject * book = [arrangedBooks objectAtIndex:i];
				
				[gcv setBook:book];
				[gcv setHidden:NO];
			}
			else
			{
				[gcv setBook:nil];
				[gcv setHidden:YES];
			}
	
			x = x + gallerySize + xSpacing;
		}
		else
		{
			[gcv setFrame:NSMakeRect (0, 0, gallerySize, gallerySize)];
			[gcv setBook:nil];
			[gcv setHidden:YES];
		}
	}
	
	if (!inited && [subs count] > 0)
	{
		inited = YES;
		
		NSArray * array = [bookList selectedObjects];
		[bookList setSelectedObjects:nil];
		[bookList setSelectedObjects:array];
	}
}

- (void) setSelectedView:(NSView *) v
{
	int i = [[self subviews] indexOfObject:v];
	
	if (i != NSNotFound && i < [[bookList arrangedObjects] count])
		[bookList setSelectionIndex:i];
	else if (![self isHidden])
		[bookList setSelectionIndex:0];
}

- (BOOL) isSelected:(BookManagedObject *) book
{
	return [[bookList selectedObjects] containsObject:book];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[[self window] makeFirstResponder:self];
	[super mouseUp:theEvent];
}

- (BOOL)acceptsFirstResponder 
{
    return YES;
}

- (NSArrayController *) listController
{
	return listList;
}

@end
