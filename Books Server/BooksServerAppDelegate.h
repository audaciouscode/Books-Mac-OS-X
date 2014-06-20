/* BooksServerAppDelegate */

#import <Cocoa/Cocoa.h>

@interface BooksServerAppDelegate : NSObject
{
    IBOutlet id progress;

    IBOutlet id siteName;
    IBOutlet id startButton;
    IBOutlet id statusBar;
    IBOutlet id statusText;
    IBOutlet id stopButton;
    IBOutlet id browseButton;
    IBOutlet id tcpPort;
    IBOutlet id xmlFile;

	NSTask * serverTask;
}

- (IBAction)browseForXml:(id)sender;
- (IBAction)showLog:(id)sender;
- (IBAction)startServer:(id)sender;
- (IBAction)stopServer:(id)sender;
@end
