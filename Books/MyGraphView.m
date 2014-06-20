//
//  MyGraphView.m

#import "MyGraphView.h"


@implementation MyGraphView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		pathsAndColor = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc {
	[super dealloc];
}


- (void)drawRect:(NSRect)rect {
	
	if ([pathsAndColor count] == 0)
		return;  //Leave the last paths that were drawn
	
    // Drawing code here.
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:rect];
	
	NSEnumerator *allKeysEnum = [[pathsAndColor allKeys] objectEnumerator];
	NSColor *nextColor;
	while (nextColor = [allKeysEnum nextObject]) {
		NSBezierPath *nextPath = [pathsAndColor objectForKey:nextColor];
		if (nextPath) {
			[nextColor set];
			[nextPath stroke];
		}
	}
}

- (void)setGreenPath:(NSBezierPath *)aPath {
	[self setPath:aPath withColor:[NSColor greenColor]];
}

- (void)setRedPath:(NSBezierPath *)aPath {
	[self setPath:aPath withColor:[NSColor redColor]];
}

- (void)setBluePath:(NSBezierPath *)aPath {
	[self setPath:aPath withColor:[NSColor blueColor]];
}

- (void)setPath:(NSBezierPath *)aPath withColor:(NSColor *)aColor {
	[pathsAndColor setObject:aPath forKey:aColor];
	[self setNeedsDisplay:YES];
}

-(void)removeAllPaths {
	[pathsAndColor removeAllObjects];
}



@end
