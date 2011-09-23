#import <Foundation/Foundation.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBAppSwitcherBarView.h>
#import <UIKit/UIKit.h>
#include <substrate.h>

MSHook(void, SBAppSwitcherBarView$prepareForDisplay$, SBAppSwitcherBarView *self, SEL sel, id inconnu) {
	//Let iOS prepare it's multitasking :P
	_SBAppSwitcherBarView$prepareForDisplay$(self, sel, inconnu);
	
	//Begin removing apps from multitasking (if the tweak is enabled)
	NSDictionary *prefsDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.philippe.sra.plist", NSHomeDirectory()]];
	NSArray *ignored = [prefsDict objectForKey:@"ignored"];
	NSArray *hidden = [prefsDict objectForKey:@"hidden"];
	if ([[prefsDict objectForKey:@"enabled"] boolValue]) {
		NSArray *origAppIcons = [NSArray arrayWithArray:[self appIcons]];
		id switcherModel = [objc_getClass("SBAppSwitcherModel") sharedInstance];
		for (id icon in origAppIcons) {
			if (([ignored indexOfObject:[icon leafIdentifier]] == NSNotFound && ![[[icon application] process] isRunning]) || [hidden indexOfObject:[icon leafIdentifier]] != NSNotFound) {
				if ([[[icon application] process] isRunning]) {
					[[icon application] kill];
				}
				[icon removeFromSuperview];
				[self removeIcon:icon];
				[switcherModel remove:[icon leafIdentifier]];
			}
		}
		//Save multitasking's displayed apps
		[switcherModel _saveRecents];
		
		//SwitcherPages support
		UIScrollView *&scrollView(MSHookIvar<UIScrollView*>(self, "_scrollView"));
		if ([self respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
			[self scrollViewDidEndScrollingAnimation:scrollView];
		}
	}
}

extern "C" void TweakInitialize() {
	if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/Preferences/com.philippe.sra.plist", NSHomeDirectory()]]) {
		[[NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue, @"enabled", [NSArray array], @"ignored", [NSArray array], @"hidden", nil] writeToFile:[NSString stringWithFormat:@"%@/Library/Preferences/com.philippe.sra.plist", NSHomeDirectory()] atomically:YES];
	}
	_SBAppSwitcherBarView$prepareForDisplay$ = MSHookMessage(objc_getClass("SBAppSwitcherBarView"), @selector(prepareForDisplay:), &$SBAppSwitcherBarView$prepareForDisplay$);
}