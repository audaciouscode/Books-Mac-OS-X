//
//  QuickFillPluginInterface.h
//  Books
//
//  Created by Chris Karr on 10/23/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BookManagedObject.h"

@interface QuickfillPluginInterface : NSObject
{
	NSTask * importTask;
	
	BookManagedObject * book;
	BOOL replace;
	
	NSString * executablePath;
}

- (void) batchImportFromBundle: (NSBundle *) bundle forBook: (BookManagedObject *) bookObject replace:(BOOL) doReplace;

- (void) importFromBundle: (NSBundle *) bundle forBook: (BookManagedObject *) book replace:(BOOL) doReplace;
- (void) killTask;

// - (void) setDataForBook: (BookManagedObject *) book fromXml:(NSXMLDocument *) xml;
- (NSXMLDocument *) getXmlDocumentForBook:(BookManagedObject *) book;

- (void) setDataForBook: (BookManagedObject *) bookObject fromXml:(NSXMLDocument *) xml;


@end
