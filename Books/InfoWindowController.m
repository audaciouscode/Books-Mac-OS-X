//
//  InfoWindowController.m
//  Books
//
//  Created by Chris Karr on 4/8/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "InfoWindowController.h"
#import "NDHotKeyEvent.h"

@implementation InfoWindowController

- (void) hotKeyReleased:(NDHotKeyEvent *) aHotKey
{
	unichar character = [aHotKey character];
	
	if (character == 50)
		[tabView selectTabViewItemAtIndex:1];
	else if (character == 51)
		[tabView selectTabViewItemAtIndex:2];
	else if (character == 52)
		[tabView selectTabViewItemAtIndex:3];
	else if (character == 54)
		[tabView selectTabViewItemAtIndex:4];
	else if (character == 53)
		[tabView selectTabViewItemAtIndex:5];
	else if (character == 116)
		[tabView selectTabViewItemAtIndex:5];
	else
		[tabView selectTabViewItemAtIndex:0];
}

- (void) awakeFromNib
{
	[NDHotKeyEvent setSignature:'Boks'];
	
	NDHotKeyEvent * hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:18 character:49 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];

	hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:19 character:50 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];

	hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:20 character:51 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];
	
	hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:21 character:52 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];
	
	hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:22 character:53 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];

	hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:23 character:54 modifierFlags:NSCommandKeyMask] retain];
	[hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	[hotKey setEnabled:YES];

	// hotKey = [[NDHotKeyEvent hotKeyWithKeyCode:17 character:116 modifierFlags:NSCommandKeyMask|NSShiftKeyMask] retain];
	// [hotKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyReleased:)];
	// [hotKey setEnabled:YES];
	
}

@end
