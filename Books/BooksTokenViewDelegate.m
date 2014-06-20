//
//  BooksTokenViewDelegate.m
//  Books
//
//  Created by Chris Karr on 7/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BooksTokenViewDelegate.h"
#import "BookManagedObject.h"
#import "BooksAppDelegate.h"

@implementation BooksTokenViewDelegate

- (BooksTokenViewDelegate *) init
{
	genres = nil;
	authors = nil;
	editors = nil;
	illustrators = nil;
	translators = nil;
	keywords = nil;

	inited = NO;
	
	return [super init];
}

- (void) dealloc
{
	if (genres != nil)
		[genres release];

	if (authors != nil)
		[authors release];

	if (editors != nil)
		[editors release];

	if (illustrators != nil)
		[illustrators release];
	
	if (translators != nil)
		[translators release];
	
	if (keywords != nil)
		[keywords release];

	[super dealloc];
}

- (void) setup
{
	NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@";"];

	[genreTokens setTokenizingCharacterSet:set];
	[genreTokens setCompletionDelay:0.75];
	genres = [[NSMutableSet alloc] init];

	[authorTokens setTokenizingCharacterSet:set];
	[authorTokens setCompletionDelay:0.75];
	authors = [[NSMutableSet alloc] init];

	[editorTokens setTokenizingCharacterSet:set];
	[editorTokens setCompletionDelay:0.75];
	editors = [[NSMutableSet alloc] init];

	[illustratorTokens setTokenizingCharacterSet:set];
	[illustratorTokens setCompletionDelay:0.75];
	illustrators = [[NSMutableSet alloc] init];

	[translatorTokens setTokenizingCharacterSet:set];
	[translatorTokens setCompletionDelay:0.75];
	translators = [[NSMutableSet alloc] init];

	[keywordTokens setTokenizingCharacterSet:set];
	[keywordTokens setCompletionDelay:0.75];
	keywords = [[NSMutableSet alloc] init];
	
	inited = YES;
}

- (NSArray *) getSuggestionForString: (NSString *) substring source:(NSSet *) source
{
	NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@" "];
	
	NSMutableArray * suggestions = [NSMutableArray array];

	NSArray * array = [source allObjects];
		
	int i = 0;
	for (i = 0; i < [array count]; i++)
	{
		NSString * value = (NSString *) [array objectAtIndex:i];
		
		value = [value stringByTrimmingCharactersInSet:set];

		if ([[value lowercaseString] hasPrefix:[substring lowercaseString]])
		{
			if (![suggestions containsObject:value])
				[suggestions addObject:value];
		}
	}
	
	if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
		[suggestions sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	else
		[suggestions sortUsingSelector:@selector(caseInsensitiveCompare:)];

	return suggestions;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(unsigned)index
{
	return tokens;
}

- (NSArray *) tokenField: (NSTokenField *) tokenField completionsForSubstring: (NSString *) substring indexOfToken: (int) tokenIndex
	indexOfSelectedItem: (int *) selectedIndex
{
	if (tokenField == genreTokens)
		return [self getSuggestionForString:substring source:genres];
	else if (tokenField == authorTokens)
		return [self getSuggestionForString:substring source:authors];
	else if (tokenField == editorTokens)
		return [self getSuggestionForString:substring source:editors];
	else if (tokenField == illustratorTokens)
		return [self getSuggestionForString:substring source:illustrators];
	else if (tokenField == translatorTokens)
		return [self getSuggestionForString:substring source:translators];
	else if (tokenField == keywordTokens)
		return [self getSuggestionForString:substring source:keywords];
		
	return [NSArray array] ;
}

- (void) updateTokens
{
	if (!inited)
		[self setup];

	NSArray * fields = [NSArray arrayWithObjects:@"genreArray", @"authorArray", @"editorArray", 
							@"illustratorArray", @"translatorArray", @"keywordArray", nil];
							
	NSArray * tokenArrays = [NSArray arrayWithObjects:genres, authors, editors, illustrators, translators, keywords, nil];

	int i = 0;
	for (i = 0; i < [tokenArrays count]; i++)
		[[tokenArrays objectAtIndex:i] removeAllObjects];
		
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Suppress Default Genres"])
	{
		[genres addObject:NSLocalizedString (@"Biography", nil)];
		[genres addObject:NSLocalizedString (@"Fantasy", nil)];
		[genres addObject:NSLocalizedString (@"Fairy Tales", nil)];
		[genres addObject:NSLocalizedString (@"Historical Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Myths & Legends", nil)];
		[genres addObject:NSLocalizedString (@"Poetry", nil)];
		[genres addObject:NSLocalizedString (@"Science Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Folk Tales", nil)];
		[genres addObject:NSLocalizedString (@"Mystery", nil)];
		[genres addObject:NSLocalizedString (@"Non-Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Realistic Fiction", nil)];
		[genres addObject:NSLocalizedString (@"Short Stories", nil)];
	}

	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[((BooksAppDelegate *) booksAppDelegate) managedObjectContext]]];

	NSError * error = nil;
	NSArray * books = [[((BooksAppDelegate *) booksAppDelegate) managedObjectContext] executeFetchRequest:fetch error:&error];

	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
		
		int j = 0;
		for (j = 0; j < [fields count] && j < [tokenArrays count]; j++)
		{
			NSArray * array = [book valueForKey:[fields objectAtIndex:j]];

			if (array != nil)
				[[tokenArrays objectAtIndex:j] addObjectsFromArray:array];
		}
	}
	
	[fetch release];
}

- (NSArray *) tokenField: (NSTokenField *) tokenField readFromPasteboard: (NSPasteboard *) pboard
{
	NSArray * tokens = (NSArray *) [NSUnarchiver unarchiveObjectWithData:[pboard dataForType:@"NSGeneralPboardType"]];	
	return tokens;
}


- (BOOL) tokenField:(NSTokenField *) tokenField writeRepresentedObjects:(NSArray *) objects 
	toPasteboard:(NSPasteboard *) pboard
{
	NSData * data = [NSArchiver archivedDataWithRootObject:[NSArray array]];
	[pboard declareTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"] owner:self];
	return [pboard setData:data forType:@"NSGeneralPboardType"];
}

@end
