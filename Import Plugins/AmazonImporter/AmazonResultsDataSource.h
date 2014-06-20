/* AmazonResultsDataSource */

#import <Cocoa/Cocoa.h>

@interface AmazonResultsDataSource : NSObject
{
	NSMutableArray * hits;
}

- (AmazonResultsDataSource *) init;
- (int) numberOfRowsInTableView:(NSTableView *) aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void) clearHits;
- (NSDictionary *) getHitAtIndex:(int) index;
- (void) addXMLContents:(NSXMLDocument *) xml;

@end
