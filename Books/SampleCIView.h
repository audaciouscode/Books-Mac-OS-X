
/* SampleCIView.h - simple OpenGL based CoreImage view */

// This code was stolen from /Developer/Examples/Quartz/Core Image/FunHouse/SampleCIView.m
// and modified to scale the CIImage within the frame rect (preserving aspect ratio,
// and painting unused areas black)

#import <Cocoa/Cocoa.h>

#import <QuartzCore/CoreImage.h>

@interface SampleCIView: NSOpenGLView
{
    CIContext *_context;
    CIImage   *_image;
    NSRect     _lastBounds;
	//CGRect     _cleanRect;
	CGSize     _displaySize;
	
	//CIImage *greenLines, *redLines;
	
	BOOL mirrored, goodScan;
	BOOL newHighResiSight;
	CGRect highResPortionOfImage;
	
	NSRecursiveLock         *lock;
	CIFilter *mirroredFilter, *redLinesFilter, *greenLinesFilter;
}

- (void)setImage:(CIImage *)image;
//- (void)setImage:(CIImage *)image dirtyRect:(CGRect)r;
//- (void)setCleanRect:(CGRect)cleanRect;
- (void)setDisplaySize:(CGSize)displaySize;

- (CIImage *)image;

// Called when the view bounds have changed
- (void)viewBoundsDidChange:(NSRect)bounds;

- (void)setGoodScan:(BOOL)aBool;
- (void)setMirrored:(BOOL)aBool;
- (void)setHighResiSight:(BOOL)aBool;

@end