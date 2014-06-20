#import "CustomApplication.h"
#import "AppDelegate.h"

@implementation CustomApplication

- (void)sendEvent:(NSEvent *)event
{
	switch ([event type]) 
	{
		case NSKeyDown:
		    if ([event modifierFlags] & NSControlKeyMask) 
			{
				NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
				[nc postNotificationName:@"shortCutKey" object:event];
		    }
			
			if ([[event characters] isEqualToString:@" "] || 
				[[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSRightArrowFunctionKey]] ||
				[[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSPageDownFunctionKey]])
			{
				[((AppDelegate *) [self delegate]) nextPage:self];
				return;
			}
			else if ([[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSLeftArrowFunctionKey]] ||
				[[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSPageUpFunctionKey]])
			{
				[((AppDelegate *) [self delegate]) previousPage:self];
				return;
			}
			else if ([[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSUpArrowFunctionKey]] ||
						[[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSHomeFunctionKey]])
			{
				[((AppDelegate *) [self delegate]) setPage:0];
				return;
			}
			else if ([[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSDownArrowFunctionKey]] ||
						[[event characters] isEqualToString:[NSString stringWithFormat:@"%C", NSEndFunctionKey]])
			{
				[((AppDelegate *) [self delegate]) setPage:-1];
				return;
			}
			else if ([[event characters] isEqualToString:[NSString stringWithFormat:@"g"]])
			{
				[[NSApp delegate] doSearch:nil];
				return;
			}
			
			break;
		default:
			break;
	}
	[super sendEvent:event];
}

@end
