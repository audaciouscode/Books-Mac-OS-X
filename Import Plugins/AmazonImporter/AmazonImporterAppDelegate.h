/* AmazonImporterAppDelegate */

#import <Cocoa/Cocoa.h>

#import "AmazonResultsDataSource.h"

@interface AmazonImporterAppDelegate : NSObject
{
    IBOutlet id resultsDataSource;
    IBOutlet id resultsTable;
    IBOutlet id searchField;
    IBOutlet id localePulldown;
    IBOutlet id fieldPulldown;
}

- (IBAction)doSearch:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)viewOnline:(id)sender;
- (IBAction)clear:(id)sender;
- (void) windowWillClose:(NSNotification *) aNotification;

@end
