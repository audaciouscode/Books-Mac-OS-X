/* TemplateImporterAppDelegate */

#import <Cocoa/Cocoa.h>
#import "ResultsDataSource.h"

@interface TemplateImporterAppDelegate : NSObject
{
    IBOutlet id aboutMenuItem;
    IBOutlet id quitMenuItem;
    ResultsDataSource * resultsDataSource;
    IBOutlet id resultsTable;
    IBOutlet id searchField;
    IBOutlet id searchQuery;
    IBOutlet id topMenuItem;
    IBOutlet id hideMenuItem;
    IBOutlet id helpMenuItem;
    IBOutlet id mainWindow;
}

- (IBAction)export:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)clear:(id)sender;

- (void) windowDidBecomeKey:(NSNotification *) aNotification;
- (void) windowWillClose:(NSNotification *) aNotification;

@end
