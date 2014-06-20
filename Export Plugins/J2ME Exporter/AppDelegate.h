/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
{
    IBOutlet id allRecords;
    IBOutlet id allRecordsTable;
    IBOutlet id appWindow;
    IBOutlet id createAppButton;
    IBOutlet id exportButton;
    IBOutlet id exportRecords;
    IBOutlet id exportRecordsTable;
    IBOutlet id preferences;
    IBOutlet id previewButton;
    IBOutlet id previewText;
    IBOutlet id previewWindow;
    IBOutlet id removeButton;
    IBOutlet id searchField;
    IBOutlet id statusMessage;
}

- (IBAction)createApp:(id)sender;
- (IBAction)exportItems:(id)sender;
- (IBAction)previewItems:(id)sender;
- (IBAction)removeItems:(id)sender;

- (void) awakeFromNib;

@end
