
#import "SGVideo.h"
#import "WhackedDebugMacros.h"
//#import "SampleCIView.h"
#import "MyBarcodeScanner.h"

@interface MyBarcodeScanner (QTKitDelegateMethod)
- (void)captureOutput:(id)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(id)sampleBuffer fromConnection:(id)connection;
@end


NSString * SGVideoPreviewViewBoundsChangedNotification = @"SGVideoPreviewViewBoundsChangedNotification";


static OSErr 
SGVideoDataProc(SGChannel c,  Ptr p,  long len,  long *offset,  long chRefCon, 
                TimeValue time,  short writeType, long refCon)
{
#pragma unused(offset)
#pragma unused(chRefCon)
#pragma unused(writeType)
#pragma unused(refCon)
	OSErr err = noErr;
    SGChan * chan = nil;
    
    SGGetChannelRefCon(c, (long*)&chan);

	err = [(SGVideo*)chan decompressData:p length:len time:time];

	return err;
}

// The tracking callback function for the decompression session.
// Used to display buffers into our view
static void 
SGVideoDecompTrackingCallback( 
		void *decompressionTrackingRefCon,
		OSStatus result,
		ICMDecompressionTrackingFlags decompressionTrackingFlags,
		CVPixelBufferRef pixelBuffer,
		TimeValue64 displayTime,
		TimeValue64 displayDuration,
		ICMValidTimeFlags validTimeFlags,
		void *reserved,
		void *sourceFrameRefCon )
{
#pragma unused(reserved)
#pragma unused(sourceFrameRefCon)
	if (result == noErr)
		[(SGVideo*)decompressionTrackingRefCon displayData:pixelBuffer
						trackingFlags:decompressionTrackingFlags
						displayTime:displayTime
						displayDuration:displayDuration
						validTimeFlags:validTimeFlags];
}


@implementation SGVideo

/*
ComponentResult SetVideoChannelBounds(SGChannel videoChannel,
                                      const Rect *scaledSourceBounds,
                                      const Rect *scaledVideoBounds)
{
    Rect sourceBounds;
    Rect videoBounds;
    Rect channelBounds;
    MatrixRecord scaledSourceBoundsToSourceBounds;
    ComponentResult err;
	
    // calculate the matrix to transform the
    // scaledSourceBounds to the source bounds
	
    SGGetSrcVideoBounds(videoChannel, &sourceBounds);   
    RectMatrix(&scaledSourceBoundsToSourceBounds,
               scaledSourceBounds, &sourceBounds);
	
    // apply the same transform to the
    // scaledVideoBounds to get the video bounds
    videoBounds = *scaledVideoBounds;
    TransformRect(&scaledSourceBoundsToSourceBounds, &videoBounds, 0);
    
    err = SGSetVideoRect(videoChannel, &videoBounds);
    if ((digiUnimpErr == err) || (qtParamErr == err)) {
        // some video digitizers may only support capturing full frame
        // or at certain specific sizes - they will return qtParamErr or
        // digiUnimpErr if unable to honor the requested video bounds      
        err = SGSetVideoRect(videoChannel, &sourceBounds);
    }
    if (err) goto bail;
	
    // the channel bounds is scaledVideoBounds offset to (0, 0)
    channelBounds = *scaledVideoBounds;
    OffsetRect(&channelBounds, -channelBounds.left, -channelBounds.top);
	
    // SGSetChannelBounds merely allows the client to specify
    // it's preferred bounds. The actual bounds returned by
    // the vDig in the image description may be different
    err = SGSetChannelBounds(videoChannel, &channelBounds);
	
bail:
    return err;
}

 */
/*___________________________________________________________________________________________
*/

#define CAMERA_FOCUS 0.35

#define NUMBER_OF_LINES_SCANNED 14
#define SPACING_BETWEEN_SCAN_LINE 8

//RELEVANT_SECTION
// Because the newer iSight has a higher resoultion all this following variables are in order to move the scanned lines
// higher in the image to the center of the image depending if resolution is 640 x 480 or 1280 x 960
#define FIRST_LINE_SCAN (240 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE))
#define FIRST_LINE_SCAN_HIGHRES (480 - (NUMBER_OF_LINES_SCANNED /2 * SPACING_BETWEEN_SCAN_LINE))
float startLine; 
float beginLineDrawingPixel, endLineDrawingPixel;

- (id)initWithSeqGrab:(SeqGrab*)sg
{
    OSStatus    err = noErr;
    NSRect      srcRect;
	long quickTimeVersion = 0;
	//ComponentInstance vd;
	
	// Set all the defaults for 640 x 480
	//startLine = FIRST_LINE_SCAN;
	//beginLineDrawingPixel = 200.0;
	//endLineDrawingPixel = 440.0;
	mPreviewBounds = NSMakeRect(0, 0, 640.0, 480.0);

    self = [super initWithSeqGrab:sg];
    
	if (mChan == NULL)
		BAILSETERR( SGNewChannel([sg seqGrabComponent], VideoMediaType, &mChan) );
	
	// Set the focus value helps with external iSights
	// Thanks to Wil Shipley for the focus code: http://lists.apple.com/archives/quicktime-api/2004/Mar/msg00257.html
	if (Gestalt(gestaltQuickTime, &quickTimeVersion) || ((quickTimeVersion & 0xFFFFFF00) > 0x0708000)) {
		QTAtomContainer iidcFeaturesAtomContainer = NULL;
		QTAtom featureAtom = 0.0;
		QTAtom typeAndIDAtom = 0.0;
		QTAtom featureSettingsAtom = 0.0;
		QTNewAtomContainer(&iidcFeaturesAtomContainer);
		
		
		QTInsertChild(iidcFeaturesAtomContainer, kParentAtomIsContainer, vdIIDCAtomTypeFeature, 1, 0, 0, nil, &featureAtom);
		VDIIDCFeatureAtomTypeAndID featureAtomTypeAndID = {vdIIDCFeatureFocus, vdIIDCGroupMechanics, {5}, vdIIDCAtomTypeFeatureSettings, vdIIDCAtomIDFeatureSettings};
		QTInsertChild(iidcFeaturesAtomContainer, featureAtom, vdIIDCAtomTypeFeatureAtomTypeAndID, vdIIDCAtomIDFeatureAtomTypeAndID, 0, sizeof(featureAtomTypeAndID), &featureAtomTypeAndID, &typeAndIDAtom);
		VDIIDCFeatureSettings featureSettings = {{0, 0, 0, 0.0, 0.0}, {vdIIDCFeatureFlagOn | vdIIDCFeatureFlagManual | vdIIDCFeatureFlagRawControl, CAMERA_FOCUS}};
		QTInsertChild(iidcFeaturesAtomContainer, featureAtom, vdIIDCAtomTypeFeatureSettings, vdIIDCAtomIDFeatureSettings, 0, sizeof(featureSettings), &featureSettings, &featureSettingsAtom);
		VDIIDCSetFeatures(SGGetVideoDigitizerComponent(mChan), iidcFeaturesAtomContainer);
	}
	
	/*
	vd = SGGetVideoDigitizerComponent(mChan);
	if (vd) {
		// Set saturation to black and white
		//unsigned short newSaturation = 0;
		//err = VDSetSaturation(vd, &newSaturation);
		
		// Old iSight give unimplemented error, way to detect new one 1.3 mega pixels
		// VDSetBrightness also not implemented by old iSight

		unsigned short newContrast = 0;
		VDGetContrast(vd, &newContrast);
		OSErr errorSetContrast = VDSetContrast(vd, &newContrast);
		if (!errorSetContrast) {
			//RELEVANT_SECTION
			// Is high resolution iSight set variables for high resolution
			newHighResiSight = YES;
			startLine = FIRST_LINE_SCAN_HIGHRES;
			mPreviewBounds = NSMakeRect(0, 0, 1280.0, 960.0);
			beginLineDrawingPixel = 520.0;
			endLineDrawingPixel = 760.0;
		}
	}
	 */
	

	BAILSETERR( SGSetChannelRefCon(mChan, (long)self) );
	
    srcRect = [self srcVideoBounds];
	[self setOutputBounds:srcRect];

    
    BAILSETERR( SGSetDataProc([sg seqGrabComponent], &SGVideoDataProc, 0) );
    
	[mSG addChannel:self];
	[super setUsage:seqGrabRecord];
    [self setUsage:seqGrabPreview];
	
	//mPreviewView = [[SampleCIView alloc] initWithFrame:srcRect];
	//[mPreviewView setHighResiSight:newHighResiSight];
	
	//[self setPreviewQuality:codecNormalQuality];
	[self setPreviewQuality:codecLosslessQuality];
    
bail:
    if (err)
    {
        [self release];
        return nil;
    }
    return self;
}

/*___________________________________________________________________________________________
*/

- (void)dealloc {
    //NSLog(@"[SGVideo dealloc] %p", self);
    DisposeGWorld(mOffscreen);
    if (mDecompS)
        ICMDecompressionSessionRelease(mDecompS);
	//[mPreviewView removeFromSuperview];
    //[mPreviewView release];
	[barcodeScanner release];
    [super dealloc];
}

/*___________________________________________________________________________________________
*/

- (void)setUsage:(long)usage
{
    mUsage = usage;
}

/*___________________________________________________________________________________________
*/

- (long)usage
{
    return mUsage;
}

/*___________________________________________________________________________________________
*/

- (NSString*)selectedDevice;
{
	SGDeviceList list = NULL;
	SGDeviceInputList theSGInputList = NULL;
    NSString * currentDeviceAndInput = nil;
    OSStatus err = noErr;
	short deviceIndex, inputIndex;
	BOOL showInputsAsDevices = NO;

// get the list
    err = SGGetChannelDeviceList(mChan, sgDeviceListIncludeInputs, &list);

    if (!err && list)
    {
        // init
        deviceIndex = (*list)->selectedIndex;
        SGGetChannelDeviceAndInputNames(mChan, NULL, NULL, &inputIndex);
        showInputsAsDevices = ((*list)->entry[deviceIndex].flags) & sgDeviceNameFlagShowInputsAsDevices;
        theSGInputList = ((SGDeviceName *)(&((*list)->entry[deviceIndex])))->inputs;

        // get the combined device/input name
        if (showInputsAsDevices)
            currentDeviceAndInput = [NSString stringWithCString:(char*)((*theSGInputList)->entry[inputIndex].name + 1) 
										length:((*theSGInputList)->entry[inputIndex].name[0])];
    }

    if (list)
        SGDisposeDeviceList([mSG seqGrabComponent], list);

    return currentDeviceAndInput;
}

/*___________________________________________________________________________________________
*/

- (NSRect)srcVideoBounds
{
    Rect r;
    NSRect nsr = {0};
    
    if (noErr == SGGetSrcVideoBounds(mChan, &r))
    {
		if (r.bottom == 1200 && r.right == 1600)
		{
			
				// IIDC/UVC drivers reports the largest bounds possible in the spec.  
				// At least if it's iSight, we can hack in a better value
			if ([[self selectedDevice] rangeOfString:@"iSight"].length > 0)
			{
				
				//RELEVANT_SECTION
				if (newHighResiSight)
					nsr = NSMakeRect(0, 0, 1280, 960);
				else
					nsr = NSMakeRect(0, 0, 640, 480);
				goto bail;
			}
		}

		nsr = NSMakeRect(r.left, r.top, r.right - r.left, r.bottom - r.top);
    }
bail:    
    return nsr;
}

/*___________________________________________________________________________________________
*/

- (NSRect)outputBounds
{
    Rect r;
    SGGetChannelBounds(mChan, &r);
    
    return NSMakeRect(r.left, r.top, r.right - r.left, r.bottom - r.top);
}

/*___________________________________________________________________________________________
*/

- (void)setOutputBounds:(NSRect)bounds
{
    OSStatus err = noErr;
    
    if (mOffscreen)
    {
        DisposeGWorld(mOffscreen);
        mOffscreen = NULL;
    }
    if (bounds.size.width && bounds.size.height)
    {
        Rect r;
		SetRect(&r, 0, 0, (short)bounds.size.width, (short)bounds.size.height);
        BAILSETERR( QTNewGWorld(&mOffscreen, 32, &r, NULL, NULL, 0) );
        LockPixels(GetGWorldPixMap(mOffscreen));
        
        BAILSETERR(SGSetGWorld(mChan, mOffscreen, GetGWorldDevice(mOffscreen)));
        
        BAILSETERR( SGSetChannelBounds(mChan, &r) );
    }
    
bail:
    return;
}

/*___________________________________________________________________________________________
*/

- (void)setPreviewQuality:(CodecQ)quality
{
	mPreviewQuality = quality;
}

/*___________________________________________________________________________________________
*/

- (CodecQ)previewQuality
{
	return mPreviewQuality;
}

/*___________________________________________________________________________________________
*/

- (NSRect)previewBounds
{
    return mPreviewBounds;
}

/*___________________________________________________________________________________________
*/
 
- (void)setPreviewBounds:(NSRect)newBounds
{
    if (newBounds.size.width != mPreviewBounds.size.width ||
        newBounds.size.height != mPreviewBounds.size.height)
    {
        mPreviewBounds = newBounds;
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:SGVideoPreviewViewBoundsChangedNotification object:self];
    }
}

/*___________________________________________________________________________________________
*/

- (OSType)channelType
{
    return VideoMediaType;
}

/*___________________________________________________________________________________________
*/

/*
- (SampleCIView *)previewView
{
	return mPreviewView;
}
 */

/*___________________________________________________________________________________________
*/

- (NSString*)summaryString
{
	return [self selectedDevice];
   // return [NSString stringWithFormat:@"[%p] SGVideo: %@", self, [self selectedDevice]];
}

/*___________________________________________________________________________________________
*/

- (void)setDesiredPreviewFrameRate:(float)fps
{
    mDesiredPreviewFrameRate = fps;
}

/*___________________________________________________________________________________________
*/

- (float)desiredPreviewFrameRate
{
    return mDesiredPreviewFrameRate;
}

/*___________________________________________________________________________________________
*/

// the object that will try to find a barcode in a frame
- (void)setBarcodeScanner:(MyBarcodeScanner *)scanner {
	[barcodeScanner release];
	barcodeScanner = [scanner retain];
	//[barcodeScanner setHighResiSight:newHighResiSight];
}
/*___________________________________________________________________________________________
 */

-(OSErr)decompressData:(void*)data length:(long)length time:(TimeValue)timeValue
{
    OSStatus err = noErr;
    ICMFrameTimeRecord frameTime = {{0}};
    
        // don't bother doing any work if we're not supposed to be previewing
    if ( ([mSG isPreviewing] && !([self usage] & seqGrabPreview)) ||
         ([mSG isRecording] && !([self usage] & seqGrabPlayDuringRecord)) )
    {
        goto bail;
    }
	
	/*
        // don't bother doing any decompressing if our view is not in use
	if ([mPreviewView window] == nil)
	{
		goto bail; 
	}
	*/
	
	if (mLastTime > timeValue)
	{
        // this means there was a stop/start
		mLastTime = 0;
		mFrameCount = 0;
        mTimeScale = 0;
        mMinPreviewFrameDuration = 0;
		mPreviewBounds = NSMakeRect(0., 0., 0., 0.);
        
        if (mDecompS)
        {
            ICMDecompressionSessionRelease(mDecompS);
            mDecompS = NULL;
        }
	}
    
    if (mTimeScale == 0)
    {
        BAILSETERR( SGGetChannelTimeScale(mChan, &mTimeScale) );
    }
    
    
    
        // find out if we should drop this frame
    if (mDesiredPreviewFrameRate)
    {
        if (mMinPreviewFrameDuration == 0)
            mMinPreviewFrameDuration = (TimeValue)(mTimeScale/mDesiredPreviewFrameRate);
            
            // round times to a multiple of the frame rate
        int n = (int)floor( ( ((float)timeValue) * mDesiredPreviewFrameRate / mTimeScale ) + 0.5 );
        timeValue = (TimeValue)(n * mTimeScale / mDesiredPreviewFrameRate);
        
        if ( (mLastTime > 0) && (timeValue < mLastTime + mMinPreviewFrameDuration) )
        {
            // drop the frame
            goto bail;
        }
    }
    
    
    
        // Make a decompression session!!
    if (NULL == mDecompS)
    {
        ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
        //NSRect srcRect = [self srcVideoBounds], imageRect = {0};
        NSMutableDictionary * pixelBufferAttribs = nil;
        ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
        ICMDecompressionSessionOptionsRef sessionOptions = NULL;
        
        
        
        if ( noErr != (err = SGGetChannelSampleDescription(mChan, (Handle)imageDesc)) )
        {
            DisposeHandle((Handle)imageDesc);
            BAILERR(err);
        }
        
        
        
        // Get the display width and height (the clean aperture width and height
        // suitable for display on a square pixel display like a computer monitor)
		 SInt32 displayWidth, displayHeight;
        if (noErr != ICMImageDescriptionGetProperty(imageDesc, kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_DisplayWidth,
                                sizeof(displayWidth), &displayWidth, NULL) )
            displayWidth = (**imageDesc).width;
        
        if (noErr != ICMImageDescriptionGetProperty(imageDesc, kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_DisplayHeight,
                                sizeof(displayHeight), &displayHeight, NULL) )
            displayHeight = (**imageDesc).height;
		
		//displayWidth = 1280.0;
		//displayHeight = 960.0;
            
		NSRect imageRect = NSMakeRect(0., 0., (float)displayWidth, (float)displayHeight);
		[self setPreviewBounds:imageRect];
        
        
        
		// the view to which we will be drawing accepts CIImage's.  As of QuickTime 7.0,
        // the CIImage * class does not apply gamma correction information present in
        // the ImageDescription unless there is also NCLCColorInfo to go with it.
        // We'll check here for the presence of this extension, and add a default if
        // we don't find one (we'll restrict this slam to 2vuy pixel format).
        if ( (**imageDesc).cType == '2vuy' )
        {
            OSStatus tryErr;
            NCLCColorInfoImageDescriptionExtension nclc;
            
            tryErr = ICMImageDescriptionGetProperty(imageDesc, 
                    kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_NCLCColorInfo, 
                    sizeof(nclc), &nclc, NULL);
            if( noErr != tryErr ) {
                // Assume NTSC
                nclc.colorParamType = kVideoColorInfoImageDescriptionExtensionType;
                nclc.primaries = kQTPrimaries_SMPTE_C;
                nclc.transferFunction = kQTTransferFunction_ITU_R709_2;
                nclc.matrix = kQTMatrix_ITU_R_601_4;
                ICMImageDescriptionSetProperty(imageDesc, 
                    kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_NCLCColorInfo, 
                    sizeof(nclc), &nclc);
            }
        }

        
        
        
        
        // fill out a dictionary describing the attributes of the pixel buffers we want the session
        // to produce.  we're purposely not setting a pixel format, as we want the session to figure
        // out the best format.  This strategy gives us performance opportunities if we don't
        // want to draw onto the video.  If we _do_ want to draw, we should explicitly ask for
        // k32ARGBPixelFormat.
	
        pixelBufferAttribs = [[NSMutableDictionary alloc] init];
	/*	
		//don't pass width and height.  Let the codec make a best guess as to the appropriate
		//width and height for the given quality.  It might choose to do a quarter frame decode,
		//for instance
		
       		*/
		[pixelBufferAttribs setObject:[NSNumber numberWithFloat:imageRect.size.width] forKey:(id)kCVPixelBufferWidthKey];
        [pixelBufferAttribs setObject:[NSNumber numberWithFloat:imageRect.size.height] forKey:(id)kCVPixelBufferHeightKey];

	
		//[pixelBufferAttribs setObject:[NSNumber numberWithFloat:640] forKey:(id)kCVPixelBufferWidthKey];
		//[pixelBufferAttribs setObject:[NSNumber numberWithFloat:480] forKey:(id)kCVPixelBufferHeightKey];		

		
        [pixelBufferAttribs setObject:[NSNumber numberWithBool:YES] forKey:(id)kCVPixelBufferOpenGLCompatibilityKey];
		
		//[pixelBufferAttribs setObject:[NSNumber numberWithInt:k32ARGBPixelFormat] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
		[pixelBufferAttribs setObject:[NSNumber numberWithInt:k2vuyPixelFormat] forKey:(id)kCVPixelBufferPixelFormatTypeKey];

		//RELEVANT_SECTION
		//Set clean aperture for new iSight, in order to zoom in on the image
		if (newHighResiSight) {
			NSMutableDictionary *aperture = [NSMutableDictionary dictionary];
			[aperture setObject:[NSNumber numberWithFloat:1280] forKey:@"Width"];		
			[aperture setObject:[NSNumber numberWithFloat:960] forKey:@"Height"];	
			//[aperture setObject:[NSNumber numberWithFloat:0] forKey:@"HorizontalOffset"];		
			//[aperture setObject:[NSNumber numberWithFloat:0] forKey:@"VerticalOffset"];			
			[pixelBufferAttribs setObject:aperture forKey:@"CVCleanAperture"];		
		}
        
        // assign a tracking callback
        trackingCallbackRecord.decompressionTrackingCallback = SGVideoDecompTrackingCallback;
        trackingCallbackRecord.decompressionTrackingRefCon = self;
        
        
        // we also need to create a ICMDecompressionSessionOptionsRef to fill in codec quality
        err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
        if (err == noErr)
        {
            ICMDecompressionSessionOptionsSetProperty(sessionOptions,
                    kQTPropertyClass_ICMDecompressionSessionOptions,
                    kICMDecompressionSessionOptionsPropertyID_Accuracy,
                    sizeof(CodecQ), &mPreviewQuality);
			
			//ICMDecompressionSessionOptionsSetProperty(sessionOptions, kQTPropertyClass_ICMDecompressionSessionOptions, kICMCompressionSessionOptionsPropertyID_ScalingMode, sizeof(CodecQ), kICMScalingMode_Trim);
			
			// kICMScalingMode_StretchCleanAperture default
			// kICMScalingMode_StretchProductionAperture
			// kICMScalingMode_Letterbox
			// kICMScalingMode_Trim
			
			// kICMCompressionSessionOptionsPropertyID_CleanAperture
        }
        
        // now make a new decompression session to decode source video frames
        // to pixel buffers
        err = ICMDecompressionSessionCreate(NULL, imageDesc, sessionOptions, // no session options
                    (CFDictionaryRef)pixelBufferAttribs, &trackingCallbackRecord, &mDecompS);
        
        
        [pixelBufferAttribs release];
        ICMDecompressionSessionOptionsRelease(sessionOptions);
        DisposeHandle((Handle)imageDesc);

		BAILERR(err);
    }
    
    
    frameTime.recordSize = sizeof(ICMFrameTimeRecord);
    *(TimeValue64*)&frameTime.value = timeValue;
    frameTime.scale = mTimeScale;
    frameTime.rate = fixed1;
    frameTime.frameNumber = ++mFrameCount;
    frameTime.flags = icmFrameTimeIsNonScheduledDisplayTime;
    
    // push the frame into the session
    err = ICMDecompressionSessionDecodeFrame( mDecompS,
			(UInt8 *)data, length, NULL, &frameTime, self );
    
    // and suck it back out
    ICMDecompressionSessionSetNonScheduledDisplayTime( mDecompS, timeValue, mTimeScale, 0 );
    
    mLastTime = timeValue;
bail:
    return err;
}



/*___________________________________________________________________________________________
*/

- (void)displayData:(CVPixelBufferRef)pixelBuffer
                    trackingFlags:(ICMDecompressionTrackingFlags)decompressionTrackingFlags
                    displayTime:(TimeValue64)displayTime
                    displayDuration:(TimeValue64)displayDuration
                    validTimeFlags:(ICMValidTimeFlags)validTimeFlags
{
#pragma unused(displayTime)
#pragma unused(displayDuration)
#pragma unused(validTimeFlags)
    if ( (decompressionTrackingFlags & kICMDecompressionTracking_EmittingFrame) && pixelBuffer)
    {		
		[barcodeScanner captureOutput:nil didOutputVideoFrame:pixelBuffer withSampleBuffer:nil fromConnection:nil];
		
		/*
		// Look for a barcode in the frame
		[barcodeScanner processPixelBuffer:pixelBuffer];
		
		// only draw into the view if it's housed in a window
		if ([mPreviewView window] != nil)
		{
			//drawLinesOnPixelBuffer(pixelBuffer, goodScan, lastNumberScanned);
			drawLinesOnPixelBuffer(pixelBuffer, goodScan);
			CIImage * ciImage = [CIImage imageWithCVImageBuffer:pixelBuffer];
			[mPreviewView setImage:ciImage];
			[mPreviewView setCleanRect:CVImageBufferGetCleanRect(pixelBuffer)];
			//[mPreviewView setDisplaySize:CVImageBufferGetDisplaySize(pixelBuffer)];
			[mPreviewView setDisplaySize:*(CGSize *)&mPreviewBounds.size];
			[mPreviewView setNeedsDisplay:YES];
		}
		 */
    }
}



@end
