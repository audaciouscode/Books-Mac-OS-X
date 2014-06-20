/* FileImporterAppDelegate */

#import <Cocoa/Cocoa.h>
#import "ResultsDataSource.h"

@interface FileImporterAppDelegate : NSObject
{
    IBOutlet id menu;
    IBOutlet ResultsDataSource * resultsDataSource;
    IBOutlet id resultsTable;
    IBOutlet id window;
    IBOutlet id progressWindow;
    IBOutlet id progressBar;
    IBOutlet id progressMessage;
    IBOutlet id quitMenuItem;
	
	NSString * filePath;
}

- (IBAction)export:(id)sender;
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;

@end
