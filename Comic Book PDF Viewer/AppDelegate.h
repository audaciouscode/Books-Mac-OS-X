/* AppDelegate */

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface AppDelegate : NSObject
{
    IBOutlet PDFView * imageView;
    IBOutlet id nextButton;
    IBOutlet id pageScroller;
    IBOutlet id previousButton;
    IBOutlet id window;

    IBOutlet id search;

	PDFDocument * document;
	int index;

	NSString * title;
	NSUserDefaults * defaults;
	
	NSString * lastSearch;
	int lastIndex;
	NSArray * searchResults;
}

- (IBAction)nextPage:(id)sender;
- (IBAction)previousPage:(id)sender;
- (void) setPage: (int) page;
- (IBAction) openDocument:(id) sender;
- (IBAction) close:(id) sender;
- (void) openURL: (NSURL *) pdfUrl;
- (IBAction) doSearch: (id) sender;

@end
