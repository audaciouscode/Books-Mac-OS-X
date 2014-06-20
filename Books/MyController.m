/*
 MyController.m is part of BarcodeScanner.
 */

#import "MyController.h"
#import "MyBarcodeScanner.h"


@implementation MyController
 
- (IBAction)openiSightOneScan:(id)sender {
	
	//Get isight object and set values
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	MyBarcodeScanner *iSight = [MyBarcodeScanner sharedInstance];
	[iSight setStaysOpen:NO];
	[iSight setDelegate:self];
	
	//If option was held down, flip the mirrored preference value
	if ([sender isKindOfClass:[NSButton class]]) {
		if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
			int mirrorValue = ([[prefs objectForKey:@"Mirror iSight"] intValue] +1) %2;
			[prefs setObject:[NSNumber numberWithInt:mirrorValue] forKey:@"Mirror iSight"];
		}
	}
	
	//Set if mirrored
	if ([[prefs objectForKey:@"Mirror iSight"] intValue])
		[iSight setMirrored:YES];
	else
		[iSight setMirrored:NO];
	
	//Begin scan
	[iSight scanForBarcodeWindow:nil];
}


/*---  Same as above but by staysOpen is set to YES  
	Scanning continously won't scan the same barcode twice
	as it remembers the last scan.
--*/

- (IBAction)openiSightContinousScanning:(id)sender {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	MyBarcodeScanner *iSight = [MyBarcodeScanner sharedInstance];
	[iSight setStaysOpen:YES];
	[iSight setDelegate:self];
	
	//If option was held down, flip the mirrored preference value
	if ([sender isKindOfClass:[NSButton class]]) {
		if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
			int mirrorValue = ([[prefs objectForKey:@"Mirror iSight"] intValue] +1) %2;
			[prefs setObject:[NSNumber numberWithInt:mirrorValue] forKey:@"Mirror iSight"];
		}
	}
	
	if ([[prefs objectForKey:@"Mirror iSight"] intValue])
		[iSight setMirrored:YES];
	else
		[iSight setMirrored:NO];
	
	[iSight scanForBarcodeWindow:nil];
}

#pragma mark -
#pragma mark delegate


- (void)iSightWillClose {
	[[resultsTextView window] makeKeyAndOrderFront:self];
}

- (void)gotBarcode:(NSString *)barcode {
	[resultsTextView replaceCharactersInRange:NSMakeRange([[resultsTextView string] length] ,0) withString:barcode];
	[resultsTextView replaceCharactersInRange:NSMakeRange([[resultsTextView string] length],0) withString:@"\n"];
}



- (void)applicationDidFinishLaunching:(NSNotification*)notification
{	
#ifdef DEBUG
	[self openiSightOneScan:nil];
#endif DEBUG
}

@end
