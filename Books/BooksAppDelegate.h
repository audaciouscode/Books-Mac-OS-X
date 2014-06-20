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
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
#import "HtmlPageBuilder.h"
#import "ListManagedObject.h"
#import "QuickfillPluginInterface.h"
#import "PluginManager.h"
#import "QuickfillSearchWindow.h"

#import "BooksToolbarDelegate.h"
#import "BooksSpotlightInterface.h"
#import "BooksTokenViewDelegate.h"
#import "BooksTextFieldDelegate.h"
#import "BooksTableViewDelegate.h"

#import "MyBarcodeScanner.h"

#define BOOKS_SHOW_INFO @"Books - Show Info Window"
#define BOOKS_UPDATE_DETAILS @"Books - Update Details"
#define BOOKS_STOP_QUICKFILL @"Books - Stop Quickfill"
#define BOOKS_START_PROGRESS_WINDOW @"Books - Start Progress Window"
#define BOOKS_END_PROGRESS_WINDOW @"Books - End Progress Window"
#define BOOKS_HIDE_COVER @"Books - Hide Cover"
#define BOOKS_SET_CONTROL_VIEW @"Books - Set Control View"
#define BOOKS_OPEN_BOOK @"Books - Open Book"

#define IS_TEST YES

@interface BooksAppDelegate : NSObject 
{
    IBOutlet BooksToolbarDelegate * toolbarDelegate;
    IBOutlet BooksSpotlightInterface * spotlightInterface;
    IBOutlet BooksTokenViewDelegate * tokenDelegate;
	IBOutlet BooksTableViewDelegate * tableViewDelegate;
	IBOutlet BooksTextFieldDelegate * comboBoxDelegate;

    IBOutlet NSWindow * mainWindow;
    IBOutlet NSWindow * infoWindow;
    IBOutlet NSWindow * coverWindow;
    IBOutlet NSWindow * preferencesWindow;
    IBOutlet NSWindow * smartListEditorWindow;
	
	IBOutlet NSArrayController * collectionArrayController;
	IBOutlet NSArrayController * bookArrayController;
	IBOutlet NSObjectController * selectedBook;

	IBOutlet NSArrayController * cameras;

	IBOutlet WebView * detailsPane;

	IBOutlet NSSplitView * splitView;
	IBOutlet NSSplitView * leftView;
	IBOutlet NSSplitView * rightView;

	IBOutlet NSWindow * progressView;
	IBOutlet NSProgressIndicator * progressIndicator;
	IBOutlet NSTextField * progressText;
	
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;
	
	NSMutableDictionary * importPlugins;
	NSMutableDictionary * quickfillPlugins;
	NSMutableDictionary * exportPlugins;
	
	HtmlPageBuilder * pageBuilder;
	
	NSModalSession session;
	
	IBOutlet NSComboBox * userFieldCombo;
	IBOutlet NSTextField * datePublished;
	NSResponder * responder;

	IBOutlet NSTextField * dateAcquired;
	IBOutlet NSTextField * dateStarted;
	IBOutlet NSTextField * dateFinished;
	IBOutlet NSTextField * dateLent;
	IBOutlet NSTextField * dateReturned;
	
	IBOutlet NSTableColumn * finishedColumn;
	IBOutlet NSTableColumn * lentColumn;
	IBOutlet NSTableColumn * returnedColumn;

	IBOutlet NSBox * imageBox;
	IBOutlet NSImageView * imageView;

	IBOutlet NSArrayController * fileArrayController;
	IBOutlet NSTextField * fileTitle;
	IBOutlet NSTextField * fileDescription;
	IBOutlet NSTextField * fileLocation;
	IBOutlet NSImageView * fileIcon;
	NSString * fullLocation;
	
	IBOutlet NSWindow * quickfillWindow;
	IBOutlet NSProgressIndicator * quickfillProgress;
	NSModalSession modalSession;

	QuickfillPluginInterface * quickfill;

	IBOutlet QuickfillSearchWindow * quickfillResultsWindow;
	
	IBOutlet PluginManager * pluginManager;

	IBOutlet NSTextView * summary;

	NSTimer * timer;

	IBOutlet NSPanel * controlsPanel;

	IBOutlet ViewControls * defaultViewControls;
	IBOutlet ViewControls * galleryViewControls;
	
	NSMutableArray * batchArray;
	NSTimer * batchTimer;
	
	BOOL leopardOrBetter;
	
	MyBarcodeScanner * iSight;
}

- (IBAction)preferences:(id)sender;
- (IBAction)getInfoWindow:(id)sender;
- (IBAction)getCoverWindow:(id)sender;
- (void) windowWillClose: (NSNotification *) aNotification;

- (IBAction)saveAction:(id)sender;
- (IBAction) save: (id)sender;
- (IBAction)newSmartList:(id)sender;

- (NSManagedObjectModel *) managedObjectModel;
- (NSManagedObjectContext *) managedObjectContext;
- (NSWindow *) mainWindow;
- (NSWindow *) infoWindow;
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *) sender;

- (void)awakeFromNib;

- (void) updateMainPane;

- (NSArray *) getQuickfillPlugins;
- (void) setQuickfillPlugins: (NSArray *) list;
- (NSArray *) getImportPlugins;
- (void) setImportPlugins: (NSArray *) list;
- (NSArray *) getExportPlugins;
- (void) setExportPlugins: (NSArray *) list;
- (NSArray *) getDisplayStyles;
- (void) setDisplayStyles: (NSArray *) list;

- (void) initImportPlugins;
- (void) initQuickfillPlugins;
- (void) initExportPlugins;

- (IBAction)quickfill:(id)sender;

- (IBAction) newBook:(id) sender;
- (IBAction) removeBook:(id) sender;

- (IBAction) newList:(id) sender;
- (IBAction) removeList:(id) sender;

- (IBAction) editSmartList:(id) sender;
- (IBAction) saveSmartList:(id) sender;
- (IBAction) cancelSmartList:(id) sender;

- (IBAction) viewOnline:(id) sender;

- (NSArray *) getSelectedBooks;
- (NSArray *) getAllBooks;
- (NSArray *) getAllLists;
- (NSArray *) getAllSmartLists;

- (void) selectBooksTable: (id) sender;
- (void) selectListsTable: (id) sender;

- (void) endProgressWindow;
- (void) startProgressWindow: (NSString *) message;
// - (void) refreshComboBoxes:(NSTimer *) theTimer;

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;

- (ListManagedObject *) getSelectedList;
- (void) setSelectedList: (ListManagedObject *) list;

// ActionScript Methods
- (id) asCreateNewList:(NSString *) listName;
- (id) asCreateNewSmartList:(NSString *) listName;

- (NSArray *) getBooklists;

- (IBAction) listQuickfill: (id)sender;

- (IBAction) openFiles: (id) sender;
- (IBAction) trashFiles: (id) sender;
- (IBAction) uploadFile: (id) sender;
- (IBAction) browseFile: (id) sender;

- (void) startQuickfill;
- (void) stopQuickfill;
- (IBAction) cancelQuickfill: (id) sender;
- (QuickfillSearchWindow *) getQuickfillResultsWindow;

- (IBAction) import: (id)sender;
- (IBAction) isight: (id)sender;
- (IBAction) duplicateRecords:(id) sender;

- (IBAction) donate: (id)sender;
- (void) orderCoverWindowOut;

- (NSString *) getDateFormatString;
- (NSString *) getDateLentFormatString;

- (IBAction) print:(id) sender;
- (IBAction) compact:(id) sender;

- (IBAction) selectPrevious:(id) sender;
- (IBAction) selectNext:(id) sender;

- (BOOL) leopardOrBetter;

@end
