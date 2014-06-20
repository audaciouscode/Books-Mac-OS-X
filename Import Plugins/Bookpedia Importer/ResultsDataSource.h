/* resultsDataSource */

#import <Cocoa/Cocoa.h>

@interface ResultsDataSource : NSObject
{
	NSMutableArray * hits;
}

- (void) addContents:(NSDictionary *) dict;
- (ResultsDataSource *) init;
- (int) numberOfRowsInTableView:(NSTableView *) aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (NSDictionary *) getHitAtIndex:(int) index;
- (void) clearHits;

@end
