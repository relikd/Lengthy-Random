//
//  Copyright (c) 2012 Oleg Geier
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished to do
//  so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "Long_RandomAppDelegate.h"
#import "DispatchObject.h"

@interface Long_RandomAppDelegate ()
@property (retain) NSMutableArray *gcdObjects;
@property (retain) NSTimer *stopAfter;
@property (retain) NSDate *timeSince;
@property (copy) NSString *askedQuestion;

- (void)startCalculation;
- (void)stopCalculation;
- (void)disableUI:(BOOL)disable;
- (void)timerUpdate;
- (void)executeOnQueue:(DispatchObject*)gcdObj;

- (NSString*)stringFromInteger:(NSInteger)integer;
- (NSInteger)integerFromString:(NSString*)string;
- (void)populatePopUpFromPlist:(BOOL)onStart;
- (void)fadeOutAndFadeInView:(NSView*)view;

- (NSArray*)allTextFieldsForCurrentBox;
- (NSArray*)allTextFieldsForBox:(NSBox*)box;
@end

@implementation Long_RandomAppDelegate

@synthesize window, settingsPanel;
@synthesize btn_question, btn_time, btn_go, sgmt_type, progress;
@synthesize box7, box42;
@synthesize gcdObjects, stopAfter, timeSince, askedQuestion;

static float windowHeight42 = 254.0f;
BOOL shouldRunRandom;
int timerCountdown; // needed for progress bar

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	self.gcdObjects = [NSMutableArray arrayWithCapacity:42];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"LRSettings" ofType:@"plist"];
	NSDictionary *mySettings = [NSDictionary dictionaryWithContentsOfFile:path];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:mySettings];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self populatePopUpFromPlist:YES];
	
	NSInteger modeIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"mode"]; // 7 default
	if (modeIndex >= sgmt_type.segmentCount) modeIndex = 0;
	[sgmt_type setSelectedSegment:modeIndex];
	
	[self changeMode:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	shouldRunRandom = NO; // stop all running dispatches, just in case
}

#pragma mark - IBAction

- (IBAction)unfreezeAll:(id)sender {
	[[self allTextFieldsForCurrentBox] makeObjectsPerformSelector:@selector(unfreezeValue)];
}

- (IBAction)changePopUpItem:(id)sender {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:btn_time.indexOfSelectedItem forKey:@"time"];
	[userDefaults setInteger:btn_question.indexOfSelectedItem forKey:@"query"];
	[userDefaults synchronize];
}

- (IBAction)changeMode:(id)sender {
	CGRect currentFrame = self.window.frame;
	NSInteger modeIndex = sgmt_type.selectedSegment;
	BOOL changedSomething = NO;
	
	if (modeIndex == 0 && sgmt_type.tag != 7) {
		sgmt_type.tag = 7;
		currentFrame.size.height = windowHeight42-55;
		currentFrame.origin.y += 55;
		changedSomething = YES;
		
	} else if (modeIndex == 1 && sgmt_type.tag != 42) {
		sgmt_type.tag = 42;
		currentFrame.size.height = windowHeight42;
		currentFrame.origin.y -= 55;
		changedSomething = YES;
	}
	
	if (changedSomething) {
		BOOL animating = (sender != nil); // NO = App Start
		[self.window setFrame:NSRectFromCGRect(currentFrame) display:animating animate:animating];
		
		[[self allTextFieldsForCurrentBox] makeObjectsPerformSelector:@selector(setStringValue:) withObject:@"0"];
		
		[box7 setHidden:(modeIndex!=0)];
		[box42 setHidden:(modeIndex!=1)];
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setInteger:modeIndex forKey:@"mode"];
		[userDefaults synchronize];
	}
}

- (IBAction)startRnd:(id)sender {
	BOOL start = [btn_go.image.name isEqualToString:NSImageNameRevealFreestandingTemplate];
	if (start)	[self startCalculation];
	else		[self stopCalculation];
}

#pragma mark - Start and Stop Calculation

- (void)startCalculation {
	// flash missing input
	if (btn_question.indexOfSelectedItem == -1 || btn_time.indexOfSelectedItem == -1) {
		if (btn_question.indexOfSelectedItem == -1) [self fadeOutAndFadeInView:btn_question];
		if (btn_time.indexOfSelectedItem == -1) [self fadeOutAndFadeInView:btn_time];
		return;
	}
	
	[self disableUI:YES];
	shouldRunRandom = YES;
	self.timeSince = [NSDate date];
	
	NSArray *views = [self allTextFieldsForCurrentBox];
	for (int i = 0; i < views.count; i++) {
		
		char intstr[3];
		sprintf(intstr, "%.2d", i);
		char prestr[15] = "LRNumberCalc"; // +2 places for numbers
		
		NSTextField *vw = [views objectAtIndex:i];
		if (vw.tag == 0) [vw setStringValue:[NSString stringWithFormat:@"%i", arc4random()%10]]; // just the first change
		DispatchObject *gcdObject = [DispatchObject objectWithName:strcat(prestr, intstr) target:vw];
		[gcdObjects addObject:gcdObject];
		[self executeOnQueue:gcdObject];
	}
	
	
	
	NSArray *times = [[NSUserDefaults standardUserDefaults] arrayForKey:@"times"];
	NSInteger sTime = [[times objectAtIndex:btn_time.indexOfSelectedItem] integerValue];
	
	if (stopAfter) {
		[stopAfter invalidate];
		self.stopAfter = nil;
	}
	timerCountdown = 1000;
	self.askedQuestion = btn_question.titleOfSelectedItem;
	self.stopAfter = [NSTimer scheduledTimerWithTimeInterval:sTime/1000.0f 
													  target:self selector:@selector(timerUpdate) 
													userInfo:nil repeats:YES];
	[stopAfter fire];
}

- (void)stopCalculation {
	shouldRunRandom = NO;
	if (stopAfter) {
		[stopAfter invalidate];
		self.stopAfter = nil;
	}
	
	NSInteger sum = 0;
	for (DispatchObject *obj in gcdObjects) {
		sum += [obj.target.stringValue integerValue];
	}
	
	// remove all previous dispatch objects
	[gcdObjects makeObjectsPerformSelector:@selector(reset)];
	[gcdObjects removeAllObjects];
	
	
	double timeDiff = [timeSince timeIntervalSinceNow]*-1;
	NSInteger intDiff = timeDiff;
	NSInteger milliSecs = (timeDiff-intDiff)*1000;
	NSString *title = [NSString stringWithFormat:@"Found an answer after %@", [self stringFromInteger:intDiff]];
	if (intDiff < 3660) title = [title stringByAppendingFormat:@" [%ldms]", milliSecs]; // up to 1h 59s
	
	NSArray *answers = [askedQuestion componentsSeparatedByString:@","];
	NSString *answer = [answers objectAtIndex:(sum % answers.count)];
	
	NSAlert *display = [NSAlert alertWithMessageText:title 
									   defaultButton:@"Thanks" 
									 alternateButton:nil otherButton:nil 
						   informativeTextWithFormat:answer];
	[display beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:NULL contextInfo:nil];
	
	[self disableUI:NO];
}

- (void)disableUI:(BOOL)disable {
	disable = !disable; // actually you ask which should be enabled not disabled
	[btn_question setEnabled:disable];
	[btn_time setEnabled:disable];
	[sgmt_type setEnabled:disable];
	[btn_go setKeyEquivalent:(disable ? @"\r" : @"\E")]; // assign return or ESC key
	[btn_go setImage:[NSImage imageNamed:(disable ? 
										  NSImageNameRevealFreestandingTemplate : 
										  NSImageNameStopProgressTemplate)]];
	[progress setDoubleValue:0];
}

- (void)timerUpdate {
	timerCountdown--;
	[progress setDoubleValue:(1000-timerCountdown)];
	if (timerCountdown<=0) [self stopCalculation];
}

- (void)executeOnQueue:(DispatchObject*)gcdObj {
	double delayInSeconds = gcdObj.intervall;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, gcdObj.queue, ^(void){
		if (shouldRunRandom) {
			if (gcdObj.active) [gcdObj.target setStringValue:[NSString stringWithFormat:@"%i", arc4random()%10]];
			[self executeOnQueue:gcdObj];
		}
	});
}

#pragma mark - My Methods

- (NSString*)stringFromInteger:(NSInteger)integer {
	switch (integer) {
		case 0: return @"0s";
		case 108: return @"108s";
		case 6480: return @"108m";
		case 9001: return @"Over 9000!";
		case 151200: return @"42h";
		case 388800: return @"108h";
		case 3628800: return @"42d";
		case 9331200: return @"108d";
	}
	
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSCalendarUnit units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *comps = [cal components:units
									 fromDate:[NSDate dateWithTimeIntervalSince1970:0]
									   toDate:[NSDate dateWithTimeIntervalSince1970:integer]
									  options:0];
	
	NSMutableString *form = [NSMutableString string];
	if ([comps year] > 0) [form appendFormat:@" %.ldY", [comps year]];
	if ([comps month] > 0) [form appendFormat:@" %.ldM", [comps month]];
	if ([comps day] > 0) [form appendFormat:@" %.ldd", [comps day]];
	if ([comps hour] > 0) [form appendFormat:@" %.ldh", [comps hour]];
	if ([comps minute] > 0) [form appendFormat:@" %.ldm", [comps minute]];
	if ([comps second] > 0) [form appendFormat:@" %.lds", [comps second]];
	[form deleteCharactersInRange:NSRangeFromString(@"{0, 1}")];
	
	return form;
}

- (NSInteger)integerFromString:(NSString*)string {
	NSArray *parts = [string componentsSeparatedByString:@" "];
	//if (parts.count == 1) return [string integerValue];
	NSDate *dateZero = [NSDate dateWithTimeIntervalSince1970:0];
	
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSCalendarUnit units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *comps = [cal components:units fromDate:dateZero toDate:dateZero options:0];
	
	for (NSString *str in parts) {
		char type = [str characterAtIndex:str.length-1];
		switch (type) {
			case 'Y':
			case 'y': [comps setYear:comps.year+[str integerValue]]; break;
			case 'M': [comps setMonth:comps.month+[str integerValue]]; break;
			case 'D':
			case 'd': [comps setDay:comps.day+[str integerValue]]; break;
			case 'H':
			case 'h': [comps setHour:comps.hour+[str integerValue]]; break;
			case 'm': [comps setMinute:comps.minute+[str integerValue]]; break;
			case 'S':
			case 's':
			case '0':
			case '1': // if it's a number or 's' simply add it
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9': ;
				
				NSInteger seconds = [str integerValue];
				if (seconds > 31471200) {
					NSInteger years = seconds / 31471200;
					NSInteger leftover = seconds - (years*31471200);
					[comps setYear:comps.year+years];
					seconds = leftover;
				}
				[comps setSecond:comps.second+seconds];
				
			default: break;
		}
	}
	
	return [[cal dateByAddingComponents:comps toDate:dateZero options:0] timeIntervalSince1970];
}

- (void)populatePopUpFromPlist:(BOOL)onStart {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger queryIndex, timeIndex;
	
	if (onStart) {
		queryIndex = [userDefaults integerForKey:@"query"];
		timeIndex = [userDefaults integerForKey:@"time"];
	} else {
		queryIndex = btn_question.indexOfSelectedItem;
		timeIndex = btn_time.indexOfSelectedItem;
	}
	
	NSArray *queries = [userDefaults arrayForKey:@"queries"];
	NSArray *times = [userDefaults arrayForKey:@"times"];
	
	NSMutableArray *mTimes = [NSMutableArray arrayWithCapacity:times.count];
	for (NSNumber *nm in times) {
		[mTimes addObject:[self stringFromInteger:[nm integerValue]]];
	}
	
	if (queryIndex >= queries.count) queryIndex = -1;
	if (timeIndex >= times.count) timeIndex = -1;
	
	[btn_question removeAllItems];
	[btn_time removeAllItems];
	
	[btn_question addItemsWithTitles:queries];
	[btn_time addItemsWithTitles:mTimes];
	
	[btn_question selectItemAtIndex:queryIndex];
	[btn_time selectItemAtIndex:timeIndex];
}

- (void)fadeOutAndFadeInView:(NSView*)view {
	NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
						  view, NSViewAnimationTargetKey, 
						  NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, nil];
	NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:attr]];
	[anim setDuration:0.3];
	[anim setDelegate:self];
	[anim startAnimation];
	[anim release];
}

- (void)animationDidEnd:(NSAnimation *)animation {
	NSDictionary *tmpDic = [[(NSViewAnimation*)animation viewAnimations] lastObject];
	id aniObj = [tmpDic objectForKey:NSViewAnimationEffectKey];
	
	if ([aniObj isEqual:NSViewAnimationFadeOutEffect]) {
		
		id btnObj = [tmpDic objectForKey:NSViewAnimationTargetKey];
		NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys:
							  btnObj, NSViewAnimationTargetKey,
							  NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
							  nil];
		
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:attr, nil]];
		
		[anim setDuration:animation.duration];
		[anim startAnimation];
		[anim release];
	}
}

#pragma mark - helper methods

- (NSArray*)allTextFieldsForCurrentBox {
	return [self allTextFieldsForBox:(sgmt_type.selectedSegment == 0 ? box7 : box42)];
}

- (NSArray*)allTextFieldsForBox:(NSBox*)box {
	return [[[box subviews] lastObject] subviews];
}

#pragma mark - Delegates / Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSInteger ix = tableView.tag; // 57 = Queries, 58 = Times
	if (ix==57 || ix==58) {
		NSArray *itms = [[NSUserDefaults standardUserDefaults] arrayForKey:(ix==57?@"queries":@"times")];
		return itms.count + 1;
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSInteger ix = tableView.tag; // 57 = Queries, 58 = Times
	if (ix==57) {
		
		NSArray *itms = [[NSUserDefaults standardUserDefaults] arrayForKey:@"queries"];
		if (row < itms.count)
			return [itms objectAtIndex:row];
		
	} else if (ix==58) {
		
		NSArray *itms = [[NSUserDefaults standardUserDefaults] arrayForKey:@"times"];
		if (row < itms.count) {
			NSNumber *value = [itms objectAtIndex:row];
			return [NSString stringWithFormat:@"%@ (%@)", value, [self stringFromInteger:[value integerValue]]];
		}
	}
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	BOOL hasChanges = YES;
	
	// ### ### QUERIES ### ###
	
	if (tableView.tag == 57) { 
		
		NSMutableArray *mQueries = [[userDefaults arrayForKey:@"queries"] mutableCopy];
		NSString *newObj = [object componentsJoinedByString:@","];
		
		if (row < mQueries.count && ![newObj isEqualToString:[mQueries objectAtIndex:row]]) {
			// cell do exist
			[mQueries removeObjectAtIndex:row];
			if (![newObj isEqualToString:@""]) [mQueries insertObject:newObj atIndex:row];
			
		} else if (row >= mQueries.count && newObj != nil && ![newObj isEqualToString:@""]) {
			// create new cell
			[mQueries addObject:newObj];
			
		} else {
			hasChanges = NO;
		}
		
		if (hasChanges) [userDefaults setValue:mQueries forKey:@"queries"];
		[mQueries release];
		
		
		
		// ### ### TIMES ### ###
		
	} else if (tableView.tag == 58) {
		
		NSMutableArray *mTimes = [[userDefaults arrayForKey:@"times"] mutableCopy];
		NSInteger intNewObj = [self integerFromString:object];
		NSNumber *newObj = [NSNumber numberWithInteger:intNewObj];
		
		if (row < mTimes.count && ![newObj isEqualToNumber:[mTimes objectAtIndex:row]] && intNewObj >= 0) {
			// cell do exist
			[mTimes removeObjectAtIndex:row];
			if (intNewObj > 0) [mTimes insertObject:newObj atIndex:row];
			
		} else if (row >= mTimes.count && intNewObj > 0) {
			// create new cell
			[mTimes addObject:newObj];
			
		} else {
			hasChanges = NO;
		}
		
		if (hasChanges) {
			NSMutableArray *tmpArr = [[mTimes sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				return [obj1 compare:obj2];
			}] mutableCopy];
			
			[userDefaults setObject:tmpArr forKey:@"times"];
			[tmpArr release];
		}
		[mTimes release];
	}
	
	if (hasChanges) {
		[userDefaults synchronize];
		[tableView reloadData];
		[self populatePopUpFromPlist:NO];
	}
}

- (void)tableView:(NSTableView *)tableView deleteRow:(NSInteger)row
{
	NSInteger ix = tableView.tag; // 57 = Queries, 58 = Times
	if (ix==57 || ix==58) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSString *tableName = (ix==57?@"queries":@"times");
		
		NSArray *itms = [userDefaults arrayForKey:tableName];
		if (row >= itms.count || row < 0) return;
		
		NSMutableArray *mItms = [itms mutableCopy];
		[mItms removeObjectAtIndex:row];
		[userDefaults setObject:mItms forKey:tableName];
		[mItms release];
		
		[userDefaults synchronize];
		[tableView reloadData];
		[self populatePopUpFromPlist:NO];
	}
}

- (void)dealloc
{
	askedQuestion = nil;
	[gcdObjects release];
	[super dealloc];
}

@end
