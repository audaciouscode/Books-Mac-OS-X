/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
{
    IBOutlet id username;
    IBOutlet id password;

    IBOutlet id window;

    IBOutlet id comments;
    IBOutlet id tags;

    IBOutlet id tableView;

    IBOutlet id tableArray;

    IBOutlet id errorWindow;
    IBOutlet id errorText;

    IBOutlet id progressWindow;
    IBOutlet id progressBar;
}

- (IBAction) myInventory: (id)sender;
- (IBAction) upload: (id)sender;

- (NSString *) getPasswordString;
- (void) setPasswordString: (NSString *) passwordString;

@end
