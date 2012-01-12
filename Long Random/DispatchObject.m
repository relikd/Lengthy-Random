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


#import "DispatchObject.h"

@interface DispatchObject()
@property (assign) dispatch_queue_t queue;
@property (assign) float intervall;
@property (assign) NSTextField *target;
@end

@implementation DispatchObject
@synthesize queue, intervall, active, target;

- (id)init {
	self = [super init];
	if (self) {
		// initialization code here
	}
	
	return self;
}

+ (DispatchObject*)objectWithName:(char*)name target:(NSTextField*)target {
	DispatchObject *newObj = [[DispatchObject alloc]init];
	
	dispatch_queue_t newQueue = dispatch_queue_create(name, NULL);
	newObj.queue = newQueue;
	
	// value between 0.2 and 2.0 (delta -0.8/1.0)
	//                                            ┌-number of seconds added to 1.0
	//                                            |┌-use the same as the subtracted value
	//                                            ||      ┌-number of milliseconds subtracted
	newObj.intervall = 1.0f + ((int)(arc4random()%180000)-80000)/100000.0f;
	newObj.target = target;
	
	return [newObj autorelease];
}

- (BOOL)active {
	if (!self.target) return NO;
	return (self.target.tag == 0);
}

- (void)reset {
	self.target = nil;
	self.intervall = 1.0f;
	dispatch_release(self.queue);
}

@end
