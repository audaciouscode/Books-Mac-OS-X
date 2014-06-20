/* TemplateExporter */

#import <Cocoa/Cocoa.h>

@interface TemplateExporter : NSObject
{
    IBOutlet id menu;
    IBOutlet id progressIndicator;
    IBOutlet id progressWindow;
    IBOutlet id quitMenuItem;
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification;

@end
