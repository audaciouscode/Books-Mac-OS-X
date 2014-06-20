//
//  BooksTokenViewDelegate.h
//  Books
//
//  Created by Chris Karr on 7/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BooksTokenViewDelegate : NSObject 
{
	IBOutlet NSObject * booksAppDelegate;
	
	IBOutlet NSTokenField * genreTokens;
	NSMutableSet * genres;

	IBOutlet NSTokenField * authorTokens;
	NSMutableSet * authors;

	IBOutlet NSTokenField * editorTokens;
	NSMutableSet * editors;

	IBOutlet NSTokenField * illustratorTokens;
	NSMutableSet * illustrators;

	IBOutlet NSTokenField * translatorTokens;
	NSMutableSet * translators;

	IBOutlet NSTokenField * keywordTokens;
	NSMutableSet * keywords;
	
	BOOL inited;
}

- (void) updateTokens;

@end
