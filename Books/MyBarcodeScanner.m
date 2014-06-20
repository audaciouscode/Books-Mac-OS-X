//
//  MyBarcodeScanner.m


#import "MyBarcodeScanner.h"
#import "MyiSightWindow.h"
#import "MyGraphView.h"
#import "SampleCIView.h"
#import <QTKit/QTKit.h>
#import "SeqGrab.h"
#import "SGVideo.h"
#import "MyController.h"

#define BLACK_PIXEL 1
#define WHITE_PIXEL 0

//Not digit found value
#define NOT_FOUND -1

//How many bytes per pixel
#define SAMPLES_PER_PIXEL_RGB 4
//#define SAMPLES_PER_PIXEL_YVU 2

//Number of lines to scan
#define NUMBER_OF_LINES_SCANNED 24
//Pixels between lines
#define SPACING_BETWEEN_SCAN_LINE 6

//offset of each center point on each line, starts in horizontal center.
#define SPACING_BETWEEN_CENTERS 2
//offset of each center point on each line, starts in horizontal center.
#define NUMBER_OF_CENTERS 3


//The multiple of the average spacing that defines that a barcode area is over
#define MULTIPLY_AVERAGE_SPACING 3.5 
#define MULTIPLY_AVERAGE_SPACING_OLD 4.0 
#define RATIO_TO_CONSIDER_BOTTOM 0.2

//the roof limit of how sure of a digit value the algorythm can be. The lower the number the more volatile 
#define SURENESS_LIMIT 10
// Minimum number of digits that need to be scan in one pass to consider the number worthy of adding to information present
#define MINIMUM_DIGITS_FOR_GOOD_SCAN 7

//At what value of the (read width / ideal single bar width) is a bar considered 4 bars wide.
#define SEPARATION_VALUE_FOR_3_BARS 3.7

//At what row to start scanning depending on the resoultion
#define FIRST_LINE_SCAN ( bytesPerRow * (240 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE)))
#define FIRST_LINE_SCAN_HIGH ( bytesPerRow * (240 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE))) + (bytesPerRow /4) 


#ifdef DEBUG
// #define CLICK_TO_SCAN  // Uncomment to have continous scanning during debug 
// #define NUMBER_OF_LINES_SCANNED 1
#endif

//EAN encoding type
enum {
	MKLeftHandEncodingOdd,
	MKLeftHandEncodingBoth,
	MKRightHandEncoding
};



@interface MyBarcodeScanner (Private)
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;  //This is the function called to scan the barcode

- (void)foundBarcode:(NSString *)aBarcode;  //Let the program know a barcode was found

- (void)setupPreviewWindowWithTitle:(NSString *)aTitle;
- (void)clearGlobalFrequency;

- (void)getGreenFromRGB:(Ptr)rowPointer to:(int *)anArray640;
- (void)getLuminanceFrom2vuy:(char *)rowPointer to:(int *)anArray640;

- (void)findStart:(int *)startBarcode end:(int *)endBarcode forLine:(int [640])pixelLineArray derivative:(int [640])lineDerivativeArray centerAt:(int)centerX min:(int *)minValue max:(int *)maxValue;
- (void)getTopMask:(int *)topMask bottomMask:(int *)bottomMask forLine:(int *)pixelLineArray start:(int)startBarcode end:(int)endBarcode;
- (void)getBars:(int [62])barsArrayOneDimension forLine:(int *)pixelLineArray derivative:(int *)lineDerivativeArray start:(int)startBarcode end:(int)endBarcode top:(int)topMask bottom:(int)bottomMask;
- (BOOL)getBinaryValueForPixel:(int)pixelValue derivativeForPixel:(int)derivative top:(int)topMask bottom:(int)bottomMask;
- (void)readBars:(int [62])lastBinaryData;
- (void)getNumberForLocation:(int *)anArray  encoding:(int)encodingType location:(int)numberIndex;
int getNumberStripesEAN(int number, double average);

- (void)readBarsBackward:(int [62])lastBinaryData;

- (void)clearNumberArray:(char [3][12])aNumberArray;
- (BOOL)calculateFirstNumberFromOddEvenParity:(char [7])aNumberArray;
- (BOOL)compareAgainstPreviousScans:(char [3][12])aNumberArray previous:(char [3][12])previousNumberArray;
- (NSString *)barcodeFromArray:(char [3][12])aNumberArray;

- (void)addNumber:(char [3][12])aNumberArray toFrequencyMatrix:(char [10][13])aFrequencyMatrix;
- (void)addParity:(char [3][12])aNumberArray toParityMatrix:(char[2][6])aFrequencyMatrix;
- (void)addFrequencyMatrix:(char[10][13])aFrequencyMatrix toFrequencyMatrix:(char[10][13])anotherFrequencyMatrix;
- (int)parityFromFrequency:(char[2][6])aParityMatrix;

- (BOOL)parityDigitFromNumber:(char [3][12])aNumberArray; //!!! can mix with the other functions

- (NSString *)numberFromFrequencyMatrix:(char [10][13])aFrequencyMatrix;
- (BOOL)numberFromFrequencyMatrix:(char [10][13])aFrequencyMatrix toArray:(char [13])anEANArray;
- (BOOL)isValidCheckDigit:(char [13])anEANArray;
- (NSString *)barcodeFromEANArray:(char [13])anEANArray;

@end


// Experimental and debug printing
#if DEBUG

@interface MyBarcodeScanner (PrivateExperimental)
- (BOOL)checkCheckDigit:(char [3][12])aNumberArray;
- (void)printFrequencyMatrix:(char [10][13])aFrequencyMatrix;
- (void)printParityMatrix:(char[2][6])aParityMatrix;


- (void)processPixelBufferOld:(CVPixelBufferRef)pixelBuffer;
- (void)findStartOld:(int *)startBarcode end:(int *)endBarcode forLine:(int *)pixelLineArray derivative:(int *)lineDerivativeArray centerAt:(int)centerX min:(int *)minValue max:(int *)maxValue;

- (void)getPeakDistanceForLine:(int *)pixelLineArray start:(int)startBarcode end:(int)endBarcode averageHeight:(int)averageHeight barArray:(int *)barsArray;
- (int)getNumberfromThickness:(int)thickness oneBar:(float)aBarWidth;
- (void)readBarsStartingWithHeaderBars:(int [62])lastBinaryData;

@end

#endif DEBUG


@implementation MyBarcodeScanner

// Used to detect Leopard Vs. Tiger
- (SInt32)osVersion {
	SInt32 osVersion;
	Gestalt(gestaltSystemVersion,&osVersion);
	return osVersion;
}


#pragma mark -
#pragma mark QTKit

- (void)scanForBarcodeWindow:(NSWindow *)aWindow {
	BOOL success = NO;
	NSError *error = nil;
	CGSize displaySize; //To be able to mirror the image fast without calculation the size is based to the preview view
	BOOL useOldCapture = NO;
	BOOL isLeopard = YES;
	if ([self osVersion] < MKOSXLeopard)
		isLeopard = NO;
	BOOL setSizeOfBuffer = YES;
	NSString *windowTitle = nil;
	
	// If the isight is already running then bring the window front
	// 	if (mCaptureSession && [mCaptureSession isRunning] && previewWindow) {
	if (previewWindow) {
		[previewWindow makeKeyAndOrderFront:self];
		return;
	}
	
	// We need at least version 721 of quicktime for the QTKit to installed
	SInt32 quickTimeVersionNumber;
	Gestalt(gestaltQuickTime, &quickTimeVersionNumber);
	//NSLog(@"%x", quickTimeVersionNumber);
	if (quickTimeVersionNumber < 0x721000) {
		NSRunAlertPanel(NSLocalizedStringWithDefaultValue(@"Action Required", nil, [NSBundle mainBundle], nil, nil), NSLocalizedStringWithDefaultValue(@"NoQuickTime721", nil, [NSBundle mainBundle], @"The version of QuickTime installed is lower than 7.2.1, please install the latest QuickTime from http://www.apple.com/quicktime/download ", nil), @"OK", nil, nil);
		return;
	}
	
	// Find a video device
	// Use old capture method on Tiger always
	QTCaptureDevice *videoDevice = nil;
	//if (isLeopard) {
		videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		if (videoDevice)
			success = [videoDevice open:&error];
		
		
		// If a video input device can't be found or opened, try to find and open a muxed input device
		if (!success) {
			/*//NSLog(@"Video device failed look for muxed");
			 //NSLog(@"Avaliable devices:");
			 NSEnumerator *enumDevice = [[QTCaptureDevice inputDevices] objectEnumerator];
			 QTCaptureDevice *nextDevice;
			 while (nextDevice = [enumDevice nextObject]) {
			 //NSLog(@"%@", nextDevice);
			 }
			 */
			
			videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
			//NSLog(@"%@ %@ %@", videoDevice, [videoDevice modelUniqueID], [videoDevice localizedDisplayName]);
			if (videoDevice)
				success = [videoDevice open:&error];
			//NSLog(@"%success: %d device: %@", success, videoDevice);
		}
		
		// Write error to the console log 
		if (!success) {
			videoDevice = nil;
			DLog(@"Error: video device not found: %@", [error localizedDescription]);
		}
	//}
	
	//Find out if it's the new built-in High res iSight
	// imac 2.0 GHX 20inch first built-in version "ProductID_34049"
	// imac silver first high-res "ProductID_34050"
	// "FireWire iSight" for the old external one
	NSString *cameraDescription = [videoDevice modelUniqueID];
	NSString *cameraName = [videoDevice localizedDisplayName];
	//NSLog(@"Device: %@", cameraDescription);
	//NSLog(@"Name: %@", [videoDevice localizedDisplayName]);
	
	int productIDNumber = 0;
	int location = [cameraDescription rangeOfString:@"ProductID_"].location;
	if (location != NSNotFound) {
		NSString *idNumber = [cameraDescription substringFromIndex:location + 10];
		productIDNumber = [idNumber intValue];
	}
	
	// This device give a quarter image, can not get full 1280 x 1024 buffer
	/*
	if (cameraDescription && [cameraDescription rangeOfString:@"com.apple.QTKit.legacydevice"].location != NSNotFound) {
			displaySize = CGSizeMake(1280.0, 1024.0);
			newHighResiSight = NO;
			setSizeOfBuffer = NO;
			windowTitle = @"Legacy";		
		}
	*/
	
	// Apparently 34053 works well with the regular 640 x 480 version
	if (cameraDescription && productIDNumber >= 34050 && productIDNumber <= 34054 && productIDNumber != 34053 && ([cameraDescription rangeOfString:@"VendorID_1452"].location != NSNotFound)) { // [cameraDescription rangeOfString:@"ProductID_34050"].location != NSNotFound) {
		displaySize = CGSizeMake(1280.0, 1024.0);
		newHighResiSight = YES;
		setSizeOfBuffer = NO; // We let it choose 1280 x 1024 on it's own otherwise it squishies the image
		windowTitle = @"Built-in iSight";
	}
	else if (cameraDescription && [cameraDescription rangeOfString:@"VendorID_1133 ProductID_2448"].location != NSNotFound) { //Logitech 9000 Pro
		displaySize = CGSizeMake(1280.0, 1024.0); // Should really be 1280 x 960, full res at 1600 x 1200
		newHighResiSight = YES;
		windowTitle = @"Logitech 9000 Pro";
	}
	else if (cameraDescription && [cameraDescription rangeOfString:@"VendorID_3277 ProductID_82"].location != NSNotFound) { //TerraCam X2
		displaySize = CGSizeMake(1280.0, 1024.0); // Should really be 1280 x 960, full res at 1600 x 1200
		newHighResiSight = YES;
		windowTitle = @"TerraCam X2";
	}
	else if (!isLeopard || (cameraDescription && ([cameraDescription rangeOfString:@"PYRO WebCam"].location != NSNotFound || [cameraDescription rangeOfString:@"ProductID_41271"].location != NSNotFound)) || (cameraName && [cameraDescription rangeOfString:@"MV500i"].location != NSNotFound)) { 
		//PYRO WEBCAM,VendorID_1266 ProductID_41271 or tiger OS
		// MV500i is Cannon camera that also needs the old iSight
		displaySize = CGSizeMake(640.0, 480.0);
		newHighResiSight = NO;
		useOldCapture = YES;
		windowTitle = @"iSight Tiger"; //Should not be seen, but just in case
	}
	else {
		displaySize = CGSizeMake(640.0, 480.0);
		newHighResiSight = NO;
		if (cameraDescription)
			windowTitle = @"iSight";
		else
			windowTitle = @"External Camera";
	}
	
	
	if (useOldCapture) {
		//This is the old version that is used if running Tiger as the QTKit is not the same even though it's included with the new version of QuickTime on Tiger
		
		if (videoDevice && [videoDevice isOpen])
			[videoDevice close];
		
		int bytesPerRow = displaySize.width * 2;
		firstScanOffset = FIRST_LINE_SCAN;
		
		mGrabber = [[SeqGrab alloc] init];
		[mGrabber setIdleFrequency:60];
		SGVideo *vide = [[SGVideo alloc] initWithSeqGrab:mGrabber];
		
		if (vide == nil)
		{
			if (aWindow)
				NSBeginAlertSheet(NSLocalizedStringWithDefaultValue(@"Action Required", nil, [NSBundle mainBundle], nil, nil), @"OK", nil, nil, aWindow, nil, nil, nil, nil, NSLocalizedStringWithDefaultValue(@"No iSight", nil, [NSBundle mainBundle], @"Please make sure your firewire camera is connected to your computer.", nil));
			else
				NSRunAlertPanel(NSLocalizedStringWithDefaultValue(@"Action Required", nil, [NSBundle mainBundle], nil, nil), NSLocalizedStringWithDefaultValue(@"No iSight", nil, [NSBundle mainBundle], @"Please make sure your firewire camera is connected to your computer.", nil), @"OK", nil, nil);
			return;
			
		}
		else {
			[vide setBarcodeScanner:self];
			[vide setUsage:seqGrabPreview];
			
			[self setupPreviewWindowWithTitle:@"- iSight -"];
			[previewView setHighResiSight:NO];
			[previewView setDisplaySize:displaySize];
			[previewView setMirrored:mirrored]; //Has to come after the displaySize is set, as the mirror filter needs that information
			
			[mGrabber preview];
			
			[vide release]; // it was retained by its mGrabber
		}
		
	}
	else if (videoDevice == nil) {
		NSRunAlertPanel(NSLocalizedStringWithDefaultValue(@"Action Required", nil, [NSBundle mainBundle], nil, nil), NSLocalizedStringWithDefaultValue(@"No iSight", nil, [NSBundle mainBundle], @"Please make sure your firewire camera is connected to your computer.", nil), @"OK", nil, nil);
		return;
	}
	else {
		
		/*//NSLog(@"attributes: %@", [videoDevice deviceAttributes]);
		 NSEnumerator *enumDevice = [[videoDevice formatDescriptions] objectEnumerator];
		 QTFormatDescription *nextDevice;
		 while (nextDevice = [enumDevice nextObject]) {
		 //NSLog(@"format: %@", [nextDevice localizedFormatSummary]);
		 }
		 */
		
		if (cameraDescription && [cameraDescription rangeOfString:@"FireWire iSight"].location != NSNotFound /* || [cameraDescription rangeOfString:@"VendorID_1133 ProductID_2448"].location != NSNotFound */) {
			
			windowTitle = @"FireWire iSight";
			
			static BOOL firstRun = YES;
			
			if (firstRun) {
				firstRun = NO;
				//close QTKit device
				if ([videoDevice isOpen])
					[videoDevice close];
				
				SGChannel           mChan;
				SeqGrabComponent    mSeqGrab;
				OpenADefaultComponent(SeqGrabComponentType, 0, &mSeqGrab);
				
				SGInitialize(mSeqGrab);
				ComponentResult errorChannel = SGNewChannel(mSeqGrab, VideoMediaType, &mChan);
				
				if (errorChannel == 0) {
					
					/*
					 Rect setVideoRec;
					 SetRect(&setVideoRec, 0, 0, 640, 480);
					 //NSLog(@"set Rect: %d, %d", setVideoRec.right, setVideoRec.bottom);
					 SGSetChannelBounds(mChan, &setVideoRec);
					 */
					
					// Set the focus value helps with external iSights
					// Thanks to Wil Shipley for the focus code: http://lists.apple.com/archives/quicktime-api/2004/Mar/msg00257.html
					ComponentInstance vd = SGGetVideoDigitizerComponent(mChan);
					if (vd) {
						
						//Old external camera, laod old code for capturing to be able to set the focus on the camera
						QTAtomContainer iidcFeaturesAtomContainer = NULL;
						QTAtom featureAtom = 0.0;
						QTAtom typeAndIDAtom = 0.0;
						QTAtom featureSettingsAtom = 0.0;
						QTNewAtomContainer(&iidcFeaturesAtomContainer);
						
						
						QTInsertChild(iidcFeaturesAtomContainer, kParentAtomIsContainer, vdIIDCAtomTypeFeature, 1, 0, 0, nil, &featureAtom);
						VDIIDCFeatureAtomTypeAndID featureAtomTypeAndID = {vdIIDCFeatureFocus, vdIIDCGroupMechanics, {5}, vdIIDCAtomTypeFeatureSettings, vdIIDCAtomIDFeatureSettings};
						QTInsertChild(iidcFeaturesAtomContainer, featureAtom, vdIIDCAtomTypeFeatureAtomTypeAndID, vdIIDCAtomIDFeatureAtomTypeAndID, 0, sizeof(featureAtomTypeAndID), &featureAtomTypeAndID, &typeAndIDAtom);
						VDIIDCFeatureSettings featureSettings = {{0, 0, 0, 0.0, 0.0}, {vdIIDCFeatureFlagOn | vdIIDCFeatureFlagManual | vdIIDCFeatureFlagRawControl, 0.35}};
						QTInsertChild(iidcFeaturesAtomContainer, featureAtom, vdIIDCAtomTypeFeatureSettings, vdIIDCAtomIDFeatureSettings, 0, sizeof(featureSettings), &featureSettings, &featureSettingsAtom);
						VDIIDCSetFeatures(vd, iidcFeaturesAtomContainer);
					}
					
					
					// Set saturation to black and white
					unsigned short newSaturation = 0;
					VDSetSaturation(vd, &newSaturation);
					
				}
				
				SGDisposeChannel(mSeqGrab, mChan);
				CloseComponent(mSeqGrab);
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
				
				//Re open device
				success = [videoDevice open:&error];
				
				// Write error to the console log 
				if (!success) {
					videoDevice = nil;
					DLog(@"Error: video device could not be re-opened after changing settings: %@", [error localizedDescription]);
					[self closeiSight];
					return;
				}
			}
		}
		
		// Create the capture session
		mCaptureSession = [[QTCaptureSession alloc] init];
		
		//Add the video device to the session as a device input
		QTCaptureDeviceInput *mCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [mCaptureSession addInput:mCaptureVideoDeviceInput error:&error];
		[mCaptureVideoDeviceInput release];
		if (!success) {
			DLog(@"Error: video device could not be added as input: %@", [error localizedDescription]);
			[self closeiSight];
			return;
		}
		
		// k32ARGBPixelFormat may be used on Mac OS X 10.4.x
		// kCVPixelFormatType_32ARGB can be used in 10.5 kCVPixelFormatType_422YpCbCr8
		// k2vuyPixelFormat
		NSMutableDictionary *attributes;
		if (newHighResiSight) {
			int bytesPerRow = displaySize.width * 2; // FIRST_LINE_SCAN needs to know the bytes per row to calculate the offset
			firstScanOffset = FIRST_LINE_SCAN_HIGH;
			// If we leave the size alone we get a pixel buffer that is 1280 x 1024, if we specify the size we get a squished image width wise?
			attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
						  //[NSNumber numberWithDouble:displaySize.width], (id)kCVPixelBufferWidthKey, 
						  //[NSNumber numberWithDouble:displaySize.height], (id)kCVPixelBufferHeightKey,
						  [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey,
						  [NSNumber numberWithUnsignedInt:k2vuyPixelFormat], (id)kCVPixelBufferPixelFormatTypeKey,
						  nil];
			if (setSizeOfBuffer) {
				[attributes setObject:[NSNumber numberWithDouble:displaySize.width] forKey:(id)kCVPixelBufferWidthKey];
				[attributes setObject:[NSNumber numberWithDouble:displaySize.height] forKey:(id)kCVPixelBufferHeightKey];
			}
		}
		else {
			int bytesPerRow = displaySize.width * 2;
			firstScanOffset = FIRST_LINE_SCAN;
			attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
						  [NSNumber numberWithDouble:displaySize.width], (id)kCVPixelBufferWidthKey, 
						  [NSNumber numberWithDouble:displaySize.height], (id)kCVPixelBufferHeightKey,
						  [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey,
						  [NSNumber numberWithUnsignedInt:k2vuyPixelFormat], (id)kCVPixelBufferPixelFormatTypeKey,
						  nil];
		}
		
		// QTCaptureVideoPreviewOutput could be if frame rate is not so important
		QTCaptureDecompressedVideoOutput *mCaptureDecompress = [[QTCaptureDecompressedVideoOutput alloc] init];
		//QTCaptureVideoPreviewOutput *mCaptureDecompress = [[QTCaptureVideoPreviewOutput alloc] init];
		[mCaptureDecompress setDelegate:self];
		[mCaptureDecompress setPixelBufferAttributes:attributes];
		success = [mCaptureSession addOutput:mCaptureDecompress error:&error];
		[mCaptureDecompress release];
		if (!success) {
			DLog(@"Error: could not add output device: %@", [error localizedDescription]);
			[self closeiSight];
			return;
		}
		
		// Associate the capture view in the UI with the session
		[self setupPreviewWindowWithTitle:windowTitle];
		[previewView setHighResiSight:newHighResiSight];
		[previewView setDisplaySize:displaySize];
		[previewView setMirrored:mirrored]; //Has to come after the displaySize is set, as the mirror filter needs that information
		
		[mCaptureSession startRunning];				
	}
}


- (void)setupPreviewWindowWithTitle:(NSString *)aTitle {
	
	lastDateScan = [[NSDate date] retain];
	
	// set up a preview window for the newly added video channel
	NSRect screenRect = [[[NSApp mainWindow] screen] visibleFrame];
	//NSRect windowRect = [videoChannel previewBounds];
	NSRect windowRect = NSMakeRect(0, 0, 640, 480);
	//NSRect windowRect = NSMakeRect(0, 0, 1280, 1024);
	
	
	//if (windowRect.size.width == 0. || windowRect.size.height == 0.)
	//windowRect = [videoChannel srcVideoBounds];
	
	windowRect.origin.x = screenRect.origin.x + 16;
	
	windowRect.origin.y = screenRect.origin.y + screenRect.size.height - windowRect.size.height - 22;
	
	
	// Here's where we create a window to hold 
	// the sgvideo object's preview view
	previewWindow = [[MyiSightWindow alloc] initWithContentRect:windowRect 
															   styleMask:NSTitledWindowMask | NSClosableWindowMask
																 backing:NSBackingStoreBuffered 
																   defer:YES
																  screen:[[NSApp mainWindow] screen]];
	
	[previewWindow setWorksWhenModal:YES];
	
	[previewWindow setReleasedWhenClosed:YES];
	[previewWindow setFrameAutosaveName:@"iSightWindow"];
	
	previewView = [[SampleCIView alloc] initWithFrame:windowRect];
	//[[previewWindow contentView] addSubview:previewView];
	[previewWindow setContentView:previewView];
	[previewView release];
	
	[previewWindow setTitle:aTitle];
	
	//[[videoChannel previewView] setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[previewWindow setDelegate:self];
	[previewWindow makeKeyAndOrderFront:self];
	
	[self clearGlobalFrequency];
	[lastBarcode release];
	lastBarcode = nil;
	//lastDateScan = [NSDate date];
	
	/*
	 // If we are in debug mode show a graph of the green pixel value
	 #if DEBUG
	 NSWindow *graphWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(30,30,640,400) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	 
	 [graphWindow setLevel: NSNormalWindowLevel];
	 [graphWindow setAlphaValue:1.00];
	 [graphWindow setOpaque:YES];
	 [graphWindow setHasShadow:NO];
	 graphView = [[[MyGraphView alloc] initWithFrame:[[graphWindow contentView] bounds]] autorelease];
	 [graphWindow setContentView:graphView];
	 [graphWindow makeKeyAndOrderFront:self];
	 
	 NSWindow *barcodeWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(30,430,1280,100) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	 
	 [barcodeWindow setLevel: NSNormalWindowLevel];
	 [barcodeWindow setAlphaValue:1.00];
	 [barcodeWindow setOpaque:YES];
	 [barcodeWindow setHasShadow:NO];
	 barcodeView = [[[MyGraphView alloc] initWithFrame:[[barcodeWindow contentView] bounds]] autorelease];
	 [barcodeWindow setContentView:barcodeView];
	 [barcodeWindow makeKeyAndOrderFront:self];
	 #endif DEBUG
	 */
}


- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection {
	
	//NSLog(@"Video frame incoming");
	
	if (previewWindow != nil) {
		
		//NSLog(@"create image");
		CIImage * ciImage = [CIImage imageWithCVImageBuffer:videoFrame];
		[previewView setImage:ciImage];	
		
		//NSLog(@"look for barcode");
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[self processPixelBuffer:videoFrame];
		[pool release];
		
		
	}
}

- (void)dealloc {
	[self closeiSight];
	[delegate release]; delegate = nil;
	//[previewWindow release];
	[super dealloc];
}


//When the window closes it's time to close the iSight as well and the timer
- (BOOL)closeiSight {
	//NSLog(@"Close iSight: %@", mCaptureSession);
	BOOL returnValue = NO;
	if (mCaptureSession) {
		[mCaptureSession stopRunning];
		QTCaptureDevice *captureDevice = [[[mCaptureSession inputs] lastObject] device];
		if ([captureDevice isOpen])
			[captureDevice close];
		
		[mCaptureSession release];
		mCaptureSession = nil;
		
		returnValue = YES;
	}	
	else if (mGrabber) {
		[mGrabber stop];
		NSArray *channels = [mGrabber channels];
		if ([channels count]) {
			
			SGChan* doomedChan = [channels objectAtIndex:0];
			[mGrabber removeChannel:doomedChan];
			
			returnValue = YES;
		}
		[mGrabber release]; mGrabber = nil;
	}
	
	if (returnValue) {
		
		[lastBarcode release]; lastBarcode = nil;
		
		//[previewWindow release];
		[previewWindow close]; // NSWindow is released on close 
		previewWindow = nil;
		previewView = nil;		
		
		if ([delegate respondsToSelector:@selector(iSightWillClose)]) {
			[delegate iSightWillClose];
		}
		[previousSingleFrameOldScan release]; previousSingleFrameOldScan = nil;
	}
	
	[lastDateScan release]; lastDateScan = nil; 
	return returnValue;
}


#pragma mark -
#pragma mark Barcode

// Delegate method for add window only called when the red button is used to close the window
// Needed here to trigger the closeiSight: method that cleans up sequence grabber
- (BOOL)windowShouldClose:(id)sender {	
    [self closeiSight];
    return YES;
}


// Send a message to the delegate that we found a barcode
// Close the window if stayOpen is negative
// Because this message is sent delayed with performSelector so as to not close the window in the middle of displaying the buffer it
// might be called twice
- (void)foundBarcode:(NSString *)aBarcode {
	[self clearGlobalFrequency];
	
	// Has to go before gotBarcode: on the main thread as it sends a barcode will close message that brings up the find panel
	if (stayOpen == NO)
		[self performSelectorOnMainThread:@selector(closeiSight) withObject:nil waitUntilDone:NO];
	
	// Only send barcode that we didn't previously scan
	// lastBarcode is reset to nil when calling scanBarcode
	// Scan barcodes with a separation of at least half a second
	if ([lastDateScan timeIntervalSinceNow] < -0.5 && (lastBarcode == nil || ![lastBarcode isEqualToString:aBarcode])) {
		[lastDateScan release];
		lastDateScan = [[NSDate date] retain];
		[(NSSound *)[NSSound soundNamed:@"Morse"] play];	
		//[delegate gotBarcode:aBarcode];
		[lastBarcode release];
		lastBarcode = [aBarcode retain];
		
		[delegate performSelectorOnMainThread:@selector(gotBarcode:) withObject:[[aBarcode retain] autorelease] waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark Barcode Scanning


- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer {
	
#ifdef DEBUG	
#ifdef CLICK_TO_SCAN
	if (scanBarcode == NO) {
		return;
	}
	scanBarcode = NO;
#endif CLICK_TO_SCAN
#endif DEBUG
	
	/*	This is where it's being asked to process the pixel buffer for a barcode. Any other algorithms for 
	 searching for the barcode should be inserted around here.  */
	
	CVReturn possibleError = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	if (possibleError) {
		DLog(@"Error locking pixel bufffer, when looking for barcode.");
		return;
	}
	
	Ptr pixelBufferBaseAddress = (Ptr)CVPixelBufferGetBaseAddress(pixelBuffer); 
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);  //bytes per line
	
	/*
	 
	 
	 //BOOL RGBA = NO;
	 //if (samplesPerPixel == 4)
	 //	RGBA = YES;
	 
	 //NSLog(@"bytes/row: %d width: %d height: %d", bytesPerRow, widthOfBuffer, heightOfBuffer);
	 //OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
	 */
	
	// Make sure we have at least 640 pixel rows
	if (frameCount == 0) {
		size_t widthOfBuffer = CVPixelBufferGetWidth(pixelBuffer);  //bytes per line
		
		/*
		 size_t heightOfBuffer = CVPixelBufferGetHeight(pixelBuffer);  //bytes per line
		 //NSLog(@"Capture size: %d x %d, bytes/row: %d", widthOfBuffer, heightOfBuffer, bytesPerRow);
		 */
		
		if (widthOfBuffer < 620) {
			size_t heightOfBuffer = CVPixelBufferGetHeight(pixelBuffer);  //bytes per line
			CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

			DLog(@"Error: image capture size too small: %d x %d, bytes/row: %d", widthOfBuffer, heightOfBuffer, bytesPerRow);
			[self performSelectorOnMainThread:@selector(closeiSight) withObject:nil waitUntilDone:NO];
			//NSRunAlertPanel(NSLocalizedStringWithDefaultValue(@"Confirmation", nil, FRAMEWORK_BUNDLE, nil, nil), @"The video resolution of this camera is not high enough for the barcode scanner, a minimum of 640 pixels wide is required.", @"OK",nil, nil);
			return;
		}
	}
	
	
	int i, j; 
	int bottomMask, topMask;
	Ptr firstRowToScan = pixelBufferBaseAddress + firstScanOffset;
	int greenScalePixels[640];  //The value of the green pixel 0 - 255
	int greenDerivative[640];
	//int xAxisCenterPoint = 320;// - (NUMBER_OF_LINES_SCANNED / 2 * SPACING_BETWEEN_CENTERS); //initalize x center point
	int xAxisCenterPoint = 320 - (NUMBER_OF_LINES_SCANNED / 2 * SPACING_BETWEEN_CENTERS); //initalize x center point
	
	
	
	//[vide setGoodScan:NO];
	[previewView setGoodScan:NO];
	//BOOL noMissingNumbers = NO;  //check local number as all digits where deciphered
	BOOL noMissingNumbersOLD = NO;
	
	//clear local number
	for (i = 0; i < 12; i++) {
		previousNumberLocalArray[0][i] = NOT_FOUND;
		previousNumberLocalArray[2][i] = 0;
		
		previousNumberLocalArrayOLD[0][i] = NOT_FOUND;
		previousNumberLocalArrayOLD[2][i] = 0;
		
	}
	previousNumberLocalArray[1][6] = NOT_FOUND;
	previousNumberLocalArrayOLD[1][6] = NOT_FOUND;
	
	
	char frequencyMatrix[10][13] = {0};
	char parityFrequencyMatrix[2][6] = {0};
	
	
	//clear
	// Should clear every 90 frames or so
	if (frameCount == 90) {
		[self clearGlobalFrequency];
		//NSLog(@"CLEAR GLOBAL");
	}
	frameCount++;
	
	// http://www.cocoabuilder.com/archive/message/cocoa/2007/12/15/194970
	
	//NSLog(@"Scan lines");
	
	//Do a number of rows from the same image centered in the middle with varying x axis center points
	for (i = 0; i < NUMBER_OF_LINES_SCANNED; i++) {
		
		//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		
		//if (RGBA) {
		//NSLog(@"Get RGB VALUES");
		//		[self getGreenFromRGB:firstRowToScan + (bytesPerRow * i * SPACING_BETWEEN_SCAN_LINE) to:greenScalePixels];
		//	}
		//	else {
		//NSLog(@"Get 2VUY VALUES");
		[self getLuminanceFrom2vuy:firstRowToScan + (bytesPerRow * i * SPACING_BETWEEN_SCAN_LINE) to:greenScalePixels];
		//	}
		
		//NSLog(@"Derivative");
		//first derivative
		for (j = 0; j < 640; j++) {
			greenDerivative[j] = greenScalePixels[j + 1] - greenScalePixels[j];
		}
		
		xAxisCenterPoint = xAxisCenterPoint + SPACING_BETWEEN_CENTERS;
		
		//NSLog(@"Find barcode area");
		//Find barcode area and information about max and min values of the pixels
		int startBarcode = 0, endBarcode = 639, minValue = 255, maxValue = 0;
		[self findStart:&startBarcode end:&endBarcode forLine:greenScalePixels derivative:greenDerivative centerAt:xAxisCenterPoint min:&minValue max:&maxValue];
		
		/*
		 #ifdef DEBUG
		 
		 //Draw a green line of the green pixel values
		 NSBezierPath *fullWave = [NSBezierPath bezierPath];
		 [fullWave moveToPoint:NSMakePoint(0, greenScalePixels[0])];
		 for (j = 1; j < 640; j++)
		 [fullWave lineToPoint:NSMakePoint(j, greenScalePixels[j])];
		 [graphView setGreenPath:fullWave];	
		 
		 
		 //Draw a blue line for the area of the barcode
		 NSBezierPath *barcodeAreaPath = [NSBezierPath bezierPath];
		 [barcodeAreaPath moveToPoint:NSMakePoint(startBarcode, greenScalePixels[startBarcode])];
		 for (j = startBarcode + 1; j < endBarcode; j++)
		 [barcodeAreaPath lineToPoint:NSMakePoint(j, greenScalePixels[j])];
		 [graphView setBluePath:barcodeAreaPath];
		 
		 
		 NSBezierPath *derivativePath = [NSBezierPath bezierPath];
		 [derivativePath moveToPoint:NSMakePoint(startBarcode, greenDerivative[startBarcode] + 280) ];
		 for (j = startBarcode + 1; j < endBarcode; j++) {
		 [derivativePath lineToPoint:NSMakePoint(j, greenDerivative[j] + 280)];
		 }
		 [graphView setPath:derivativePath withColor:[NSColor orangeColor]];
		 
		 
		 NSBezierPath *derivativePathZero = [NSBezierPath bezierPath];
		 [derivativePathZero moveToPoint:NSMakePoint(startBarcode, 280) ];
		 [derivativePathZero lineToPoint:NSMakePoint(endBarcode, 280)];
		 [graphView setPath:derivativePathZero withColor:[NSColor yellowColor]];		
		 #endif		
		 */
		
		// A real barcode will not reach to the edge of the frame
		if (endBarcode != 639 && startBarcode > 0) {
			int barsArray[62] = {0};
			
			//NSLog(@"Get mask");
			[self getTopMask:&topMask bottomMask:&bottomMask forLine:greenScalePixels start:startBarcode end:endBarcode];
			//Get the bar width information based on the mask
			// This function can do with a serious improvement, it only likes very steep and condensed barcodes, if a barcode has soft curves it fails, as it uses the derivative to decide if a pizel is black or white insteasd of an average tone between the last two peaks.
			//NSLog(@"Bars");
			[self getBars:barsArray forLine:greenScalePixels derivative:greenDerivative start:startBarcode end:endBarcode top:topMask bottom:bottomMask];
			
			/*
			 //Draw the mask lines
			 #ifdef DEBUG
			 //NSLog(@"%d %d", topMask, bottomMask);
			 NSBezierPath *topPathZero = [NSBezierPath bezierPath];
			 [topPathZero moveToPoint:NSMakePoint(startBarcode, topMask) ];
			 [topPathZero lineToPoint:NSMakePoint(endBarcode, topMask)];
			 [graphView setPath:topPathZero withColor:[NSColor purpleColor]];
			 
			 NSBezierPath *bottomPathZero = [NSBezierPath bezierPath];
			 [bottomPathZero moveToPoint:NSMakePoint(startBarcode, bottomMask) ];
			 [bottomPathZero lineToPoint:NSMakePoint(endBarcode, bottomMask)];
			 [graphView setPath:bottomPathZero withColor:[NSColor magentaColor]];			
			 
			 
			 [graphView display];
			 #endif 
			 */
			//Try to read a number based on the bars widths
			numberOfDigitsFound = 0;
			[self clearNumberArray:numberArray];
			//[self readBars:barsArray];
			//NSLog(@"Read bars");
			[self readBars:barsArray];
			//NSLog(@"Process bars");
			if (numberOfDigitsFound > MINIMUM_DIGITS_FOR_GOOD_SCAN ) {
				[self calculateFirstNumberFromOddEvenParity:numberArray[1]];
				[self addNumber:numberArray toFrequencyMatrix:frequencyMatrix];
				[self addParity:numberArray toParityMatrix:parityFrequencyMatrix];
				//[vide setGoodScan:YES];
				[previewView setGoodScan:YES];
				//noMissingNumbers = 
				[self compareAgainstPreviousScans:numberArray previous:previousNumberLocalArray];
			}
			
			//NSLog(@"Scanned %@  local:%@  j:%d", [self barcodeFromArray:numberArray], [self barcodeFromArray:previousNumberLocalArray], j);
			
#if DEBUG
			//NSString *forwardScan = [self barcodeFromArray:numberArray];
#endif		
			
			//NSLog(@"read bars backwards");
			[self clearNumberArray:numberArray];
			numberOfDigitsFound = 0;
			[self readBarsBackward:barsArray];
			
#if DEBUG
			//NSLog(@"Forward: %@  Back:%@ ", forwardScan, [self barcodeFromArray:numberArray]);
#endif		
			//NSLog(@"Back:%@ ", [self barcodeFromArray:numberArray]);
			
			//Back reading is pretty bad with errors
			//NSLog(@"read backwards");
			if (numberOfDigitsFound > 4 ) {
				//remove first digits, when going backwards
				// int k;
				// for (k=0 ; k<6;k++)
				// numberArray[0][k] = NOT_FOUND;
				
				
				[self addNumber:numberArray toFrequencyMatrix:frequencyMatrix];
				//[vide setGoodScan:YES];
				// noMissingNumbers = [self compareAgainstPreviousScans:numberArray previous:previousNumberLocalArray];
			}
			
			//[self printFrequencyMatrix:frequencyMatrix];
			//}
			
			//Try the old version on this line as well
			
			// if the end goes to the edge of the frame do not process
			//if (endBarcode != 639) {
			
			int differenceInRange =  maxValue - minValue;
			
			// repeat for different values of the masks
			// the masks were determined via trial and error
			for (j =0; j < 5; j++) {
				
				int barsArray[62] = {0};
				
				if (j == 0) {
					bottomMask = minValue + (differenceInRange * 0.34);
					topMask = maxValue - (differenceInRange * 0.44);
				}
				else if (j == 1) {
					bottomMask = minValue + (differenceInRange * 0.15);
					topMask = maxValue - (differenceInRange * 0.4);
				}
				else {
					bottomMask = minValue + (differenceInRange * 0.18);
					topMask = maxValue - (differenceInRange * 0.5);
				}
				
				//NSLog(@"Get bars old");
				//Get the bar width information based on the mask
				[self getBars:barsArray forLine:greenScalePixels derivative:greenDerivative start:startBarcode end:endBarcode top:topMask bottom:bottomMask];
				
				//NSLog(@"bars %@", [self stringFromBars:barsArray]);
				
				//Try to read a number based on the bars widths
				numberOfDigitsFound = 0;
				[self clearNumberArray:numberArray];
				//NSLog(@"read bars old");
				[self readBars:barsArray];
				
				//NSLog(@"process bars old");
				// If 7 or more digits were read from the barcode then process number 
				// and add it to the local number 
				// Don't check the scanned number if it has 12 digits as it not verfied and it could lead to a lucky checksum and a wrong number
				if (numberOfDigitsFound >= MINIMUM_DIGITS_FOR_GOOD_SCAN) {
					//NSLog(@"Scanned %@  local:%@  j:%d", [self barcodeFromArray:numberArray], [self barcodeFromArray:previousNumberLocalArrayOLD], j);
					//NSLog(@"j = %d %d", j, numberOfDigitsFound);
					//Also add to frequency
					//[self calculateFirstNumberFromOddEvenParity:numberArray[1]];
					//[self addNumber:numberArray toFrequencyMatrix:frequencyMatrix];
					//[self addParity:numberArray toParityMatrix:parityFrequencyMatrix];					
					//[vide setGoodScan:YES];
					[previewView setGoodScan:YES];
					noMissingNumbersOLD = [self compareAgainstPreviousScans:numberArray previous:previousNumberLocalArrayOLD];
					//[vide setScannedNumber:[self barcodeFromArray:previousNumberGlobalArray]];
				}
			} // old section
		}  // 639 section
		
		
		//[pool release];
		//} //centers
	}
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	
	//NSLog(@"check scan");
	
	int parityBasedOnFrequency = [self parityFromFrequency:parityFrequencyMatrix];
	if (parityBasedOnFrequency != NOT_FOUND)
		frequencyMatrix[parityBasedOnFrequency][0] += 2; //Weighted by 2 as it's from the frequency and not a single scan
	
	[self addFrequencyMatrix:frequencyMatrix toFrequencyMatrix:globalFrequencyMatrix];	
	
	
	/*
	 #if DEBUG
	 NSLog(@"All");
	 [self printFrequencyMatrix:frequencyMatrix];
	 [self printParityMatrix:parityFrequencyMatrix];
	 
	 NSLog(@"Global");
	 [self printFrequencyMatrix:globalFrequencyMatrix];
	 
	 
	 NSString *barcodeString = [self barcodeFromArray:previousNumberLocalArray];
	 NSLog(@"Local number: %@", barcodeString);
	 
	 NSString *localNumber = [self numberFromFrequencyMatrix:frequencyMatrix];
	 NSLog(@"Local freq: %@", localNumber);
	 NSString *globalNumber = [self numberFromFrequencyMatrix:globalFrequencyMatrix];
	 NSLog(@"Global freq: %@", globalNumber);
	 
	 
	 barcodeString = [self barcodeFromArray:previousNumberLocalArrayOLD];
	 NSLog(@"OLD Local: %@", barcodeString);
	 //barcodeString = [self barcodeFromArray:previousNumberGlobalArray];
	 //NSLog(@"OLD Global: %@", barcodeString);
	 
	 [barcodeView removeAllPaths];
	 [graphView removeAllPaths];
	 #endif DEBUG
	 */
	
	
	/*
	 if (noMissingNumbers && parityBasedOnFrequency != NOT_FOUND) {
	 previousNumberLocalArray[1][6] = parityBasedOnFrequency;
	 if ([self checkCheckDigit:previousNumberLocalArray]) {
	 NSString *barcodeString = [self barcodeFromArray:previousNumberLocalArray];
	 
	 //NSLog(@"Found single frequency %@", barcodeString);
	 [self foundBarcode:barcodeString];
	 //[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
	 //[pool release];
	 return; //Otherwise it might sent another message with the global matches as well
	 }
	 }
	 */
	
	
	char localEANArray[13];
	if ([self numberFromFrequencyMatrix:frequencyMatrix toArray:localEANArray]) {
		if ([self isValidCheckDigit:localEANArray]) {
			NSString *barcodeString = [self barcodeFromEANArray:localEANArray];
			//NSLog(@"Local frequency: %@", barcodeString);
			[self foundBarcode:barcodeString];
			//[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
			//[pool release];
			return; //Otherwise it might sent another message with the global matches as well
		}
	}
	
	
	char globalEANArray[13];
	if ([self numberFromFrequencyMatrix:globalFrequencyMatrix toArray:globalEANArray]) {
		if ([self isValidCheckDigit:globalEANArray]) {
			NSString *barcodeString = [self barcodeFromEANArray:globalEANArray];
			//NSLog(@"Global frequency:  %@", barcodeString);
			[self foundBarcode:barcodeString];
			//[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
			//[pool release];
			return; //Otherwise it might sent another message with the global matches as well
		}
	}
	
	
	//check the local number if it has no missing numbers run the checksum
	if (noMissingNumbersOLD) {
		if ([self parityDigitFromNumber:previousNumberLocalArrayOLD]) {
			
			//Is correct but the single frame old, is sometimes mistaken s, has to scan the number twice
			
			NSString *barcodeString = [self barcodeFromArray:previousNumberLocalArrayOLD];
			
			if ([barcodeString isEqualToString:previousSingleFrameOldScan]) {
				[previousSingleFrameOldScan release]; previousSingleFrameOldScan = nil;
				
				//NSLog(@"Single frame old version: %@", barcodeString);
				[self foundBarcode:barcodeString];
				//[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
				return; //Otherwise it might sent another message with the global matches as well
			}
			
			[previousSingleFrameOldScan release];
			previousSingleFrameOldScan = [barcodeString retain];
		}
	}	
	
	/*
	 //Add the local number to the global number and
	 //check the global number if it has no missing numbers run the checksum
	 if ([self compareAgainstPreviousScans:previousNumberLocalArray previous:previousNumberGlobalArray] == YES) {
	 if ([self parityDigitFromNumber:previousNumberGlobalArray]) {
	 NSString *barcodeString = [self barcodeFromArray:previousNumberGlobalArray];
	 //NSLog(@"Found global OLD %@", barcodeString);
	 [self foundBarcode:barcodeString];
	 //[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
	 }
	 }
	 */
	
}




- (void)getLuminanceFrom2vuy:(char *)rowPointer to:(int *)anArray640 {
	int i;
	for (i = 0; i < 640; i++) {
		anArray640[i] = 255 - (UInt8)*(rowPointer + (i * 2) + 1) ;
	}
}

- (void)getLuminanceFrom2vuyBackwards:(char *)rowPointer to:(int *)anArray640 {
	int i;
	for (i = 0; i < 640; i++) {
		anArray640[i] = 255 - (UInt8)*(rowPointer + ((639 - i) * 2) + 1) ;
	}
}

//Get the Green pixel value for a row from the Pixel buffer
- (void)getGreenFromRGB:(Ptr)rowPointer to:(int *)anArray640 {
	// mirroring done by the CIImage at the display level
	int i;
	for (i = 0; i < 640; i++) {
		anArray640[i] = (UInt8)*(rowPointer + (i * SAMPLES_PER_PIXEL_RGB) +2) ;
		anArray640[i] = 255 - anArray640[i];
	}
}



#define NOISE_REDUCTION 4
// Determine the area of the barcode by using the supplied center and determining the average change of direction
// As soon as something is below 1/4 of the variation in height for more than the average spacing time MULTIPLY_AVERAGE_SPACING, then the barcode ends
- (void)findStart:(int *)startBarcode end:(int *)endBarcode forLine:(int [640])pixelLineArray derivative:(int [640])lineDerivativeArray centerAt:(int)centerX min:(int *)minValue max:(int *)maxValue {
	
	int averageSpacing = 0, numberOfCurves = 0, spacingInThisRun = 0;
	int i, count, startScan = centerX - 40, endScan = centerX + 40;
	
	BOOL positive = YES;
	if (lineDerivativeArray[startScan] < 0)
		positive = NO;
	
	
	//Build the average spacing number and the variation in height from a sample around the center
	for (i = startScan; i < endScan; i++) {
		
		if (*maxValue < pixelLineArray[i])
			*maxValue = pixelLineArray[i];
		else if (*minValue > pixelLineArray[i])
			*minValue = pixelLineArray[i];
		
		
		if (lineDerivativeArray[i] < -NOISE_REDUCTION) {
			if (positive) {
				positive = NO;
				averageSpacing = averageSpacing + spacingInThisRun;
				numberOfCurves++;
				spacingInThisRun = 0;
			}
			
		}
		else if (lineDerivativeArray[i] > NOISE_REDUCTION){
			if (!positive) {
				positive = YES;
				averageSpacing = averageSpacing + spacingInThisRun;
				numberOfCurves++;
				spacingInThisRun = 0;
			}
		}
		
		spacingInThisRun++;
	}
	
	//If there was a solid growing gradient with no curves then return
	if (numberOfCurves == 0)
		return;
	
	int localStartBarcode = 0, localEndBarcode = 639;
	
	averageSpacing = (averageSpacing / numberOfCurves) * MULTIPLY_AVERAGE_SPACING;
	
	//NSLog(@"min %d max %d spacing: %d curves: %d", *minValue, *maxValue, averageSpacing, numberOfCurves);
	int quarterHeight = ((*maxValue - *minValue) * RATIO_TO_CONSIDER_BOTTOM);
	int bottomForth = *minValue + quarterHeight;
	int topForth = *maxValue - quarterHeight;
	
	//anything below oneForth for averageSpacing * MULTIPLY_AVERAGE_SPACING is the end of the barcode
	for (i = centerX, count = 0; i > 0; i--) {
		if (pixelLineArray[i] < bottomForth ) { //|| pixelLineArray[i] > topForth) { //We need the beginnign to be exact, but not the end
			count++;
		}
		else {
			count = 0;
			localStartBarcode = i;
		}
		
		if (count > averageSpacing) {
			*startBarcode = localStartBarcode;
			break;
		}
	}
	
	for (i = centerX, count = 0; i < 640; i++) {
		if (pixelLineArray[i] < bottomForth || pixelLineArray[i] > topForth) {
			count++;
		}
		else {
			count = 0;
			localEndBarcode = i;
		}
		
		if (count > averageSpacing) {
			*endBarcode = localEndBarcode;
			break;
		}
	}
	//NSLog(@"beginning: %d end %d", *startBarcode, *endBarcode);
}


- (void)getTopMask:(int *)topMask bottomMask:(int *)bottomMask forLine:(int *)pixelLineArray start:(int)startBarcode end:(int)endBarcode{
	
	*bottomMask = 255; //lowestPeak
	*topMask = 0; //highestValley
	
	BOOL lookformax = YES;
	int mn = 256, mx = -256;
	//int mnpos, mxpos;
	int delta = 0; 
	int index = startBarcode;
	int peakNumber = 0;
	//int i;
	
	
	while (index < endBarcode && peakNumber < 69) {
		int current = pixelLineArray[index];
		
		if (current > mx) {
			mx = current; 
			//mxpos = index;
		}
		if (current < mn) {
			mn = current; 
			//mnpos = index;
		}
		
		
		if (lookformax) {
			
			
			//peak
			if (current < (mx - delta)) {
				
				if (current < *bottomMask)
					*bottomMask = current;
				
				
				lookformax = NO;
				
				mn = current;
				//mnpos = index;
				
			}
		}
		else {
			
			//valley
			if (current > (mn + delta)) {
				
				if (current > *topMask)
					*topMask = current;
				
				mx = current;
				//mxpos = index;
				lookformax = YES;
			}
		}
		
		index++;
	}
	
	*--bottomMask;
	*++topMask;
}

//given an array of pixel values and the first derivative as well as the area of the barcode it goes throw determining the bar lengths.
- (void)getBars:(int [62])barsArrayOneDimension forLine:(int *)pixelLineArray derivative:(int *)lineDerivativeArray start:(int)startBarcode end:(int)endBarcode top:(int)topMask bottom:(int)bottomMask {
	
	
	//NSLog(@"%d %d %d %d" ,startBarcode, endBarcode, topMask, bottomMask);
	float barWidths[70];
	int i, sectionThickness = 0;
	BOOL blackSection = YES;
	int nextSection = 0;
	BOOL binaryValueOfPixel;
	float barWidth = (endBarcode - startBarcode) / 96.0;  //What a single bar width should be
	
#if DEBUG
	//NSBezierPath *blackPath = [NSBezierPath bezierPath];
#endif
	
	//For the entire area of the barcode
	
	for (i = startBarcode; i < endBarcode && nextSection < 62; i++) {
		
		//NSLog(@"%d %d" ,i, nextSection);
		
		// Determine the binaryValue of the pixel
		binaryValueOfPixel = [self getBinaryValueForPixel:pixelLineArray[i] derivativeForPixel:lineDerivativeArray[i] top:topMask bottom:bottomMask];
		
		//black pixel (is really a white pixel and it's counting backwards, but since it does not label the pixel color it does not matter)
		if (binaryValueOfPixel == NO) {
			
			// We are not in a black section, determine the previous white bar width
			if (!blackSection) {
				
				//Get bar width
				int stripes = getNumberStripesEAN(sectionThickness, barWidth);
				
				barWidths[nextSection] = sectionThickness;
				
				barsArrayOneDimension[nextSection] = stripes;
				nextSection++;
				
				sectionThickness = 0;
			}
			
			//set black section
			blackSection = YES;
			sectionThickness++;
		}
		//White pixel
		else {
			
#if DEBUG
			//[blackPath moveToPoint:NSMakePoint(i, 255)];
			//[blackPath lineToPoint:NSMakePoint(i, 0)];
#endif	
			
			//We are not in a white section, determine the previous black bar width
			if (blackSection) {
				
				//Get bar width
				int stripes = getNumberStripesEAN(sectionThickness, barWidth);
				
				barWidths[nextSection] = sectionThickness;
				
				barsArrayOneDimension[nextSection] = stripes;
				nextSection++;
				
				sectionThickness = 0;
			}
			
			//set white section
			blackSection = NO;
			sectionThickness++;
			
		}
	}
	
	/*
	 #if DEBUG
	 //Draw a barcode by averaging the spacing between the peaks and the valleys
	 [barcodeView setPath:blackPath withColor:[NSColor blackColor]];
	 [barcodeView display];
	 #endif
	 */
}



// Determines if a pixel is black or white depending on the mask provided and if not on the first derivative
// A possability is changing the first derivative to the second derivative to be more precise about the midpoint
// or even a simple midpoint calculation between the peak and the valley
- (BOOL)getBinaryValueForPixel:(int)pixelValue derivativeForPixel:(int)derivative top:(int)topMask bottom:(int)bottomMask {
	
	if (pixelValue > topMask) {
		return YES;
	}
	else if (pixelValue < bottomMask) {
		return NO;
	}
	else {
		
		//use derivative
		if (derivative < 0) {
			return YES;
		}
		else {
			return NO;
		}
	}	
}



#pragma mark -

//given a array of bar thickness it read four bars at a time and determines the number based on the encoding 
- (void)readBars:(int [62])lastBinaryData {
	
	int k, i;
	
	if (lastBinaryData[0] == 1 && lastBinaryData[1] == 1 && lastBinaryData[2] == 1 && lastBinaryData[3] == 1) {
		i = 4;
		/*}
		 else {
		 i = 3;
		 }
		 */
		
		//First number has to be odd encoded			
		[self getNumberForLocation:&lastBinaryData[i]  encoding:MKLeftHandEncodingOdd location:0];
		if (numberArray[0][0] != NOT_FOUND)
			numberOfDigitsFound++;
		
		
		//First Section left hand encoding even or odd
		for (i = i +4, k = 1; i < 28; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKLeftHandEncodingBoth location:k];
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
			
		}
		
		//Second section all right hand encoding
		for (i = i+5; i < 57; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
		}
	} /*
	 else {
	 //[self clearNumberArray:numberArray];
	 }
	 */
	
}


//given a array of bar thickness it read four bars at a time and determines the number based on the encoding 
- (void)readBarsWithShift:(int [62])lastBinaryData {
	
	int i, k;
	
	//Starts with 0101
	//find starter bar 1111 should be in the first 7
	for (i = 0; i < 5; i++) {
		if (lastBinaryData[i] == 1 && lastBinaryData[i+1] == 1 && lastBinaryData[i+2] == 1 && lastBinaryData[i+3] != 1) {
			break;	
		}
	}
	//NSLog(@"Begin Position: %d", i);
	
	
	
	
	if (i < 5)  {
		i = i + 4;
		
		//First number has to be odd encoded			
		[self getNumberForLocation:&lastBinaryData[i]  encoding:MKLeftHandEncodingOdd location:0];
		if (numberArray[0][0] != NOT_FOUND)
			numberOfDigitsFound++;
		
		
		//First Section left hand encoding even or odd
		for (i = i +4, k = 1; i < 28; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKLeftHandEncodingBoth location:k];
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
			
		}
		
		//Second section all right hand encoding
		for (i = i+5; i < 57; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
		}
	} /*
	 else {
	 //[self clearNumberArray:numberArray];
	 }
	 */
	
}


- (void)readBarsBackward:(int [62])lastBinaryData {
	
	int i, k;
	
	
	
	//find starter bar at back
	for (i = 61; i > 54; i--) {
		if ((lastBinaryData[i-3] == 1 && lastBinaryData[i-2] == 1 && lastBinaryData[i] == 0) ||  (lastBinaryData[i-3] == 1 && lastBinaryData[i-2] == 1 && lastBinaryData[i -1] == 1)) {
			break;	
		}
	}
	i = i - 3;
	//NSLog(@"footer Position: %d", i);
	
	if (i > 51) {
		//Second section all right hand encoding
		for (i = i - 4, k = 11; i > 0 && k > 5; i = i - 4, k--) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
		}
		
		/*
		 //First Section left hand encoding even or odd
		 for (; i > 0 && k > 0; i = i - 4, k--) {
		 
		 [self getNumberForLocation:&lastBinaryData[i] encoding:MKLeftHandEncodingBoth location:k];
		 
		 if (numberArray[0][k] != NOT_FOUND)
		 numberOfDigitsFound++;
		 }
		 
		 
		 //First number has to be odd encoded	
		 if (i > 4) {
		 [self getNumberForLocation:&lastBinaryData[i-4]  encoding:MKLeftHandEncodingOdd location:0];
		 if (numberArray[0][0] != NOT_FOUND)
		 numberOfDigitsFound++;
		 }
		 */
	}
	
}

// Given an array of bar lengths an index to begin the scan,  it scans the next four bars and determines the number
// based on the UPC/EAN encoding
// For more info check out: http://www.barcodeisland.com/ean13.phtml
- (void)getNumberForLocation:(int *)anArray encoding:(int)encodingType location:(int)numberIndex {
	
	//All 6 numbers on the right hand of the code have a single encoding
	if (encodingType == MKRightHandEncoding) {
		//numberArray[1][numberIndex] = 0;
		
		if (anArray[0] == 3 && anArray[1]  == 2 && anArray[2] == 1 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 2 && anArray[2] == 2 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 1;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 1 && anArray[2] == 2 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 2;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 4 && anArray[2] == 1 && anArray[3] == 1)
		{
			numberArray[0][numberIndex] = 3;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 3 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 4;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 2 && anArray[2] == 3 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 5;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 4) 
		{
			numberArray[0][numberIndex] = 6;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 3 && anArray[2] == 1 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 7;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 2 && anArray[2] == 1 && anArray[3] == 3) 
		{
			numberArray[0][numberIndex] = 8;
			return;
		}
		else if (anArray[0] == 3 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 9;
			return;
		}
		
		numberArray[0][numberIndex] = NOT_FOUND;
		return;
		
	}
	
	//the first 6 numbers on the left hand has two encodings that allow it to determine the 13 number for EAN numbers
	
	//odd parity
	if (anArray[0] == 3 && anArray[1]  == 2 && anArray[2] == 1 && anArray[3] == 1) //isEqualToString:@"0001101"])
	{
		numberArray[0][numberIndex] = 0;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 2 && anArray[1]  == 2 && anArray[2] == 2 && anArray[3] == 1) //isEqualToString:@"0011001"])
	{
		numberArray[0][numberIndex] = 1;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 2 && anArray[1]  == 1 && anArray[2] == 2 && anArray[3] == 2) //isEqualToString:@"0010011"])
	{
		numberArray[0][numberIndex] = 2;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 4 && anArray[2] == 1 && anArray[3] == 1) //isEqualToString:@"0111101"])
	{
		numberArray[0][numberIndex] = 3;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 3 && anArray[3] == 2) //isEqualToString:@"0100011"])
	{
		numberArray[0][numberIndex] = 4;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 2 && anArray[2] == 3 && anArray[3] == 1) //isEqualToString:@"0110001"])
	{
		numberArray[0][numberIndex] = 5;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 4) //isEqualToString:@"0101111"])
	{
		numberArray[0][numberIndex] = 6;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 3 && anArray[2] == 1 && anArray[3] == 2) //isEqualToString:@"0111011"])
	{
		numberArray[0][numberIndex] = 7;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 1 && anArray[1]  == 2 && anArray[2] == 1 && anArray[3] == 3) //isEqualToString:@"0110111"])
	{
		numberArray[0][numberIndex] = 8;
		numberArray[1][numberIndex] = 1;
		return;
	}
	else if (anArray[0] == 3 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 2) //isEqualToString:@"0001011"])
	{
		numberArray[0][numberIndex] = 9;
		numberArray[1][numberIndex] = 1;
		return;
	}
	
	
	//even parity
	if (encodingType == MKLeftHandEncodingBoth) {
		if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 2 && anArray[3] == 3) 
		{
			numberArray[0][numberIndex] = 0;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 2 && anArray[2] == 2 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 1;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 2 && anArray[2] == 2 && anArray[3] == 2) 
		{
			numberArray[0][numberIndex] = 2;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 1 && anArray[2] == 4 && anArray[3] == 1)
		{
			numberArray[0][numberIndex] = 3;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 3 && anArray[2] == 1 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 4;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 1 && anArray[1]  == 3 && anArray[2] == 2 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 5;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 4 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 6;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 1 && anArray[2] == 3 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 7;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 3 && anArray[1]  == 1 && anArray[2] == 2 && anArray[3] == 1) 
		{
			numberArray[0][numberIndex] = 8;
			numberArray[1][numberIndex] = 0;
			return;
		}
		else if (anArray[0] == 2 && anArray[1]  == 1 && anArray[2] == 1 && anArray[3] == 3) 
		{
			numberArray[0][numberIndex] = 9;
			numberArray[1][numberIndex] = 0;
			return;
		}
	}
	
	
	// Code could be added here if a number is not found, then check the neighbours and see if they include a large white or black bar that might
	// throw the bar thickness of for this section and correct for that error 
	
	numberArray[0][numberIndex] = NOT_FOUND;
}


//Given a number of consecutive equal binary values and the average thickness of single bar it returns the thickness of the bar
int getNumberStripesEAN(int number, double average) {
	double ratioToAverageThickness = number / average;
	if (ratioToAverageThickness < 1.5)
		return 1;
	else if (ratioToAverageThickness < 2.5)
		return 2;
	else if (ratioToAverageThickness < SEPARATION_VALUE_FOR_3_BARS)
		return 3;
	else 
		return 4;
	
}


- (BOOL)calculateFirstNumberFromOddEvenParity:(char [7])aParitySection {
	
#if DEBUG
	//NSLog(@"%d %d %d %d %d %d" , aParitySection[0], aParitySection[1], aParitySection[2], aParitySection[3], aParitySection[4], aParitySection[5]);
	//NSLog(@"%d", aParitySection[6]);
#endif DEBUG
	
	
	//first build the first number from odd even parity and store it index 6 of the odd even array [1][6]
	if (aParitySection[1] == 1) { // odd
		if (aParitySection[2] == 1)  {  // odd
			if (aParitySection[3] == 1 || aParitySection[4] == 1 || aParitySection[5] == 1) //odd odd odd
				aParitySection[6] = 0;			//12 digit UPC first number is 0
			else
				return NO;
		}
		else if (aParitySection[2] == 0) { // odd even 
			if (aParitySection[3] == 1)  { // odd 
				if (aParitySection[4] == 0 || aParitySection[5] == 0) //even even
					aParitySection[6] = 1;	
				else
					return NO;
			}
			else if (aParitySection[3] == 0) { //odd even even
				if (aParitySection[4] == 1)  { // odd 
					if (aParitySection[5] == 0) //even
						aParitySection[6] = 2;	
					else
						return NO;
				}
				else if (aParitySection[4] == 0) {// even
					if (aParitySection[5] == 1) //odd
						aParitySection[6] = 3;	 
					else
						return NO;
				}
			}
		}
	}
	else if (aParitySection[1] == 0) {
		
		if (aParitySection[2] == 1)  {  // even odd
			if (aParitySection[3] == 1)  {  //odd
				if (aParitySection[4] == 0 || aParitySection[5] == 0) //even even
					aParitySection[6] = 4;
				else
					return NO;
			}
			else if (aParitySection[3] == 0) {
				if (aParitySection[4] == 1)  { // even odd even odd 
					if (aParitySection[5] == 0) //even
						aParitySection[6] = 7;	
					else
						return NO;
				}
				else if (aParitySection[4] == 0) {// even odd even even
					if (aParitySection[5] == 1) //odd
						aParitySection[6] = 8;	 
					else
						return NO;
				}
			}
		}
		else if (aParitySection[2] == 0) {
			if (aParitySection[3] == 1)  {  
				if (aParitySection[4] == 1)  { // even even odd odd 
					if (aParitySection[5] == 0) // even
						aParitySection[6] = 5;	
					else
						return NO;
				}
				else if (aParitySection[4] == 0) {// even even odd even
					if (aParitySection[5] == 1) //odd
						aParitySection[6] = 9;	
					else
						return NO;
					
				}
			}
			else if (aParitySection[3] == 0) {
				// even even even
				if (aParitySection[4] == 1 || aParitySection[5] == 1) //odd odd
					aParitySection[6] = 6;
				else
					return NO;
			}
		}
	}
	
#if DEBUG
	//NSLog(@"%d", aParitySection[6]);
#endif DEBUG
	
	return YES;
}


- (BOOL)parityDigitFromNumber:(char [3][12])aNumberArray {
	//first build the first number from odd even parity and store it index 6 of the odd even array [1][6]
	if (aNumberArray[1][1] == 1) { 
		if (aNumberArray[1][2] == 1)  {  // odd odd
			aNumberArray[1][6] = 0;			//12 digit UPC first number is 0
			if (aNumberArray[1][3] != 1 || aNumberArray[1][4] != 1 || aNumberArray[1][5] != 1) //check the rest
				return NO;
		}
		else {
			if (aNumberArray[1][3] == 1)  {  
				aNumberArray[1][6] = 1;	// odd even odd
				if (aNumberArray[1][4] != 0 || aNumberArray[1][5] != 0) //check the rest
					return NO;
			}
			else {
				if (aNumberArray[1][4] == 1)  {  
					aNumberArray[1][6] = 2;	// odd even even odd
					if (aNumberArray[1][5] != 0) //check the rest
						return NO;
				}
				else {
					aNumberArray[1][6] = 3;	 // odd even even even
					if (aNumberArray[1][5] != 1) //check the rest
						return NO;
				}
			}
		}
	}
	else {
		
		if (aNumberArray[1][2] == 1)  {  // even odd
			if (aNumberArray[1][3] == 1)  {  
				aNumberArray[1][6] = 4;	// even odd odd 
				if (aNumberArray[1][4] != 0 || aNumberArray[1][5] != 0) //check the rest
					return NO;
			}
			else {
				if (aNumberArray[1][4] == 1)  {  
					aNumberArray[1][6] = 7;	// even odd even odd
					if (aNumberArray[1][5] != 0) //check the rest
						return NO;
				}
				else {
					aNumberArray[1][6] = 8;	 // even odd even even
					if (aNumberArray[1][5] != 1) //check the rest
						return NO;
				}
			}
		}
		else {
			if (aNumberArray[1][3] == 1)  {  
				if (aNumberArray[1][4] == 1)  {  
					aNumberArray[1][6] = 5;	// even even odd odd
					if (aNumberArray[1][5] != 0) //check the rest
						return NO;
				}
				else {
					aNumberArray[1][6] = 9;	// even even odd even
					if (aNumberArray[1][5] != 1) //check the rest
						return NO;
					
				}
			}
			else {
				aNumberArray[1][6] = 6;	// even even even
				if (aNumberArray[1][4] != 1 || aNumberArray[1][5] != 1) //check the rest
					return NO;
			}
		}
	}
	
	//check digit
	// the first digit is in [1][6]
	// 11 total count becasue we want to leave the check digit out of the calculation
	int i, checkDigitSum = aNumberArray[1][6];
	for (i = 0; i < 11; i++) {
		if ( i % 2)
			checkDigitSum = checkDigitSum + aNumberArray[0][i];
		else
			checkDigitSum = checkDigitSum + (aNumberArray[0][i] * 3);
		
	}
	
	//NSLog(@"check Sum %d", checkDigitSum);
	
	checkDigitSum = 10 - (checkDigitSum % 10);
	
	//NSLog(@"check %d == %d", checkDigitSum, aNumberArray[0][11]);
	
	//OLD WAY if (checkDigitSum == aNumberArray[0][11] || (checkDigitSum == 10 && aNumberArray[0][11] == 0))
	
	checkDigitSum = checkDigitSum % 10;
	if (checkDigitSum == aNumberArray[0][11])
		return YES;
	
	return NO;
}



// Compares two barcode numbers and merges them intelligently. That way not wasting previous scans. It keeps a table of how sure it is about a number depending on how many times that number has appeared at that location
- (BOOL)compareAgainstPreviousScans:(char [3][12])aNumberArray previous:(char [3][12])previousNumberArray {
	
	int i;
	BOOL completeNumber = YES;
	
	for (i = 0; i < 12; i++) {
		//check other results to fill in ?
		if (previousNumberArray[0][i] != NOT_FOUND ) {			
			//Number are equal increase sureness until limit
			if (previousNumberArray[0][i] == aNumberArray[0][i]) {
				if (previousNumberArray[2][i] != SURENESS_LIMIT)
					++previousNumberArray[2][i];
			}
			else {
				
				if (aNumberArray[0][i] == NOT_FOUND) {
					// A aNumberArray is never used so no need to fill it
					//aNumberArray[0][i] = previousNumberArray[0][i];
					//aNumberArray[1][i] = previousNumberArray[1][i];
				}
				else {
					// decide on the sureness index which one stays
					// if the previous number sureness ahs dipped under 0 then replace it with the current number 
					// else if the current number sureness is higher than previous number then replace previous number as well
					// subtract 1 from sureness as the numbers where not matching
					if (previousNumberArray[2][i] < 0) {
						previousNumberArray[0][i] = aNumberArray[0][i];
						previousNumberArray[1][i] = aNumberArray[1][i];	
						previousNumberArray[2][i] = 0;
					}
					else {
						if (previousNumberArray[2][i] < aNumberArray[0][i]) {
							previousNumberArray[0][i] = aNumberArray[0][i];
							//previousNumberArray[1][i] = aNumberArray[1][i];	// We leave this line out as we don't want to carry the surenees from a single bad scan
						}
						--previousNumberArray[2][i];
					}
				}
			}
		}
		else {
			if (aNumberArray[0][i] == NOT_FOUND ) {
				completeNumber = NO;
			}
			else {
				previousNumberArray[0][i] = aNumberArray[0][i];	
				previousNumberArray[1][i] = aNumberArray[1][i];	
				previousNumberArray[2][i] = 0;
			}
		}
		
	}
	
	return completeNumber;
}



#pragma mark -
#pragma mark Frequency

- (void)addNumber:(char [3][12])aNumberArray toFrequencyMatrix:(char[10][13])aFrequencyMatrix {
	int i;
	int firstDigit = aNumberArray[1][6];
	if (firstDigit != NOT_FOUND)
		aFrequencyMatrix[firstDigit][0]++;
	
	for (i = 0; i < 12; i++) {
		int nextDigit = aNumberArray[0][i];
		if (nextDigit != NOT_FOUND)
			aFrequencyMatrix[nextDigit][i+1]++;
	}
}

- (void)addParity:(char [3][12])aNumberArray toParityMatrix:(char[2][6])aParityMatrix {
	int i;
	for (i = 0; i < 6; i++) {
		int nextDigit = aNumberArray[1][i];
		if (nextDigit == 0)
			aParityMatrix[0][i]++;
		else if (nextDigit == 1)
			aParityMatrix[1][i]++;
	}
}


- (void)addFrequencyMatrix:(char[10][13])aFrequencyMatrix toFrequencyMatrix:(char[10][13])anotherFrequencyMatrix {
	int i, j;
	for (i = 0; i < 10; i++) {
		for (j = 0; j < 13; j++) {
			anotherFrequencyMatrix[i][j] += aFrequencyMatrix[i][j];
		}
	}
}


- (int)parityFromFrequency:(char[2][6])aParityMatrix {
	int j;
	char parityArray[7] = {0};
	parityArray[6] = NOT_FOUND;
	for (j = 1; j < 6; j++) { //First number is always odd, so don't use it
		if (aParityMatrix[0][j] > aParityMatrix[1][j])
			parityArray[j] = 0;
		else if (aParityMatrix[1][j] != 0) //si hay valor entonces odd
			parityArray[j] = 1;
		else
			parityArray[j] = NOT_FOUND;
	}
	
	//NSLog(@"Parity digit: %d", parityArray[6]);
	[self calculateFirstNumberFromOddEvenParity:parityArray];
	return parityArray[6];
}


- (NSString *)numberFromFrequencyMatrix:(char [10][13])aFrequencyMatrix {
	NSMutableString *numberString = [[NSMutableString alloc] init];	
	
	int i, j;
	for (j = 0; j < 13; j++) {
		int highestNumber = NOT_FOUND, highestCount = 0;
		for (i = 0; i < 10; i++) {
			if (aFrequencyMatrix[i][j] != 0 && aFrequencyMatrix[i][j] > highestCount) {
				highestCount = aFrequencyMatrix[i][j];
				highestNumber = i;
			}
		}
		if (highestNumber == NOT_FOUND)
			[numberString appendString:@"?"];
		else
			[numberString appendString:[NSString stringWithFormat:@"%d", highestNumber]];
	}	
	//NSLog(@"%@", numberString);
	return [numberString autorelease];
}


- (BOOL)numberFromFrequencyMatrix:(char [10][13])aFrequencyMatrix toArray:(char [13])anEANArray {
	
	int i, j;
	for (j = 0; j < 13; j++) {
		int highestNumber = NOT_FOUND, highestCount = 0;
		for (i = 0; i < 10; i++) {
			if (aFrequencyMatrix[i][j] != 0 && aFrequencyMatrix[i][j] > highestCount) {
				highestCount = aFrequencyMatrix[i][j];
				highestNumber = i;
			}
		}
		if (highestNumber == NOT_FOUND) {
			//anEANArray[j] = NOT_FOUND;
			return NO;
		}
		else
			anEANArray[j] = highestNumber;
	}	
	
	return YES;		
}

#pragma mark -

- (BOOL)isValidCheckDigit:(char [13])anEANArray {
	int i, checkDigitSum = 0;
	for (i = 0; i < 12; i++) {
		if ( i % 2 == 0)
			checkDigitSum = checkDigitSum + anEANArray[i];
		else
			checkDigitSum = checkDigitSum + (anEANArray[i] * 3);
	}
	
	//NSLog(@"check Sum %d", checkDigitSum);
	
	checkDigitSum = 10 - (checkDigitSum % 10);
	checkDigitSum = checkDigitSum % 10;
	
	//NSLog(@"check %d == %d", checkDigitSum, anEANArray[12]);
	
	if (checkDigitSum == anEANArray[12])
		return YES;
	return NO;
}


- (NSString *)barcodeFromEANArray:(char [13])anEANArray {
	
	NSMutableString *numberString = [NSMutableString string];	
	
	int i;
	for (i = 0; i < 13; i++) {
		if (anEANArray[i] == NOT_FOUND)
			[numberString appendString:@"?"];
		else
			[numberString appendString:[NSString stringWithFormat:@"%d", anEANArray[i]]];
	}
	return numberString;
}


// Turns a C array of a number into a string
// Sections can be uncommented to print more info about the number
- (NSString *)barcodeFromArray:(char [3][12])aNumberArray {
	
	NSMutableString *numberString = [NSMutableString string];	
	//NSMutableString *sureness = [NSMutableString string];	
	//NSMutableString *evenODD = [NSMutableString string];	
	
	//It's a UPC don't include the leading zero from the EAN
	if (aNumberArray[1][6] != 0)
		[numberString appendFormat:@"%d", aNumberArray[1][6]];
	
	int i;
	for (i = 0; i < 12; i++) {
		int numberValue = aNumberArray[0][i];
		if (numberValue == NOT_FOUND)
			[numberString appendString:@"?"];
		else
			[numberString appendString:[NSString stringWithFormat:@"%d", numberValue]];
		
		//[sureness appendString:[NSString stringWithFormat:@"%d ", aNumberArray[2][i]]];
		//[evenODD appendString:[NSString stringWithFormat:@"%d", aNumberArray[1][i]]];
	}
	
	//NSLog(@"Number : %@", numberString);
	//NSLog(@"Surenes: %@ ", sureness);
	//NSLog(@"evenOdd: %@ ", evenODD);
	
	return numberString;	
}


- (void)clearGlobalFrequency {
	int i, j;
	for (i = 0; i < 10; i++) {
		for (j = 0; j < 13; j++) {
			globalFrequencyMatrix[i][j] = 0;
		}
	}	
	frameCount = 0;
	
	//[self clearNumberArray:previousNumberGlobalArray];
}


/*
 - (void)clear:(id)sender {
 int i;
 for (i = 0; i < 12; i++) {
 previousNumberGlobalArray[0][i] = NOT_FOUND;
 previousNumberGlobalArray[2][i] = 0;
 }
 previousNumberGlobalArray[1][6] = NOT_FOUND;
 
 //NSLog(@"Clear: %@", [self barcodeFromArray:previousNumberLocalArray]);
 }
 */

- (void)clearNumberArray:(char [3][12])aNumberArray {
	int i;
	for (i = 0; i < 12; i++) {
		aNumberArray[0][i] = NOT_FOUND;
		aNumberArray[1][i] = NOT_FOUND;
		aNumberArray[2][i] = 0;
	}	
}




#pragma mark -
#pragma mark sharedInstance

static MyBarcodeScanner *sharedInstance = nil;

+ (MyBarcodeScanner *)sharedInstance {	
	if (sharedInstance == nil) {
		//Make mirrored the default now, with the smooth Core Image Mirror
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"Mirror iSight"]];
		
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}
- (void)release {
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX;
}
+ (id)allocWithZone:(NSZone *)zone {
	if (sharedInstance == nil) {
		return [super allocWithZone:zone];
	}
    return sharedInstance;
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)autorelease {
    return self;
}

#pragma mark Accessors

- (void)setDelegate:(id)aDelegate {
	[delegate release];
	delegate = [aDelegate retain];
}

- (void)setStaysOpen:(BOOL)stayOpenValue {
	stayOpen = stayOpenValue;
}

- (void)setMirrored:(BOOL)mirroredValue {
	mirrored = mirroredValue;
	[previewView setMirrored:mirroredValue];
}

- (void)setHighResiSight:(BOOL)aBool {
	newHighResiSight = aBool;
}


#pragma mark -
#pragma mark Debug only

#ifdef DEBUG
- (NSString *)stringFromBars:(int [62])aNumberArray {		
	
	NSMutableString *numberString = [NSMutableString string];	
	int i;
	for (i = 0; i < 62; i++) {
		[numberString appendString:[NSString stringWithFormat:@"%d ", aNumberArray[i]]];
	}
	return numberString;
}


- (void)setScanBarcode:(BOOL)aBoolValue {
	scanBarcode = aBoolValue;
}


- (BOOL)checkCheckDigit:(char [3][12])aNumberArray {	
	
	//NSLog(@"numberToCheck %@", [NSString stringWithFormat:@"%d%@", aNumberArray[1][6], [self barcodeFromArray:aNumberArray]]);
	
	
	//check digit
	// the first digit is in [1][6]
	// 11 total count becasue we want to leave the check digit out of the calculation
	int i, checkDigitSum = aNumberArray[1][6];
	for (i = 0; i < 11; i++) {
		if ( i % 2)
			checkDigitSum = checkDigitSum + aNumberArray[0][i];
		else
			checkDigitSum = checkDigitSum + (aNumberArray[0][i] * 3);
		
	}
	
	//NSLog(@"check Sum %d", checkDigitSum);
	
	checkDigitSum = 10 - (checkDigitSum % 10);
	
	//NSLog(@"check %d == %d", checkDigitSum, aNumberArray[0][11]);
	
	//OLD WAY if (checkDigitSum == aNumberArray[0][11] || (checkDigitSum == 10 && aNumberArray[0][11] == 0))
	
	checkDigitSum = checkDigitSum % 10;
	if (checkDigitSum == aNumberArray[0][11])
		return YES;
	
	return NO;
}


- (void)printFrequencyMatrix:(char [10][13])aFrequencyMatrix {
	NSMutableString *numberString = [NSMutableString string];	
	[numberString appendString:@"\n"];
	
	int i, j;
	for (i = 0; i < 10; i++) {
		for (j = 0; j < 13; j++) {
			[numberString appendString:[NSString stringWithFormat:@"%d\t", aFrequencyMatrix[i][j]]];
		}
		[numberString appendString:@"\n"];
	}	
	NSLog(@"%@", numberString);
}


- (void)printParityMatrix:(char[2][6])aParityMatrix {
	NSMutableString *numberString = [NSMutableString string];	
	[numberString appendString:@"Parity\n"];
	
	int i, j;
	for (i = 0; i < 2; i++) {
		for (j = 0; j < 6; j++) {
			[numberString appendString:[NSString stringWithFormat:@"%d\t", aParityMatrix[i][j]]];
		}
		[numberString appendString:@"\n"];
	}	
	NSLog(@"%@", numberString);
}


#endif

#ifdef DEBUG
#pragma mark -
#pragma mark Experimental

- (void)processPixelBufferOld:(CVPixelBufferRef)pixelBuffer {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	/*	This is where it's being asked to process the pixel buffer for a barcode. Any other algorithms for 
	 searching for the barcode should be inserted around here.  */
	
	
	CVReturn possibleError = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	if (possibleError) {
		DLog(@"Error locking pixel bufffer old, when looking for barcode.");
		return;
	}
	Ptr pixelBufferBaseAddress = (Ptr)CVPixelBufferGetBaseAddress(pixelBuffer); 
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);  //bytes per line
	//size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer); 
	//NSLog(@"%d x %d",bytesPerRow/4, bufferHeight);
	
	/*
	 //Only needed when the OPenGL bufer comes empty the first time
	 if (bytesPerRow == 0) {
	 [pool release];
	 return;
	 }
	 */
	
	int i, j; 
	int bottomMask, topMask;
	Ptr firstRowToScan; //RELEVANT_SECTION
	//if (newHighResiSight) // move to the center and for high res center width wise as well
	//	firstRowToScan = pixelBufferBaseAddress + FIRST_LINE_SCAN_HIGH;// + bytesPerRow / 2;
	//else
	firstRowToScan = pixelBufferBaseAddress + firstScanOffset;
	int greenScalePixels[640];  //The value of the green pixel 0 - 255
	int greenDerivative[640];
	int xAxisCenterPoint = 320 - (NUMBER_OF_LINES_SCANNED / 2 * SPACING_BETWEEN_CENTERS); //initalize x center point
	
	//[vide setGoodScan:NO];
	[previewView setGoodScan:NO];
	BOOL noMissingNumbers = NO;  //check local number as all digits where deciphered
	
	//clear local number
	for (i = 0; i < 12; i++) {
		previousNumberLocalArray[0][i] = NOT_FOUND;
		previousNumberLocalArray[2][i] = 0;
	}
	
	//Do a number of rows from the same image centered in the middle with varying x axis center points
	for (i = 0; i < NUMBER_OF_LINES_SCANNED; i++) {
		
		//get green pixels for row
		//[self getGreenFromRGB:firstRowToScan + (bytesPerRow * i * SPACING_BETWEEN_SCAN_LINE) to:greenScalePixels];
		[self getLuminanceFrom2vuy:firstRowToScan + (bytesPerRow * i * SPACING_BETWEEN_SCAN_LINE) to:greenScalePixels];
		
		
		//first derivative
		for (j = 0; j < 640; j++) {
			greenDerivative[j] = greenScalePixels[j + 1] - greenScalePixels[j];
		}
		
		//Find barcode area and information about max and min values of the pixels
		int startBarcode = 0, endBarcode = 639, minValue = 255, maxValue = 0;
		[self findStartOld:&startBarcode end:&endBarcode forLine:greenScalePixels derivative:greenDerivative centerAt:xAxisCenterPoint min:&minValue max:&maxValue];
		
		//move x center forward for the next row
		xAxisCenterPoint = xAxisCenterPoint + SPACING_BETWEEN_CENTERS;
		
		// A real barcode will not reach to the edge of the frame
		// if the end goes to the edge of the frame do not process
		if (endBarcode != 639) {
			
			
			
#ifdef DEBUG
			//Draw a green line of the green pixel values
			NSBezierPath *aPath = [NSBezierPath bezierPath];
			[aPath moveToPoint:NSMakePoint(0, greenScalePixels[0])];
			for (j = 1; j < 640; j++)
				[aPath lineToPoint:NSMakePoint(j, greenScalePixels[j])];
			[graphView setGreenPath:aPath];
			
			//Draw a blue line for the area of the barcode
			
			NSBezierPath *barcodeAreaPath = [NSBezierPath bezierPath];
			[barcodeAreaPath moveToPoint:NSMakePoint(startBarcode, greenScalePixels[startBarcode])];
			for (j = startBarcode; j < endBarcode; j++)
				[barcodeAreaPath lineToPoint:NSMakePoint(j, greenScalePixels[j])];
			[graphView setBluePath:barcodeAreaPath];
#endif DEBUG
			
			//return;
			
			/*	This is a route is in development.
			 Locating only the peaks of the barcode and infering the barcode from the peaks.
			 Although the peaks contain less information they are not affected by edge blurring
			 So using the space between peaks and statistical analysis could lead to the barcode
			 Normalized distance between peaks should reflect the following:
			 1 would mean it's 1 black stripe and 1 white stripe
			 1.5 would mean it's 1 black and 2 white or 2 black and 1 white;
			 2  =  1-3, 2-2, 3-1
			 2.5  = 1-4, 2-3, 3-2, 1-4
			 Using the next sorounding distances it can tell which possability it should be.
			 Maybe even using the distance between peak and valley might be better
			 
			 int peakArray[62] = {0};
			 [self getPeakDistance:peakArray forLine:greenScalePixels start:startBarcode end:endBarcode];
			 return;
			 */
			
			int differenceInRange =  maxValue - minValue;
			
			// repeat for different values of the masks
			// the masks were determined via trial and error
			for (j =0; j < 5; j++) {
				
				int barsArray[62] = {0};
				
				if (j == 0) {
					bottomMask = minValue + (differenceInRange * 0.34);
					topMask = maxValue - (differenceInRange * 0.44);
				}
				else if (j == 1) {
					bottomMask = minValue + (differenceInRange * 0.15);
					topMask = maxValue - (differenceInRange * 0.4);
				}
				else if (j == 2) {
					bottomMask = minValue + (differenceInRange * 0.3);
					topMask = maxValue - (differenceInRange * 0.3);
				}
				else if (j == 3) {
					bottomMask = minValue + (differenceInRange * 0.18);
					topMask = maxValue - (differenceInRange * 0.5);
				}
				
				/*  //These masks are not very useful 
				 else if (j == 4) {
				 bottomMask = minValue + (differenceInRange * 0.39);
				 topMask = maxValue - (differenceInRange * 0.25);
				 }
				 else if (j == 5) {
				 bottomMask = minValue + (differenceInRange * 0.32);
				 topMask = maxValue - (differenceInRange * 0.17);
				 }
				 */
				
				else  {
					bottomMask = minValue + (differenceInRange * 0.1);
					topMask = maxValue - (differenceInRange * 0.25);
				}
				
				//Get the bar width information based on the mask
				[self getBars:barsArray forLine:greenScalePixels derivative:greenDerivative start:startBarcode end:endBarcode top:topMask bottom:bottomMask];
				
				//NSLog(@"bars %@", [self stringFromBars:barsArray]);
				
				//Try to read a number based on the bars widths
				numberOfDigitsFound = 0;
				[self clearNumberArray:numberArray];
				[self readBars:barsArray];
				
				//NSLog(@"Scanned %@  local:%@  j:%d", [self barcodeFromArray:numberArray], [self barcodeFromArray:previousNumberLocalArray], j);
				
				// If 7 or more digits were read from the barcode then process number 
				// and add it to the local number 
				// Don't check the scanned number if it has 12 digits as it not verfied and it could lead to a lucky checksum and a wrong number
				if (numberOfDigitsFound >= MINIMUM_DIGITS_FOR_GOOD_SCAN) {
					//NSLog(@"j = %d %d", j, numberOfDigitsFound);
					//foundBarcodeArea = YES;	 //Tells the sequence grabber to draw the lines green as feedback to the user
					//[vide setGoodScan:YES];
					[previewView setGoodScan:YES];
					noMissingNumbers = [self compareAgainstPreviousScans:numberArray previous:previousNumberLocalArray];
					//[vide setScannedNumber:[self barcodeFromArray:previousNumberGlobalArray]];
				}
				
			}
		}
	}
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	
	
	/*	The compareAgainstPreviousScans: not only compares the numbers but builds how sure it is about the number based on previous
	 comparisons. There are two numbers that are built this way. The local number based on all scan lines and the different masks for each line.
	 And a global number based on all the local numbers for each frame.
	 */
	
	//check the local number if it has no missing numbers run the checksum
	if (noMissingNumbers) {
		if ([self parityDigitFromNumber:previousNumberLocalArray] ) {
			NSString *barcodeString = [self barcodeFromArray:previousNumberLocalArray];
			
			//NSLog(@"Found local OLD %@", barcodeString);
			[self foundBarcode:barcodeString];
			//[self performSelectorOnMainThread:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
			[pool release];
			return; //Otherwise it might sent another message with the global matches as well
		}
	}
	
	//NSLog(@"local %@", [self barcodeFromArray:previousNumberLocalArray]);
	
	//Add the local number to the global number and
	//check the global number if it has no missing numbers run the checksum
	if ([self compareAgainstPreviousScans:previousNumberLocalArray previous:previousNumberGlobalArray] == YES) {
		if ([self parityDigitFromNumber:previousNumberGlobalArray]) {
			NSString *barcodeString = [self barcodeFromArray:previousNumberGlobalArray];
			//NSLog(@"Found global OLD %@", barcodeString);
			[self foundBarcode:barcodeString];
			//[self performSelector:@selector(foundBarcode:) withObject:barcodeString afterDelay:0.0];
		}
	}
	
	[pool release];
	
	//NSLog(@"Global %@", [self barcodeFromArray:previousNumberGlobalArray]);
}



// Determine the area of the barcode by using the supplied center and determining the average change of direction
// As soon as something is below 1/4 of the variation in height for more than the average spacing time MULTIPLY_AVERAGE_SPACING_OLD, then the barcode ends
- (void)findStartOld:(int *)startBarcode end:(int *)endBarcode forLine:(int *)pixelLineArray derivative:(int *)lineDerivativeArray centerAt:(int)centerX min:(int *)minValue max:(int *)maxValue {
	
	int averageSpacing = 0, numberOfCurves = 0, spacingInThisRun = 0;
	int i, count, startScan = centerX - 40, endScan = centerX + 40;
	
	BOOL positive = YES;
	if (lineDerivativeArray[startScan] < 0)
		positive = NO;
	
	
	//Build the average spacing number and the variation in height from a smaple around the center
	for (i = startScan; i < endScan; i++) {
		
		if (*maxValue < pixelLineArray[i])
			*maxValue = pixelLineArray[i];
		else if (*minValue > pixelLineArray[i])
			*minValue = pixelLineArray[i];
		
		
		if (lineDerivativeArray[i] < 0) {
			if (positive) {
				positive = NO;
				averageSpacing = averageSpacing + spacingInThisRun;
				numberOfCurves++;
				spacingInThisRun = 0;
			}
			
		}
		else {
			if (!positive) {
				positive = YES;
				averageSpacing = averageSpacing + spacingInThisRun;
				numberOfCurves++;
				spacingInThisRun = 0;
			}
		}
		
		spacingInThisRun++;
	}
	
	//If there was a solid growing gradient with no curves then return
	if (numberOfCurves == 0)
		return;
	
	
	averageSpacing = (averageSpacing / numberOfCurves) * MULTIPLY_AVERAGE_SPACING_OLD;
	
	//NSLog(@"min %d max %d spacing: %d", *minValue, *maxValue, averageSpacing);
	int quarterHeight = ((*maxValue - *minValue) * 0.25);
	int bottomForth = *minValue + quarterHeight;
	int topForth = *maxValue - quarterHeight;
	
	//anything below oneForth for averageSpacing * MULTIPLY_AVERAGE_SPACING_OLD is the end of the barcode
	for (i = centerX, count = 0; i > 0; i--) {
		if (pixelLineArray[i] < bottomForth || pixelLineArray[i] > topForth) {
			count++;
		}
		else {
			count = 0;
			*startBarcode = i;
		}
		
		if (count > averageSpacing) {
			break;
		}
	}
	
	for (i = centerX, count = 0; i < 640; i++) {
		if (pixelLineArray[i] < bottomForth || pixelLineArray[i] > topForth) {
			count++;
		}
		else {
			count = 0;
			*endBarcode = i;
		}
		
		if (count > averageSpacing) {
			break;
		}
	}
	
	//NSLog(@"beginning: %d end %d", *startBarcode, *endBarcode);
}





- (void)getPeaksForLine:(int *)pixelLineArray start:(int)startBarcode end:(int)endBarcode peaks:(int [70][2])peakValleyInformation {
	
	
	int zeroDerivativeCloseToZero = 0;
	//BOOL lookForSlopes = NO;
	//int lookingForSlopeSign;
	
	int lowestPeak = 255, heighestPeak = 0, heighestValley = 0, lowestValley = 255;
	int barcodeThickness = endBarcode - startBarcode;
	float averageBarWidth = barcodeThickness / 95.0;
	//int peakValleyInformation[70][2] = {0};  //First row peak index, second height
	int mn = 256, mx = -256;
	//int mnpos, mxpos;
	int delta = 0; 
	//int delta = barcodeThickness / 100;  //Should be dependant on the width of the barcode
	int lookformax = YES;
	int index = startBarcode;
	int peakNumber = 0;
	int count = 0;
	//int i, j;
	NSBezierPath *aPath = [NSBezierPath bezierPath];
	NSBezierPath *valleyPath = [NSBezierPath bezierPath];
	//NSBezierPath *blackPath = [NSBezierPath bezierPath];
	
	/*
	 int newLine[640] = {0};
	 [self binarizeLine:pixelLineArray to:newLine start:startBarcode width:barcodeThickness];
	 
	 NSBezierPath *binaryPath = [NSBezierPath bezierPath];
	 for (j = 0; j < 640 ; j++) {
	 if (newLine[j] == BLACK_PIXEL) {
	 [binaryPath moveToPoint:NSMakePoint(j, 0)];
	 [binaryPath lineToPoint:NSMakePoint(j, 255)];
	 }
	 }
	 [barcodeView setPath:binaryPath withColor:[NSColor blackColor]];
	 return;
	 */
	
	
	while (index < endBarcode && peakNumber < 69) {
		int current = pixelLineArray[index];
		
		if (current > mx) {
			mx = current; 
			//mxpos = index;
		}
		if (current < mn) {
			mn = current; 
			//mnpos = index;
		}
		
		
		// Looking for small slopes that are small peaks
		int secondDerivative =  pixelLineArray[index + 1] - current;
		
		
		if (lookformax) {
			
			if (secondDerivative < 4) {
				zeroDerivativeCloseToZero = index;
			}
			else {
				if (zeroDerivativeCloseToZero != 0) {
					
					// Only add if the lest a bar width away from the previous peak, 
					//!!! should check against the upcoming peak as well
					if (index - peakValleyInformation[peakNumber -1][0] > averageBarWidth) {
						//add peak and valley
						peakValleyInformation[peakNumber][0] = zeroDerivativeCloseToZero;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						peakValleyInformation[peakNumber][0] = index;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						
						[aPath moveToPoint:NSMakePoint(zeroDerivativeCloseToZero, 0)];
						[aPath lineToPoint:NSMakePoint(zeroDerivativeCloseToZero, 350)];
						
					}
					zeroDerivativeCloseToZero = 0;
				}
			}
			
			
			//peak
			if (current < (mx - delta)) {
				
				if (current < lowestPeak)
					lowestPeak = current;
				if (current > heighestPeak)
					heighestPeak = current;
				
				[aPath moveToPoint:NSMakePoint(index -1, 255)];
				[aPath lineToPoint:NSMakePoint(index -1, 0)];
				
				peakValleyInformation[peakNumber][0] = index -1;
				peakValleyInformation[peakNumber][1] = current;
				peakNumber++;
				
				mn = current;
				//mnpos = index;
				lookformax = NO;
				count = -1;
				zeroDerivativeCloseToZero = 0;
			}
		}
		else {
			
			if (secondDerivative > -4) {
				zeroDerivativeCloseToZero = index;
			}
			else {
				if (zeroDerivativeCloseToZero != 0) {
					
					// Only add if the lest a bar width away from the previous peak, 
					if (index - peakValleyInformation[peakNumber - 1][0] > averageBarWidth) {
						//add peak and valley
						peakValleyInformation[peakNumber][0] = zeroDerivativeCloseToZero;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						peakValleyInformation[peakNumber][0] = index;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						
						[aPath moveToPoint:NSMakePoint(zeroDerivativeCloseToZero, 0)];
						[aPath lineToPoint:NSMakePoint(zeroDerivativeCloseToZero, 350)];
						
					}
					zeroDerivativeCloseToZero = 0;
				}
			}
			
			
			
			//valley
			if (current > (mn + delta)) {
				
				if (current > heighestValley)
					heighestValley = current;
				if (current < lowestValley)
					lowestValley = current;
				
				[valleyPath moveToPoint:NSMakePoint(index -1, 255)];
				[valleyPath lineToPoint:NSMakePoint(index -1, 0)];
				
				peakValleyInformation[peakNumber][0] = index -1;
				peakValleyInformation[peakNumber][1] = current;
				peakNumber++;
				
				mx = current;
				//mxpos = index;
				lookformax = YES;
				zeroDerivativeCloseToZero = 0;
			}
		}
		
		index++;
		count++;
	}
}



/*	This is a route is in development.
 Locating only the peaks of the barcode and infering the barcode from the peaks.
 Although the peaks contain less information they are not affected by edge blurring
 So using the space between peaks and statistical analysis could lead to the barcode
 Normalized distance between peaks should reflect the following:
 1 would mean it's 1 black stripe and 1 white stripe
 1.5 would mean it's 1 black and 2 white or 2 black and 1 white;
 2  =  1-3, 2-2, 3-1
 2.5  = 1-4, 2-3, 3-2, 1-4
 Using the next sorounding distances it can tell which possability it should be.
 */


//Experimentation with finding out the distance between peaks as they are not as sucetible to blurring 
- (void)getPeakDistanceForLine:(int *)pixelLineArray start:(int)startBarcode end:(int)endBarcode averageHeight:(int)averageHeight barArray:(int *)barsArray {
	
	
	/*
	 //Test average scanner
	 float testBarWidth[70] = {0};
	 testBarWidth[0] = 1;
	 testBarWidth[1] = 1;
	 testBarWidth[2] = 1;
	 testBarWidth[3] = 1;
	 testBarWidth[4] = 3;
	 testBarWidth[5] = 1;
	 testBarWidth[6] = 2;
	 testBarWidth[7] = 3;
	 testBarWidth[8] = 1;
	 testBarWidth[9] = 2;
	 testBarWidth[10] = 1;
	 testBarWidth[11] = 1;
	 [self decodeNumberBasedOnCloseMatch:testBarWidth];
	 */
	
	
	
	int zeroDerivativeCloseToZero = 0;
	//BOOL lookForSlopes = NO;
	//int lookingForSlopeSign;
	
	int lowestPeak = 255, heighestPeak = 0, heighestValley = 0, lowestValley = 255;
	int barcodeThickness = endBarcode - startBarcode;
	float averageBarWidth = barcodeThickness / 95.0;
	int peakValleyInformation[70][2] = {0};  //First row peak index, second height
	int mn = 256, mx = -256;
	//int mnpos, mxpos;
	int delta = 0; 
	//int delta = barcodeThickness / 100;  //Should be dependant on the width of the barcode
	int lookformax = YES;
	int index = startBarcode;
	int peakNumber = 0;
	int count = 0;
	int i, j;
	NSBezierPath *aPath = [NSBezierPath bezierPath];
	NSBezierPath *valleyPath = [NSBezierPath bezierPath];
	NSBezierPath *blackPath; // = [NSBezierPath bezierPath];
	
	/*
	 int newLine[640] = {0};
	 [self binarizeLine:pixelLineArray to:newLine start:startBarcode width:barcodeThickness];
	 
	 NSBezierPath *binaryPath = [NSBezierPath bezierPath];
	 for (j = 0; j < 640 ; j++) {
	 if (newLine[j] == BLACK_PIXEL) {
	 [binaryPath moveToPoint:NSMakePoint(j, 0)];
	 [binaryPath lineToPoint:NSMakePoint(j, 255)];
	 }
	 }
	 [barcodeView setPath:binaryPath withColor:[NSColor blackColor]];
	 return;
	 */
	
	
	while (index < endBarcode && peakNumber < 69) {
		int current = pixelLineArray[index];
		
		if (current > mx) {
			mx = current; 
			//mxpos = index;
		}
		if (current < mn) {
			mn = current; 
			//mnpos = index;
		}
		
		
		// Looking for small slopes that are small peaks
		int secondDerivative =  pixelLineArray[index + 1] - current;
		
		
		if (lookformax) {
			
			if (secondDerivative < 4) {
				zeroDerivativeCloseToZero = index;
			}
			else {
				if (zeroDerivativeCloseToZero != 0) {
					
					// Only add if the lest a bar width away from the previous peak, 
					//!!! should check against the upcoming peak as well
					if (index - peakValleyInformation[peakNumber -1][0] > averageBarWidth) {
						//add peak and valley
						peakValleyInformation[peakNumber][0] = zeroDerivativeCloseToZero;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						peakValleyInformation[peakNumber][0] = index;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						
						[aPath moveToPoint:NSMakePoint(zeroDerivativeCloseToZero, 0)];
						[aPath lineToPoint:NSMakePoint(zeroDerivativeCloseToZero, 350)];
						
					}
					zeroDerivativeCloseToZero = 0;
				}
			}
			
			
			//peak
			if (current < (mx - delta)) {
				
				if (current < lowestPeak)
					lowestPeak = current;
				if (current > heighestPeak)
					heighestPeak = current;
				
				[aPath moveToPoint:NSMakePoint(index -1, 255)];
				[aPath lineToPoint:NSMakePoint(index -1, 0)];
				
				peakValleyInformation[peakNumber][0] = index -1;
				peakValleyInformation[peakNumber][1] = current;
				peakNumber++;
				
				mn = current;
				//mnpos = index;
				lookformax = NO;
				count = -1;
				zeroDerivativeCloseToZero = 0;
			}
		}
		else {
			
			if (secondDerivative > -4) {
				zeroDerivativeCloseToZero = index;
			}
			else {
				if (zeroDerivativeCloseToZero != 0) {
					
					// Only add if the lest a bar width away from the previous peak, 
					if (index - peakValleyInformation[peakNumber - 1][0] > averageBarWidth) {
						//add peak and valley
						peakValleyInformation[peakNumber][0] = zeroDerivativeCloseToZero;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						peakValleyInformation[peakNumber][0] = index;
						peakValleyInformation[peakNumber][1] = current;
						peakNumber++;
						
						[aPath moveToPoint:NSMakePoint(zeroDerivativeCloseToZero, 0)];
						[aPath lineToPoint:NSMakePoint(zeroDerivativeCloseToZero, 350)];
						
					}
					zeroDerivativeCloseToZero = 0;
				}
			}
			
			
			
			//valley
			if (current > (mn + delta)) {
				
				if (current > heighestValley)
					heighestValley = current;
				if (current < lowestValley)
					lowestValley = current;
				
				[valleyPath moveToPoint:NSMakePoint(index -1, 255)];
				[valleyPath lineToPoint:NSMakePoint(index -1, 0)];
				
				peakValleyInformation[peakNumber][0] = index -1;
				peakValleyInformation[peakNumber][1] = current;
				peakNumber++;
				
				mx = current;
				//mxpos = index;
				lookformax = YES;
				zeroDerivativeCloseToZero = 0;
			}
		}
		
		index++;
		count++;
	}
	
	//Add the last bar as it's not added above
	//peakValleyInformation[peakNumber-1][0] = peakValleyInformation[peakNumber-1][0] + averageBarWidth;
	//peakValleyInformation[peakNumber][1] = peakValleyInformation[peakNumber][0];
#ifdef DEBUG
	
	[graphView setPath:aPath withColor:[NSColor redColor]];
	[graphView setPath:valleyPath withColor:[NSColor darkGrayColor]];
	//NSLog(@"peak: high %d low: %d", heighestPeak, lowestPeak);
	//NSLog(@"valley: high %d low: %d", heighestValley, lowestValley);
#endif DEBUG
	
	
	
	//NSBezierPath *curvePath = [NSBezierPath bezierPath];
	
	//There should be 58 peaks and valleys 30 black peaks and 28 valleys in between
	if (peakNumber > 30 && peakNumber < 70) {
		
		int k;
		int largestDifference = (heighestPeak - lowestValley);
		float averageHeightOfCode = largestDifference * 0.5 + lowestValley;
		
		
		/*
		 //float widthBarcode = (peakValleyInformation[peakNumber - 1][0] - peakValleyInformation[0][0]);
		 //float oneBarWidth = widthBarcode / 95.0;
		 int twentyPercentHeight = largestDifference * 0.2;
		 int tenPercentHeight = largestDifference * 0.1;
		 //int fourPercentHeight = largestDifference * 0.04;
		 
		 //NSLog(@"diff: %d twenty: %d", largestDifference, twentyPercentHeight);
		 
		 int highRangeForOne = lowestPeak + twentyPercentHeight;
		 int lowRangeForOne = heighestValley - twentyPercentHeight;
		 //int highRangeForOne = averageHeightOfCode + twentyPercentHeight;
		 //int lowRangeForOne = averageHeightOfCode - twentyPercentHeight;
		 
		 //int barsArray[70] = {0};  //Should be 58 bars, but 70 to get some over scans		
		 
		 //Make the first peak, valley, peak all one
		 barsArray[0] = 1;
		 //barsArray[1] = 1;
		 //barsArray[2] = 1;
		 
		 //[curvePath moveToPoint:NSMakePoint(peakValleyInformation[0][0] + ((peakValleyInformation[1][0] - peakValleyInformation[0][0]) / 2), peakValleyInformation[0][1] - ((peakValleyInformation[1][1] - peakValleyInformation[0][1]) / 2))];
		 
		 //int k = 0;
		 //heighestValley = heighestValley * 1.1;
		 //lowestPeak = lowestPeak * 0.9;
		 
		 
		 //start at valley 2
		 for (i = 1; i < peakNumber - 1 ; i++) {
		 
		 //int x = peakValleyInformation[i][0] + (peakValleyInformation[i+1][0] - peakValleyInformation[i][0]) / 2;
		 //int y = peakValleyInformation[i][1] - (peakValleyInformation[i+1][1] - peakValleyInformation[i][1]) / 2;
		 //[curvePath lineToPoint:NSMakePoint(x, y)];
		 
		 int heightOfPoint = peakValleyInformation[i][1];
		 //int widthOfPoint = peakValleyInformation[i+1][0] - peakValleyInformation[i-1][0];
		 
		 //		int previousPointHeight = peakValleyInformation[i-1][1];
		 //		int nextPointHeight = peakValleyInformation[i+1][1];
		 
		 //	int previousWidth = peakValleyInformation[i][0] - peakValleyInformation[i-2][0];
		 //	int nextWidth = peakValleyInformation[i+2][0] - peakValleyInformation[i][0];
		 
		 
		 //based on height of peak
		 if (i % 2 == 0) { //peak
		 if (heightOfPoint < highRangeForOne)
		 barsArray[i] = 1;
		 else if (heightOfPoint > heighestPeak - tenPercentHeight)
		 barsArray[i] = 3; //or 4
		 else 
		 barsArray[i] = 2;	 
		 }
		 else { // valley
		 if (heightOfPoint > lowRangeForOne)
		 barsArray[i] = 1;
		 else if (heightOfPoint < lowestValley + tenPercentHeight)
		 barsArray[i] = 3; //or 4
		 else 
		 barsArray[i] = 2;	
		 
		 }
		 
		 }
		 barsArray[peakNumber - 1] = 1; // The last peak
		 //return;
		 
		 //[graphView setPath:curvePath withColor:[NSColor purpleColor]];
		 
		 */
		
		
		
		
		
		int blackAndWhite[640] = {0};
		//There should be 58 peaks and valleys 30 black peaks and 28 valleys in between
		if (peakNumber > 30 && peakNumber < 70) {
			
			float widthBarcode = (peakValleyInformation[peakNumber - 1][0] - peakValleyInformation[0][0]);
			averageBarWidth = widthBarcode / 95.0;
			
			for (i = 0; i < peakNumber - 1 ; i++) {
				
				int locationOfBar = peakValleyInformation[i][0];
				int locationLastBar = peakValleyInformation[i+1][0];
				int heightOfBar = peakValleyInformation[i][1];
				int heightLastBar = peakValleyInformation[i+1][1];
				float averageHeightOfSection = (heightOfBar + heightLastBar) / 2.0;
				
				
				float ratioToAdjust = averageHeightOfSection / averageHeightOfCode;
				if (ratioToAdjust > 1) {
					ratioToAdjust = ratioToAdjust - 1;
					ratioToAdjust = 1 - ratioToAdjust;
				}
				//else
				//ratioToAdjust = 1 - ratioToAdjust;
				
				
				if (heightOfBar > heightLastBar) {
					averageHeightOfSection = heightLastBar + ((heightOfBar - heightLastBar) * ratioToAdjust) / 2;
				}
				else
					averageHeightOfSection = heightOfBar + ((heightLastBar - heightOfBar) * ratioToAdjust) / 2;
				
				
				for (j = locationOfBar; j < locationLastBar; j++) {
					//NSLog(@"%d\t\t%f", peakValleyInformation[j][1], averageHeightOfSection);
					if (pixelLineArray[j] > averageHeightOfSection) {
						//NSLog(@"%d black", j);
						//[blackPath moveToPoint:NSMakePoint(j, 0)];
						//[blackPath lineToPoint:NSMakePoint(j, 255)];	
						blackAndWhite[j] = BLACK_PIXEL;
					}
					//else
					//NSLog(@"%d white", j);
				}
			}
		}
		//[barcodeView setPath:blackPath withColor:[NSColor blackColor]];
		
		//Count thickness
		int thickness[70] = {0};
		int lastPeak = peakValleyInformation[peakNumber - 1][0], firstPeak = peakValleyInformation[0][0];
		BOOL inBlack = YES;
		int count = 0, largestCount = 0, smallestCount = 255;
		
		for (k = 0, i = firstPeak; i < lastPeak; i++) {
			int nextColor = blackAndWhite[i];
			if ((inBlack && nextColor == WHITE_PIXEL) || (!inBlack && nextColor == BLACK_PIXEL)) {
				thickness[k] = count;
				k++;
				inBlack = !inBlack;
				
				
				if (count > largestCount)
					largestCount = count;
				if (count < smallestCount)
					smallestCount = count;
				count = 0;
			}
			count++;
		}
		
		
		//fill out the other bars counts based on the thickness
		//NSLog(@"small: %d large: %d", smallestCount, largestCount);
		//NSLog(@"%f", averageBarWidth);
		//int averageThicknessBasedOnFattest = largestCount / 3.0;
		for (i = 0; i < peakNumber - 1 ; i++) {
			if (barsArray[i] == 0) {
				barsArray[i] = [self getNumberfromThickness:thickness[i] oneBar:averageBarWidth];
			}
		}
		
		
		
		
		// Draw bars in 1200 pixel for debugging
		blackPath = [NSBezierPath bezierPath];
		int movingLocation = 0;
		for (i = 0; i < 62; i++) {
			int displayWidth = barsArray[i] * 4;
			
			//black
			if (i % 2 == 0) {
				for (j = 0; j < displayWidth; j++) {
					[blackPath moveToPoint:NSMakePoint(movingLocation, 255)];
					[blackPath lineToPoint:NSMakePoint(movingLocation, 0)];
					movingLocation++;
				}			 
			}
			else 
				movingLocation += displayWidth; //white
		}
		
		/*
		 //draw one width
		 int movingLocation = 1250;
		 int displayWidth = averageBarWidth / widthBarcode * 1200;
		 for (j = 0; j < displayWidth; j++) {
		 [blackPath moveToPoint:NSMakePoint(movingLocation, 255)];
		 [blackPath lineToPoint:NSMakePoint(movingLocation, 0)];
		 movingLocation++;
		 }			 
		 
		 */
#ifdef DEBUG
		
		[barcodeView setPath:blackPath withColor:[NSColor blackColor]];
		[barcodeView display];
		[barcodeView removeAllPaths];
#endif
		
		
		//print bars
		NSMutableString *numberString = [NSMutableString string];		
		for (i = 0; i < 62; i++) {
			[numberString appendString:[NSString stringWithFormat:@"%d ", barsArray[i]]];
		}
		//NSLog(@"%@", numberString);
		
		
		[self clearNumberArray:numberArray];
		[self readBarsStartingWithHeaderBars:barsArray];
		//NSLog(@"Scanned %@  ", [self barcodeFromArray:numberArray]);
		
		
		//NSString *barcodeNumberAvergae = [self decodeNumberBasedOnCloseMatch:barsArray];
		//NSLog(@"based on best guess: %@", barcodeNumberAvergae);
		
	}
	
}



//given a array of bar thickness it read four bars at a time and determines the number based on the encoding 
- (void)readBarsStartingWithHeaderBars:(int [62])lastBinaryData {
	
	int k, j;
	
	if (lastBinaryData[0] == 1 && lastBinaryData[1] == 1 && lastBinaryData[2] == 1) {
		int i = 3;
		k = 0;
		
		//First number has to be odd encoded			
		[self getNumberForLocation:&lastBinaryData[i]  encoding:MKLeftHandEncodingOdd location:k];
		
		if (numberArray[0][k] == NOT_FOUND) {
			//turn any 3 bars into 4 bars and try again
			for (j = i; j < i + 4; j++)
				if (lastBinaryData[j] == 3)
					lastBinaryData[j] = 4;
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
		}
		
		if (numberArray[0][k] != NOT_FOUND)
			numberOfDigitsFound++;
		
		
		//First Section left hand encoding even or odd
		for (i = i +4, k = 1; i < 28; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKLeftHandEncodingBoth location:k];
			
			if (numberArray[0][k] == NOT_FOUND) {
				//turn any 3 bars into 4 bars and try again
				for (j = i; j < i + 4; j++)
					if (lastBinaryData[j] == 3)
						lastBinaryData[j] = 4;
				[self getNumberForLocation:&lastBinaryData[i] encoding:MKLeftHandEncodingBoth location:k];
			}
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
		}
		
		//Second section all right hand encoding
		for (i = i+5; i < 57; i = i + 4, k++) {
			
			[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
			
			if (numberArray[0][k] == NOT_FOUND) {
				//turn any 3 bars into 4 bars and try again
				for (j = i; j < i + 4; j++)
					if (lastBinaryData[j] == 3)
						lastBinaryData[j] = 4;
				[self getNumberForLocation:&lastBinaryData[i] encoding:MKRightHandEncoding location:k];
			}
			
			if (numberArray[0][k] != NOT_FOUND)
				numberOfDigitsFound++;
		}
	} 
}


- (int)getNumberfromThickness:(int)thickness oneBar:(float)aBarWidth {
	double ratioToAverageThickness = thickness / aBarWidth;
	//NSLog(@"%d %f", thickness, aBarWidth);
	//NSLog(@"%f", ratioToAverageThickness);
	if (ratioToAverageThickness < 1.5)
		return 1;
	else if (ratioToAverageThickness < 2.7)
		return 2;
	else
		return 3;
}


#endif

@end

