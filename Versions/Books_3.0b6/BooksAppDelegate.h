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

@interface BooksAppDelegate : NSObject 
{
    IBOutlet NSWindow * mainWindow;
    IBOutlet NSWindow * infoWindow;
    IBOutlet NSWindow * coverWindow;
    IBOutlet NSWindow * preferencesWindow;
    IBOutlet NSWindow * smartListEditorWindow;
	
	IBOutlet NSArrayController * collectionArrayController;

	IBOutlet NSArrayController * bookArrayController;
	IBOutlet NSObjectController * selectedBook;

	IBOutlet NSTableView * booksTable;
	IBOutlet NSTableView * listsTable;
	
	IBOutlet WebView * detailsPane;
	IBOutlet NSTableView * prefFieldsTable;
	IBOutlet NSTableColumn * enabledColumn;
	IBOutlet NSSplitView * splitView;
	IBOutlet NSSplitView * leftView;
	IBOutlet NSSplitView * rightView;

	IBOutlet NSWindow * progressView;
	IBOutlet NSProgressIndicator * progressIndicator;
	IBOutlet NSTextField * progressText;
	
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;

	NSToolbarItem * getInfo;
	NSToolbarItem * getCover;
	NSToolbarItem * editSmartList;
	NSToolbarItem * newBook;
	NSToolbarItem * removeBook;
	NSToolbarItem * removeList;

	IBOutlet NSView * searchField;
	IBOutlet NSSearchField * searchTextField;
	
	NSMutableDictionary * importPlugins;
	NSMutableDictionary * quickfillPlugins;
	NSMutableDictionary * exportPlugins;
	
	HtmlPageBuilder * pageBuilder;
	
	NSModalSession session;
	
	NSString * newTitle;
	
	NSData * loadData;
	
	IBOutlet NSComboBox * genreCombo;
	IBOutlet NSComboBox * authorsCombo;
	IBOutlet NSComboBox * editorsCombo;
	IBOutlet NSComboBox * illustratorsCombo;
	IBOutlet NSComboBox * translatorsCombo;
	IBOutlet NSComboBox * publisherCombo;
	IBOutlet NSComboBox * userFieldCombo;

	IBOutlet NSBox * imageBox;
	IBOutlet NSImageView * imageView;

	IBOutlet NSArrayController * fileArrayController;
	IBOutlet NSTextField * fileTitle;
	IBOutlet NSTextField * fileDescription;
	IBOutlet NSTextField * fileLocation;
	
	IBOutlet NSWindow * quickfillWindow;
	IBOutlet NSProgressIndicator * quickfillProgress;
	NSModalSession modalSession;

	QuickfillPluginInterface * quickfill;

	IBOutlet QuickfillSearchWindow * quickfillResultsWindow;
	
	IBOutlet PluginManager * pluginManager;

	IBOutlet NSWindow * iSightWindow;
	IBOutlet QCView * iSightView;
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

// Toolbar Methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;

- (void)awakeFromNib;

- (void) updateMainPane;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

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

- (IBAction)updateBooksTable:(id)sender;

- (IBAction) newBook:(id) sender;

- (IBAction) newList:(id) sender;
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
- (void) refreshComboBoxes: (NSArray *) books;

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;

- (ListManagedObject *) getSelectedList;
- (void) setSelectedList: (ListManagedObject *) list;

// ActionScript Methods
- (id) asCreateNewList:(NSString *) listName;
- (id) asCreateNewSmartList:(NSString *) listName;

- (NSArray *) getBooklists;

// Spotlight
- (void) loadDataFromOutside;
- (IBAction) updateSpotlightIndex: (id) sender;
- (IBAction) clearSpotlightIndex: (id) sender;

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

@end
