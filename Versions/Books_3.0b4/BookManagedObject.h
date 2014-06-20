//
//  BookManagedObject.h
//  Books
//
//  Created by Chris Karr on 10/18/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ListManagedObject.h"

@interface BookManagedObject : NSManagedObject 
{
	NSData * imageData;
	NSMutableSet * fileSet;
}

- (void) didChangeValueForKey: (NSString *) key;

- (NSString *) getObjectIdString;

//- (void) setList: (ListManagedObject *) newList;
- (void) setListName: (NSString *) listName;
- (NSString *) getListName;
- (void) writeSpotlightFile;

- (NSObject *) customValueForKey:(NSString *) key;

- (void) addNewFile: (NSString *) location title: (NSString *) title description: (NSString *) description;
- (void) removeFile: (NSDictionary *) entry;

- (NSSet *) getFiles;
- (void) setFiles:(NSSet *) fileSet;

- (NSData *) getCoverImage;
- (void) setValueFromString:(NSString *) valueString forKey:(NSString *) key replace:(BOOL) doReplace;

@end
