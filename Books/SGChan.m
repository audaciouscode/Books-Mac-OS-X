

#import "SGChan.h"


@implementation SGChan

/*________________________________________________________________________________________
*/

- (id)initWithSeqGrab:(SeqGrab*)sg
{
	if (sg)
	{
		self = [super init];
		
		mSG = sg;

		// sub-classes call SGNewChannel
		// and addChannel:
    }
	else {
		[self release];
		return nil;
	}
	return self;
}

/*________________________________________________________________________________________
*/

- (id)initWithSeqGrab:(SeqGrab*)sg channelComponent:(SGChannel)chn
{
	mChan = chn;
	self = [self initWithSeqGrab:sg];
	return self;
}

/*________________________________________________________________________________________
*/

- (void)dealloc {
    //NSLog(@"[SGChan dealloc] %p", self);
    SGDisposeChannel([mSG seqGrabComponent], mChan);
    [super dealloc];
}

/*________________________________________________________________________________________
*/

// concrete subclasses answer this
- (OSType)channelType
{
    return 0;
}

/*________________________________________________________________________________________
*/

- (void)setUsage:(long)usage
{
	SGSetChannelUsage(mChan, usage);
}

/*________________________________________________________________________________________
*/

- (long)usage
{
    long usage;
    SGGetChannelUsage(mChan, &usage);
    return usage;
}

/*________________________________________________________________________________________
*/

- (void)setPreviewFlags:(long)flags
{
	SGSetChannelPlayFlags(mChan, flags);
}

/*________________________________________________________________________________________
*/

- (long)previewFlags
{
    long flags = 0;
    SGGetChannelPlayFlags(mChan, &flags);
    return flags;
}

/*________________________________________________________________________________________
*/

- (OSStatus)showSettingsDialog
{
	return( SGSettingsDialog([mSG seqGrabComponent], mChan, 0, NULL, 0, NULL, 0) );
}

/*________________________________________________________________________________________
*/

- (NSString*)summaryString
{
	return @"(implemented by sub-classes)";
}
- (SeqGrab*)grabber
{
	return mSG;
}

/*________________________________________________________________________________________
*/

- (SGChannel)chanComponent
{
	return mChan;
}

/*________________________________________________________________________________________
*/
@end
