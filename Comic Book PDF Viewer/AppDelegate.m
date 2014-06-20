#import "AppDelegate.h"

@implementation AppDelegate

-(void) sliderUpdate: (id) sender
{
	[self setPage:[pageScroller intValue]];
}

-(void) setPage: (int) page
{
	if (page < 0)
		page = [document pageCount] + page;
		
	index = page;
	
	if (index == 0)
		[previousButton setEnabled:NO];
	else
		[previousButton setEnabled:YES];

	if (index == [document pageCount] - 1)
		[nextButton setEnabled:NO];
	else
		[nextButton setEnabled:YES];

	PDFPage * pdfPage = nil;

	if (index < [document pageCount])
		pdfPage = [document pageAtIndex:index];
	else
		pdfPage = [document pageAtIndex:0];
	
	[imageView goToPage:pdfPage];

	[pageScroller setIntValue:page];

	[window setTitle:[NSString stringWithFormat:@"%@, Page %d - Comic Book PDF Viewer", [title lastPathComponent], page + 1, nil]];
	[window display];
}

-(IBAction) nextPage: (id) sender
{
	int page = index;
	
	if (page < [document pageCount] - 1)
		[self setPage:page + 1];
}

- (IBAction)previousPage:(id)sender
{
	int page = index;
	
	if (page > 0)
		[self setPage:page - 1];
}

- (void) awakeFromNib
{
	defaults = [NSUserDefaults standardUserDefaults];

	NSString * path = [defaults stringForKey:@"lastPath"];
	
	if (path != nil)
	{
		NSURL * pdfUrl = [NSURL fileURLWithPath:path];

		if ([[NSFileManager defaultManager] fileExistsAtPath:[pdfUrl relativePath]])
		{
			[self openURL:pdfUrl];
			
			int pageNo = [defaults integerForKey:@"lastPage"];
			[self setPage:pageNo];

			return;
		}
	}

	[self openDocument:self];
	[self setPage:0];
}

-(void) openDocument:(id) sender
{
	NSOpenPanel * panel = [NSOpenPanel openPanel];
	[panel setAllowsMultipleSelection:NO];
	
	if ([panel runModalForTypes:[NSArray arrayWithObject:@"pdf"]] == NSOKButton)
	{
		NSURL * pdfUrl = [[panel URLs] objectAtIndex:0];

		[self openURL:pdfUrl];
	}
}

- (void) openURL: (NSURL *) pdfUrl
{
	title = [[pdfUrl relativePath] retain];

	[defaults setValue:title forKey:@"lastPath"];

	if (document != nil)
		[document release];

	document = [[PDFDocument alloc] initWithURL:pdfUrl];

	[imageView setAutoScales:YES];
	[imageView setDocument:document];
	[imageView setBackgroundColor:[NSColor darkGrayColor]];
		
	if ([document pageCount] == 1)
	{
		[pageScroller setEnabled:NO];
		[pageScroller setMinValue:0.0];
		[pageScroller setMaxValue:0.0];
	}
	else
	{
		[pageScroller setEnabled:YES];
		[pageScroller setMaxValue:[document pageCount] - 1];
		[pageScroller setNumberOfTickMarks:[document pageCount]];
		[pageScroller setAllowsTickMarkValuesOnly:YES];
	}

	[self setPage:0];
		
	NSSliderCell * cell = [pageScroller cell];
	[cell setAction:@selector (sliderUpdate:)];
	[cell setTarget:self];

	[window setRepresentedFilename:title];

//	NSRect frame = [[document pageAtIndex:0] boundsForBox:kPDFDisplayBoxMediaBox];
//	frame.size.height += 40;
//	[window center];
//	[window setFrame:frame display:YES];

	[window makeKeyAndOrderFront:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[NSApp terminate:self];
}

- (IBAction) close:(id) sender
{
	[window performClose:self];
}

- (void) applicationWillTerminate: (NSNotification *) aNotification
{
	[defaults setInteger:index forKey:@"lastPage"];
}	

- (IBAction) doSearch: (id) sender
{
	NSString * searchText = [search stringValue];
	
	if ([searchText isEqualToString:lastSearch])
	{
		lastIndex++;

		if (searchResults != nil && lastIndex >= [searchResults count])
			lastIndex = 0;
	}
	else
	{
		lastSearch = [searchText copy];
		
		searchResults = [document findString:searchText withOptions:NSCaseInsensitiveSearch];
		lastIndex = 0;
	}

	PDFPage * match = nil;
	
	PDFSelection * selection = (PDFSelection *) [searchResults objectAtIndex:lastIndex];

	[imageView setCurrentSelection:selection];
		
	match = [[selection pages] objectAtIndex:0];

	[self setPage:[document indexForPage:match]];
}


@end
