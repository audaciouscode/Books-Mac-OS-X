/* AppDelegate */

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject
{
    IBOutlet id password;
    IBOutlet id source;
    IBOutlet id tableView;
    IBOutlet id username;

    IBOutlet id tableArray;
}

- (IBAction) myInventory: (id)sender;
- (IBAction) upload: (id)sender;

- (NSString *) getPasswordString;
- (void) setPasswordString: (NSString *) passwordString;

@end
