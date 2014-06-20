/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
{
    IBOutlet id accessoryView;
    IBOutlet id webView;
    IBOutlet id webViewWindow;
}

- (void) awakeFromNib;

@end
