/*
   Copyright (c) 2006 Chris J. Karr

   Permission is hereby granted, free of charge, to any person 
   obtaining a copy of this software and associated documentation 
   files (the "Software"), to deal in the Software without restriction, 
   including without limitation the rights to use, copy, modify, merge, 
   publish, distribute, sublicense, and/or sell copies of the Software, 
   and to permit persons to whom the Software is furnished to do so, 
   subject to the following conditions:

   The above copyright notice and this permission notice shall be 
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
   SOFTWARE.
*/


#import <Cocoa/Cocoa.h>
#import "ListManagedObject.h"

#define BOOK_DID_UPDATE @"Book Managed Object - Updated"

@interface BookManagedObject : NSManagedObject 
{
	NSData * imageData;
	NSMutableSet * fileSet;

	NSDateFormatter * formatter;
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
- (void) setCoverImage: (NSData *) data;
- (void) setValueFromString:(NSString *) valueString forKey:(NSString *) key replace:(BOOL) doReplace;

- (NSString *) getCoverPath;
- (void) setCoverPath:(NSString *) path;

- (NSString *) getId;
- (void) addNewCopy;

@end
