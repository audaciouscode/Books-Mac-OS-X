
/* SampleCIView.m - simple OpenGL based CoreImage view */

#import "SampleCIView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

static CGRect centerSizeWithinRect(CGSize size, CGRect rect);

@interface SampleCIView (Private)
- (CIImage *)lineImageWithColor:(NSColor *)aColor;
@end

@implementation SampleCIView

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self != nil) {
		lock = [[NSRecursiveLock alloc] init];
	}
	return self;
}


- (void)dealloc {
	[mirroredFilter release];
	[redLinesFilter release];
	[greenLinesFilter release];
	[lock release];
    [_image release];
    [_context release];	
    [super dealloc];
}


+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    static NSOpenGLPixelFormat *pf;
	
    if (pf == nil)
    {
		/* Making sure the context's pixel format doesn't have a recovery
		 * renderer is important - otherwise CoreImage may not be able to
		 * create deeper context's that share textures with this one. */
		
		static const NSOpenGLPixelFormatAttribute attr[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFAColorSize, 32,
			0
		};
		
		pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];
    }
	
    return pf;
}


- (void)setGoodScan:(BOOL)aBool {
	goodScan = aBool;
}


- (void)setMirrored:(BOOL)aBool {
	mirrored = aBool;
	
	if (mirrored && mirroredFilter == nil) {
		mirroredFilter = [[CIFilter filterWithName:@"CIAffineTransform"] retain];
		NSAffineTransform *rotateTransform = [NSAffineTransform transform];
		[rotateTransform rotateByDegrees:180.0];
		[rotateTransform scaleXBy:1.0 yBy:-1.0];
		[rotateTransform translateXBy:-_displaySize.width yBy:0 ];
		[mirroredFilter setValue:rotateTransform forKey:@"inputTransform"];
	}
	
	//NSLog(@"Mirrored: %d, filter: %@", mirrored, mirroredFilter);
	
}
- (void)setHighResiSight:(BOOL)aBool {
	newHighResiSight = aBool;
	// The value of FIRST_LINE_SCAN_HIGH in MybarcodeScanner has to change as well if the value bellow changes
	//	highResPortionOfImage = CGRectMake(0.0, 0.0, 640.0, 480.0); //Capture bottom left portion
	//	highResPortionOfImage = CGRectMake(320.0, 240.0, 640.0, 4800.0); //To capture middle
	//highResPortionOfImage = CGRectMake(0.0, 544.0, 640.0, 480.0); //Capture top left portion
	highResPortionOfImage = CGRectMake(320.0, 544.0, 640.0, 480.0); //Capture top middle
	
	CIImage *redLines = [self lineImageWithColor:[NSColor redColor]];
	CIImage *greenLines = [self lineImageWithColor:[NSColor greenColor]];
	
	redLinesFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
	[redLinesFilter setValue:redLines forKey:@"inputImage"];
	greenLinesFilter = [[CIFilter filterWithName:@"CISourceOverCompositing"] retain];
	[greenLinesFilter setValue:greenLines forKey:@"inputImage"];
	
	//NSLog(@"HighRes: %d, size: %f %f %f %f", newHighResiSight, highResPortionOfImage.origin.x, highResPortionOfImage.origin.y, highResPortionOfImage.size.width, highResPortionOfImage.size.height);
	
}


#define NUMBER_OF_LINES_SCANNED 14
#define SPACING_BETWEEN_SCAN_LINE 8
//#define FIRST_LINE_SCAN 
//#define FIRST_LINE_SCAN (752 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE))

- (CIImage *)lineImageWithColor:(NSColor *)aColor {
	
	NSPoint middleLine;
	NSImage *linesImage;
	if (newHighResiSight) {
		linesImage = [[NSImage alloc] initWithSize:NSMakeSize(770.0, 1024.0)];
		middleLine.y = (784 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE)); 
		middleLine.x = 520.0;
		//middleLine.y = (240 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE)); 
		
	}
	else {
		linesImage = [[NSImage alloc] initWithSize:NSMakeSize(640.0, 480.0)];
		middleLine.y = (240 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE));
		middleLine.x = 200.0;
	}
	
	[linesImage lockFocus];
	[aColor set];
	NSBezierPath *linesDetails = [NSBezierPath bezierPath];
	//[linesDetails setLineWidth:1];
	int i;
	for (i = 0; i < NUMBER_OF_LINES_SCANNED; i++) {
		i * SPACING_BETWEEN_SCAN_LINE;
		[linesDetails moveToPoint:NSMakePoint(middleLine.x, middleLine.y + (i * SPACING_BETWEEN_SCAN_LINE) +1)];
		[linesDetails lineToPoint:NSMakePoint(middleLine.x + 250.0, middleLine.y + (i * SPACING_BETWEEN_SCAN_LINE) +1)];
	}
	[linesDetails stroke];			
	[linesImage unlockFocus];
	CIImage *tempImage = [CIImage imageWithData:[linesImage TIFFRepresentation]];
	[linesImage release];
	return tempImage;
}


- (CIImage *)image
{
    return [[_image retain] autorelease];
}

/*
 - (void)setImage:(CIImage *)image dirtyRect:(CGRect)r
 {
 if (_image != image)
 {
 //[lock lock];    
 
 [_image release];
 _image = [image retain];
 
 if (CGRectIsInfinite (r))
 [self setNeedsDisplay:YES];
 else
 [self setNeedsDisplayInRect:*(NSRect *)&r];
 
 //[lock unlock];    
 }
 }
 */


- (void)setImage:(CIImage *)image
{
	
	if (_image != image)
    {
		//[lock lock];    
		[_image release];
		_image = [image retain];
		[self setNeedsDisplay:YES];
		//[lock unlock];    
    }
	
	
    //[self setImage:image dirtyRect:CGRectInfinite];
}

/*
 - (void)setCleanRect:(CGRect)cleanRect
 {
 _cleanRect = cleanRect;
 }
 */

- (void)setDisplaySize:(CGSize)displaySize
{
	_displaySize = displaySize;
}

- (void)prepareOpenGL
{
    const GLint parm = 1;
	// file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Conceptual/CoreVideo/CVProg_Intro/chapter_1_section_1.html
	// file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/chapter_3_section_8.html
	
	/* Enable beam-synced updates. */
	
    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];
	
    /* Make sure that everything we don't need is disabled. Some of these
     * are enabled by default and can slow down rendering. */
	
    glDisable (GL_ALPHA_TEST);
    glDisable (GL_DEPTH_TEST);
    glDisable (GL_SCISSOR_TEST);
    glDisable (GL_BLEND);
    glDisable (GL_DITHER);
    glDisable (GL_CULL_FACE);
    glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask (GL_FALSE);
    glStencilMask (0);
    glClearColor (0.0f, 0.0f, 0.0f, 0.0f);
    glHint (GL_TRANSFORM_HINT_APPLE, GL_FASTEST);	
}

- (void)viewBoundsDidChange:(NSRect)bounds
{
#pragma unused(bounds)
    /* For subclasses. */
}

- (void)updateMatrices
{
    NSRect r = [self bounds];
	
    if (!NSEqualRects (r, _lastBounds))
    {
		[[self openGLContext] update];
		
		/* Install an orthographic projection matrix (no perspective)
		 * with the origin in the bottom left and one unit equal to one
		 * device pixel. */
		
		glViewport (0, 0, r.size.width, r.size.height);
		
		glMatrixMode (GL_PROJECTION);
		glLoadIdentity ();
		glOrtho (0, r.size.width, 0, r.size.height, -1, 1);
		
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity ();
		
		_lastBounds = r;
		
		[self viewBoundsDidChange:r];
    }
}

- (void)drawRect:(NSRect)r
{
	
	//[lock lock];    
	
    CGRect ir, rr;
    CGImageRef cgImage;
	
    [[self openGLContext] makeCurrentContext];
	
    /* Allocate a CoreImage rendering context using the view's OpenGL
     * context as its destination if none already exists. */
	
    if (_context == nil)
    {
		NSOpenGLPixelFormat *pf;
		
		pf = [self pixelFormat];
		if (pf == nil)
			pf = [[self class] defaultPixelFormat];
		
		_context = [[CIContext contextWithCGLContext: CGLGetCurrentContext() pixelFormat: [pf CGLPixelFormatObj] options: nil] retain];
    }
	
    ir = CGRectIntegral (*(CGRect *)&r);
	
    if ([NSGraphicsContext currentContextDrawingToScreen])
    {
		[self updateMatrices];
		
		/* Clear the specified subrect of the OpenGL surface then
		 * render the image into the view. Use the GL scissor test to
		 * clip to * the subrect. Ask CoreImage to generate an extra
		 * pixel in case * it has to interpolate (allow for hardware
		 * inaccuracies) */
		
		rr = CGRectIntersection (CGRectInset (ir, -1.0f, -1.0f), *(CGRect *)&_lastBounds);
		
		glScissor (ir.origin.x, ir.origin.y, ir.size.width, ir.size.height);
		glEnable (GL_SCISSOR_TEST);
		
		glClear (GL_COLOR_BUFFER_BIT);
		
		//NSLog(@"Display %@", _image);
		
		if (_image != nil)
		{
			CIImage *displayImage = _image;
			
			/*
			 NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage  
			 imageWithCVImageBuffer:imageBuffer]];
			 NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]]  
			 autorelease];
			 */
			
			
			
			//mirror filter
			if (mirrored) {
				[mirroredFilter setValue:displayImage forKey:@"inputImage"];
				displayImage = [mirroredFilter valueForKey:@"outputImage"];
			}
			
			
			
			//Add lines showing scan area
			if (goodScan) {
				[greenLinesFilter setValue:displayImage forKey:@"inputBackgroundImage"];
				displayImage = [greenLinesFilter valueForKey:@"outputImage"];
			}
			else {
				[redLinesFilter setValue:displayImage forKey:@"inputBackgroundImage"];
				displayImage = [redLinesFilter valueForKey:@"outputImage"];
			}			
			
			
			/*
			 CIFilter *transitionFilter = [CIFilter filterWithName:@"CIAffineTransform"];
			 [transitionFilter setValue:displayImage forKey:@"inputImage"];
			 NSAffineTransform *rotateTransform = [NSAffineTransform transform];
			 //[rotateTransform scaleXBy:2.0 yBy:2.0];
			 [rotateTransform translateXBy:0 yBy:-512.0];
			 [transitionFilter setValue:rotateTransform forKey:@"inputTransform"];
			 displayImage = [transitionFilter valueForKey:@"outputImage"];
			 */
			
			
			
			
			/*
			 CIFilter *noiseReduction = [CIFilter filterWithName:@"CINoiseReduction"];
			 [noiseReduction setValue:displayImage forKey:@"inputImage"];
			 [noiseReduction setValue:[NSNumber numberWithFloat: 0.1] forKey:@"inputNoiseLevel"];
			 [noiseReduction setValue:[NSNumber numberWithFloat: 0.2] forKey:@"inputSharpness"];
			 displayImage = [noiseReduction valueForKey:@"outputImage"];
			 */
			
			
			/*
			 CIFilter *noiseReduction = [CIFilter filterWithName:@"CISharpenLuminance"];
			 [noiseReduction setValue:displayImage forKey:@"inputImage"];
			 [noiseReduction setValue:[NSNumber numberWithFloat: 0.2] forKey:@"inputSharpness"];
			 displayImage = [noiseReduction valueForKey:@"outputImage"];
			 */
			
			/*
			 CIFilter *noiseReduction = [CIFilter filterWithName:@"CIUnsharpMask"];
			 [noiseReduction setValue:displayImage forKey:@"inputImage"];
			 //	[noiseReduction setValue:[NSNumber numberWithFloat: 4.0] forKey:@"inputRadius"];
			 //[noiseReduction setValue:[NSNumber numberWithFloat: 1.0] forKey:@"inputIntensity"];
			 displayImage = [noiseReduction valueForKey:@"outputImage"];
			 */
			
			/*
			 CIFilter *noiseReduction = [CIFilter filterWithName:@"CILineOverlay"];
			 [noiseReduction setValue:displayImage forKey:@"inputImage"];
			 //	[noiseReduction setValue:[NSNumber numberWithFloat: 4.0] forKey:@"inputRadius"];
			 //[noiseReduction setValue:[NSNumber numberWithFloat: 1.0] forKey:@"inputIntensity"];
			 displayImage = [noiseReduction valueForKey:@"outputImage"];
			 */
			
			/*
			 CIFilter *hueAdjust = [CIFilter filterWithName:@"CIHueAdjust"];
			 [hueAdjust setDefaults];
			 [hueAdjust setValue: _image forKey: @"inputImage"];
			 [hueAdjust setValue: [NSNumber numberWithFloat: 2.094] forKey: @"inputAngle"];
			 CIImage *rotatedImage = [hueAdjust valueForKey: @"outputImage"];
			 */
			
			/*
			 CIFilter *hueAdjust = [CIFilter filterWithName:@"CIEdgeWork"];
			 [hueAdjust setDefaults];
			 [hueAdjust setValue: _image forKey: @"inputImage"];
			 [hueAdjust setValue: [NSNumber numberWithFloat: 0.3] forKey: @"inputRadius"];
			 displayImage = [hueAdjust valueForKey: @"outputImage"];
			 */
			
			
			//RELEVANT_SECTION
			//Display the center part of a high resolution grab 
			if (newHighResiSight) {
				//[_context drawImage:displayImage atPoint:rr.origin fromRect:rr];
				[_context drawImage:displayImage atPoint:rr.origin fromRect:highResPortionOfImage];
			}
			else {
				[_context drawImage:displayImage atPoint:rr.origin fromRect:rr];
			}
			// use the commented out method if you want to perform scaling
			//CGRect where = centerSizeWithinRect(_displaySize, *(CGRect *)&_lastBounds);
			//[_context drawImage:displayImage inRect:where fromRect:_cleanRect];
			
		}
		
		glDisable (GL_SCISSOR_TEST);
		
		/* Flush the OpenGL command stream. If the view is double
		 * buffered this should be replaced by [[self openGLContext]
		 * flushBuffer]. */
		
		glFlush ();
    }
    else
    {
		/* Printing the view contents. Render using CG, not OpenGL. */
		
		if (_image != nil)
		{
			cgImage = [_context createCGImage:_image fromRect:ir];
			
			if (cgImage != NULL)
			{
				CGContextDrawImage ([[NSGraphicsContext currentContext]
									 graphicsPort], ir, cgImage);
				CGImageRelease (cgImage);
			}
		}
    }	
	
	//[lock unlock];
}

@end

static CGRect centerSizeWithinRect(CGSize size, CGRect rect)
{
	float delta;
	if( CGRectGetHeight(rect) / CGRectGetWidth(rect) > size.height / size.width ) {
		// rect is taller: fit width
		delta = rect.size.height - size.height * CGRectGetWidth(rect) / size.width;
		rect.size.height -= delta;
		rect.origin.y += delta/2;
	}
	else {
		// rect is wider: fit height
		delta = rect.size.width - size.width * CGRectGetHeight(rect) / size.height;
		rect.size.width -= delta;
		rect.origin.x += delta/2;
	}
	return rect;
}
