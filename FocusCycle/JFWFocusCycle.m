//
//  CycleWindows.m
//  CycleWindows
//
//  Created by Julian Weinert on 07/08/16.
//  Copyright © 2016 Julian Weinert Softwareentwicklung. All rights reserved.
//

#import "JFWFocusCycle.h"
#include <Carbon/Carbon.h>

CFStringRef createStringForKey(CGKeyCode keyCode) {
	TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
	CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
	const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
	
	UInt32 keysDown = 0;
	UniChar chars[4];
	UniCharCount realLength;
	
	UCKeyTranslate(keyboardLayout,
				   keyCode,
				   kUCKeyActionDisplay,
				   0,
				   LMGetKbdType(),
				   kUCKeyTranslateNoDeadKeysBit,
				   &keysDown,
				   sizeof(chars) / sizeof(chars[0]),
				   &realLength,
				   chars);
	
	CFRelease(currentKeyboard);
	
	return CFStringCreateWithCharacters(kCFAllocatorDefault, chars, 1);
}

@interface JFWFocusCycle () <NSMenuDelegate>

@property (nonatomic, retain) NSMenuItem *previousWindowItem;
@property (nonatomic, retain) NSMenuItem *nextWindowItem;

@end

static JFWFocusCycle *sharedPlugin;

@implementation JFWFocusCycle

#pragma mark - Initialization

+ (void)pluginDidLoad:(NSBundle *)plugin {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.dt.Xcode"]) {
		sharedPlugin = [[self alloc] initWithBundle:plugin];
	}
}

+ (instancetype)sharedPlugin {
	return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)bundle {
	if (self = [super init]) {
		_bundle = bundle;
		
		if (NSApp && ![NSApp mainMenu]) {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(applicationDidFinishLaunching:)
														 name:NSApplicationDidFinishLaunchingNotification
													   object:nil];
		}
		else {
			[self initialize];
		}
	}
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
	[self initialize];
}

#pragma mark - Implementation

- (BOOL)initialize {
	NSMenuItem *windowMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
	NSMenu *windowSubMenu = [windowMenuItem submenu];
	
	if (windowSubMenu) {
		NSUInteger separatorIndex = [[windowMenuItem submenu] indexOfItemWithTitle:@"Show Previous Tab"] + 1;
		[windowSubMenu insertItem:[NSMenuItem separatorItem] atIndex:separatorIndex];
		
		int keyID = KBGetLayoutType(LMGetKbdType()) == kKeyboardISO ? kVK_ISO_Section : kVK_ANSI_Grave;
		NSString *keyEquivalent = (__bridge NSString *)createStringForKey(keyID);
		
		[self setPreviousWindowItem:[[NSMenuItem alloc] initWithTitle:@"Focus Previous Window" action:@selector(focusPreviousWindow) keyEquivalent:keyEquivalent]];
		[self setNextWindowItem:[[NSMenuItem alloc] initWithTitle:@"Focus Next Window" action:@selector(focusNextWindow) keyEquivalent:keyEquivalent]];
		
		[[self previousWindowItem] setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
		[[self nextWindowItem] setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		[[self previousWindowItem] setTarget:self];
		[[self nextWindowItem] setTarget:self];
		
		[[windowMenuItem submenu] insertItem:[self previousWindowItem] atIndex:++separatorIndex];
		[[windowMenuItem submenu] insertItem:[self nextWindowItem] atIndex:++separatorIndex];
		
		return YES;
	}
	else {
		return NO;
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (menuItem == [self previousWindowItem]) {
		NSUInteger keyIndex = [[self windows] indexOfObject:[NSApp keyWindow]];
		return keyIndex != NSNotFound && keyIndex > 0;
	}
	else if (menuItem == [self nextWindowItem]) {
		NSUInteger keyIndex = [[self windows] indexOfObject:[NSApp keyWindow]];
		return keyIndex != NSNotFound && keyIndex < ([[self windows] count] - 1);
	}
	return NO;
}

- (void)focusPreviousWindow {
	NSUInteger previousIndex = [[self windows] indexOfObject:[NSApp keyWindow]] - 1;
	
	if (previousIndex != NSNotFound) {
		[[[self windows] objectAtIndex:previousIndex] makeKeyAndOrderFront:NSApp];
	}
}

- (void)focusNextWindow {
	NSUInteger nextIndex = [[self windows] indexOfObject:[NSApp keyWindow]] + 1;
	
	if (nextIndex != NSNotFound) {
		[[[self windows] objectAtIndex:nextIndex] makeKeyAndOrderFront:NSApp];
	}
}

- (NSArray<NSWindow *> *)windows {
	return [[NSApp windows] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isVisible=YES"]];
}

@end
