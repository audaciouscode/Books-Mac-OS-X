/* AppDelegate */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface AppDelegate : NSObject
{
    IBOutlet PDFView *pdfView;
    IBOutlet NSTableView *recordTable;
    IBOutlet NSSearchField *search;
    IBOutlet id stylesMenu;
    IBOutlet NSButton * save;
    IBOutlet NSButton * print;
    IBOutlet NSTextField * status;
	
	NSMutableDictionary * stylesTable;
	
	IBOutlet NSArrayController * records;
	
	IBOutlet NSTableColumn * titleColumn;
	IBOutlet NSTableColumn * authorsColumn;
}

- (IBAction) createPDF: (id) sender;
- (IBAction) savePDF: (id) sender;
- (IBAction) printPDF: (id) sender;

@end
