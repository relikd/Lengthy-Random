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


#import "LRTableView.h"

@implementation LRTableView
@synthesize delegate;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)deleteSelection
{
	[self.delegate tableView:self deleteRow:self.selectedRow];
	// Simulate a mouse click in the control.  The control is expected to
	// perform some kind of "delete" function.
	//IBOutlet NSControl* deleteControl;
	//[deleteControl performClick:self];
}

- (void)deleteBackward:(id)inSender
{
	[self deleteSelection];
}

- (void)deleteForward:(id)inSender
{
	[self deleteSelection];
}

- (void)keyDown:(NSEvent*)event
{
	BOOL deleteKeyEvent = NO;
	
	// Check if the event was a keypress that matches either the backward
	// or forward delete key.
	if ([event type] == NSKeyDown)
	{
		NSString* pressedChars = [event characters];
		if ([pressedChars length] == 1)
		{
			unichar pressedUnichar = [pressedChars characterAtIndex:0];
			
			// Test the key that was pressed. Note that this does not work with
			// custom key bindings. Ideally, NSTableView should support the delete keys
			// itself <rdar://6305317>.
			if ( (pressedUnichar == NSDeleteCharacter) || (pressedUnichar == NSDeleteFunctionKey) )
			{
				deleteKeyEvent = YES;
				
				// Additionally, it would be ideal to be able to check if 'type
				// select' is in progress and if so not treat this as a delete. The user
				// may expect the delete key to delete the last keypress of this type
				// select sequence. Type select does not work that way, but he might expect
				// it nonetheless, and we shouldn't delete his data in this case. No such
				// API exists: <rdar://6305086>.
			}
		}
	}
	
	// If it was a delete key, handle the event specially, otherwise call
	// super. In general, we want super to handle most keypresses since it
	// handles arrow keys, home, end, page up, page down, and type select.
	if (deleteKeyEvent)
	{
		// This will end up calling deleteBackward: or deleteForward:.
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
	}
	else if (self.tag == 57 && [event keyCode] == 36) {}
	else
	{
		[super keyDown:event];
	}
}

@end
