/* BooksTextFieldDelegate */

#import <Cocoa/Cocoa.h>

@interface BooksTextFieldDelegate : NSObject
{
    IBOutlet id authors;
    IBOutlet id editors;
    IBOutlet id genre;
    IBOutlet id illustrators;
    IBOutlet id keywords;
    IBOutlet id translators;
    IBOutlet id publisher;

	NSMutableSet * genreSet;
	NSMutableSet * authorSet;
	NSMutableSet * illustratorSet;
	NSMutableSet * editorSet;
	NSMutableSet * translatorSet;
	NSMutableSet * keywordSet;
	NSMutableSet * publisherSet;

	NSArray * tokenList;
	NSArray * fieldList;

	NSMutableDictionary * comboArrays;
}

- (void) updateTokens;

@end
