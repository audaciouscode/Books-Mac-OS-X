#import "BooksTextFieldDelegate.h"
#import "BooksAppDelegate.h"

@implementation BooksTextFieldDelegate

- (BooksTextFieldDelegate *) init
{
	self = [super init];
	
	genreSet = [[NSMutableSet alloc] init];
	authorSet = [[NSMutableSet alloc] init];
	illustratorSet = [[NSMutableSet alloc] init];
	editorSet = [[NSMutableSet alloc] init];
	translatorSet = [[NSMutableSet alloc] init];
	keywordSet = [[NSMutableSet alloc] init];
	publisherSet = [[NSMutableSet alloc] init];

	comboArrays = [[NSMutableDictionary alloc] init];

	tokenList = [[NSArray alloc] initWithObjects:genreSet, authorSet, editorSet, illustratorSet, translatorSet, keywordSet, publisherSet, nil];
	fieldList = [[NSArray alloc] initWithObjects:@"genre", @"authors", @"editors", @"illustrators", @"translators", @"keywords", @"publisher", nil];
	
	return self;
}

- (void) dealloc
{
	[genreSet release];
	[authorSet release];
	[illustratorSet release];
	[editorSet release];
	[translatorSet release];
	[keywordSet release];
	[publisherSet release];

	[comboArrays release];
	[tokenList release];
	[fieldList release];
	
	[super dealloc];
}

- (void) update
{
	int i = 0;
	for (i = 0; i < [tokenList count]; i++)
		[((NSMutableSet *) [tokenList objectAtIndex:i]) removeAllObjects];

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Suppress Default Genres"])
	{
		[genreSet addObject:NSLocalizedString (@"Biography", nil)];
		[genreSet addObject:NSLocalizedString (@"Fantasy", nil)];
		[genreSet addObject:NSLocalizedString (@"Fairy Tales", nil)];
		[genreSet addObject:NSLocalizedString (@"Historical Fiction", nil)];
		[genreSet addObject:NSLocalizedString (@"Myths & Legends", nil)];
		[genreSet addObject:NSLocalizedString (@"Poetry", nil)];
		[genreSet addObject:NSLocalizedString (@"Science Fiction", nil)];
		[genreSet addObject:NSLocalizedString (@"Folk Tales", nil)];
		[genreSet addObject:NSLocalizedString (@"Mystery", nil)];
		[genreSet addObject:NSLocalizedString (@"Non-Fiction", nil)];
		[genreSet addObject:NSLocalizedString (@"Realistic Fiction", nil)];
		[genreSet addObject:NSLocalizedString (@"Short Stories", nil)];
	}
	
	NSFetchRequest * fetch = [[NSFetchRequest alloc] init];
	[fetch setEntity:[NSEntityDescription entityForName:@"Book" inManagedObjectContext:[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext]]];

	NSError * error = nil;
	NSArray * books = [[((BooksAppDelegate *) [NSApp delegate]) managedObjectContext] executeFetchRequest:fetch error:&error];
	
	for (i = 0; i < [books count]; i++)
	{
		BookManagedObject * book = (BookManagedObject *) [books objectAtIndex:i];
	
		int j = 0;
		for (j = 0; j < [fieldList count] && j < [tokenList count]; j++)
		{
			NSObject * value = [book valueForKey:[fieldList objectAtIndex:j]];
			
			if (value != nil)
				[[tokenList objectAtIndex:j] addObject:value];
		}
	}

	[fetch release];
}

- (void) updateTokens
{
	[comboArrays removeAllObjects];
	[self update];
}

- (NSArray *) getArrayForBox:(NSComboBox *) box
{
	NSArray * items = [comboArrays objectForKey:[box description]];
	
	if (items != nil)
		return items;
	else
	{
		if (box == genre)
			items = [genreSet allObjects];
		else if (box == authors)
			items = [authorSet allObjects];
		else if (box == illustrators)
			items = [illustratorSet allObjects];
		else if (box == editors)
			items = [editorSet allObjects];
		else if (box == translators)
			items = [translatorSet allObjects];
		else if (box == keywords)
			items = [keywordSet allObjects];
		else if (box == publisher)
			items = [publisherSet allObjects];
		
		if (items != nil)
		{
			if ([((BooksAppDelegate *) [NSApp delegate]) leopardOrBetter])
				items = [items sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
			else
				items = [items sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
			[comboArrays setObject:items forKey:[box description]];
		}
	}

	return items;
}

- (id) comboBox: (NSComboBox *) box objectValueForItemAtIndex:(int) index
{
	NSArray * items = [self getArrayForBox:box];
	
	return [items objectAtIndex:index];
}

- (unsigned int) comboBox:(NSComboBox *)box indexOfItemWithStringValue:(NSString *) string
{
	NSArray * items = [self getArrayForBox:box];
	
	return [items indexOfObjectIdenticalTo:string];
}

- (NSString *) comboBox:(NSComboBox *) box completedString:(NSString *) string
{
	NSArray * items = [self getArrayForBox:box];
	
	int i = 0;
	for (i = 0; i < [items count]; i++)
	{
		NSString * item = (NSString *) [items objectAtIndex:i];
		
		if ([item hasPrefix:string])
			return item;
	}

	return @"";
}

- (int)numberOfItemsInComboBox:(NSComboBox *) box
{
	NSArray * items = [self getArrayForBox:box];

	return [items count];
}

@end
