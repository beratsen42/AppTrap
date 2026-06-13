/*
-----------------------------------------------
  APPTRAP LICENSE

  "Do what you want to do,
  and go where you're going to
  Think for yourself,
  'cause I won't be there with you"

  You are completely free to do anything with
  this source code, but if you try to make
  money on it you will be beaten up with a
  large stick. I take no responsibility for
  anything, and this license text must
  always be included.

  Markus Amalthea Magnuson <markus.magnuson@gmail.com>
-----------------------------------------------
*/

#import <PreferencePanes/PreferencePanes.h>

// NOTE: System Preference Panes are deprecated as of macOS 13 (Ventura).
// AppTrap settings are now available from the menu bar icon. This pane is
// maintained for compatibility only.

@interface ATPreferencePane : NSPreferencePane
{
    IBOutlet NSTextField *statusText;
    IBOutlet NSButton *startStopButton;
    IBOutlet NSButton *startOnLoginButton;
    IBOutlet NSTextView *aboutView;
    IBOutlet NSProgressIndicator *restartingAppTrapIndicator;
    IBOutlet NSTextField *restartingAppTrapTextField;
    IBOutlet NSWindow *appTrapRestartWindow;
}

- (void)updateStatus;
- (void)launchAppTrap;
- (void)terminateAppTrap;
- (BOOL)appTrapIsRunning;
- (void)checkBackgroundProcessVersion:(NSNotification*)notification;
- (void)checkBackgroundProcessVersion;

- (IBAction)startStopAppTrap:(id)sender;
- (IBAction)startOnLogin:(id)sender;
- (IBAction)visitWebsite:(id)sender;

@end
