//
//  ImportPluginInterface.h
//  Books
//
//  Created by Chris Karr on 7/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "BookManagedObject.h"

@interface ImportPluginInterface : NSObject 
{
	NSTask * importTask;
}

- (void) importFromBundle: (NSBundle *) bundle;
- (void) exitThread:(NSNotification *) note;
- (void) book:(BookManagedObject *) bookObject setValueFromString:(NSString *) valueString forKey:(NSString *) key;
@end
