/* QuickfillSearchWindow */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface QuickfillSearchWindow : NSObject
{
    IBOutlet id data;
    IBOutlet NSPopUpButton *dataSource;
    IBOutlet WebView *details;
    IBOutlet NSTableView *list;
    IBOutlet NSPanel *panel;
    IBOutlet id statusSpinner;
    IBOutlet id statusText;
    IBOutlet id quickfillResults;
	
	NSString * pluginName;
}

- (IBAction) doSave: (id) sender;
- (IBAction) doSearch: (id) sender;
- (IBAction)doCancel:(id)sender;

- (NSArrayController *) getArrayController;

- (void) showResults;
- (void) setPluginName: (NSString *) name;
- (void) tableViewSelectionDidChange: (NSNotification *) aNotification;

@end
