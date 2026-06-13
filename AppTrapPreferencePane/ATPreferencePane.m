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

#import "ATPreferencePane.h"
#import "ATNotifications.h"
#import "ATVariables.h"

// NOTE: System Preference Panes are deprecated as of macOS 13 (Ventura) and will
// be removed in a future release. AppTrap's settings are now also accessible from
// its menu bar icon. This pane is maintained for compatibility only.

static NSString *AppTrapBackgroundBundleIdentifier = @"com.KumaranVijayan.AppTrap";

@interface ATPreferencePane ()
@property (nonatomic) BOOL loginItemEnabled;
@end

@implementation ATPreferencePane

- (void)mainViewDidLoad
{
    NSString *appPath = [[self bundle] pathForResource:@"AppTrap" ofType:@"app"];
    NSLog(@"appPath: %@", appPath);

    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];

    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationFinishedLaunchingNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationTerminatedNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [nc addObserver:self
           selector:@selector(checkBackgroundProcessVersion:)
               name:ATApplicationGetVersionData
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [nc addObserver:self
           selector:@selector(handleLoginItemStatus:)
               name:ATApplicationLoginItemStatusNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [nc postNotificationName:ATApplicationSendVersionData
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];

    // Display readme
    [aboutView readRTFDFromFile:[[self bundle] pathForResource:@"Read Me" ofType:@"rtf"]];
    NSRange versionSymbolRange = [[aboutView string] rangeOfString:@"{APPTRAP_VERSION}"];
    if (versionSymbolRange.location != NSNotFound) {
        [[aboutView textStorage] replaceCharactersInRange:versionSymbolRange
                                              withString:[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
}

- (void)handleLoginItemStatus:(NSNotification *)notification
{
    BOOL enabled = [notification.userInfo[ATLoginItemStatusKey] boolValue];
    self.loginItemEnabled = enabled;
    [startOnLoginButton setState:enabled ? NSControlStateValueOn : NSControlStateValueOff];
}

- (void)checkBackgroundProcessVersion:(NSNotification*)notification
{
    NSString *backgroundProcessVersion = notification.userInfo[ATBackgroundProcessVersion];
    int backgroundProcessVersionInt = backgroundProcessVersion.intValue;
    NSString *prefpaneVersion = [[self bundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    int prefpaneVersionInt = prefpaneVersion.intValue;

    if (prefpaneVersionInt != backgroundProcessVersionInt)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"AppTrap";
        alert.informativeText = NSLocalizedStringFromTableInBundle(@"The background process is an older version. Would you like to restart it with the newer version?", nil, [self bundle], @"");
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Restart AppTrap", nil, [self bundle], @"")];
        [alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Don't restart AppTrap", nil, [self bundle], @"")];
        [alert beginSheetModalForWindow:startStopButton.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn)
            {
                [startStopButton setEnabled:NO];
                [restartingAppTrapIndicator startAnimation:nil];
                [restartingAppTrapTextField setHidden:NO];
                [self terminateAppTrap];
                [self performSelector:@selector(restartWithNewVersion) withObject:nil afterDelay:5];
            }
        }];
    }
}

- (void)checkBackgroundProcessVersion
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:ATApplicationSendVersionData
                                                                   object:nil
                                                                 userInfo:nil
                                                       deliverImmediately:YES];
}

- (void)restartWithNewVersion
{
    [self launchAppTrap];
    [restartingAppTrapIndicator stopAnimation:nil];
    [restartingAppTrapTextField setHidden:YES];
    [startStopButton setEnabled:YES];
}

- (void)didSelect
{
    [self updateStatus];
    [self checkBackgroundProcessVersion];
}

- (void)updateStatus
{
    if ([self appTrapIsRunning])
    {
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Active", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor labelColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Stop AppTrap", nil, [self bundle], @"")];
    }
    else
    {
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Inactive", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor secondaryLabelColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Start AppTrap", nil, [self bundle], @"")];
    }

    [self performSelector:@selector(updateStatus) withObject:nil afterDelay:5.0];
}

- (void)launchAppTrap
{
    NSString *appPath = [[self bundle] pathForResource:@"AppTrap" ofType:@"app"];
    if (!appPath) return;

    NSURL *appURL = [NSURL fileURLWithPath:appPath];
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.addsToRecentItems = NO;
    config.activates = NO;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL
                                          configuration:config
                                      completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error)
        {
            NSLog(@"Couldn't launch AppTrap: %@", error);
        }
    }];
}

- (void)terminateAppTrap
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:ATApplicationShouldTerminateNotification
                                                                   object:nil
                                                                 userInfo:nil
                                                       deliverImmediately:YES];
}

- (BOOL)appTrapIsRunning
{
    for (NSRunningApplication *application in [NSRunningApplication runningApplicationsWithBundleIdentifier:AppTrapBackgroundBundleIdentifier])
    {
        if ([application.bundleIdentifier isEqualToString:AppTrapBackgroundBundleIdentifier])
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Interface actions

- (IBAction)startStopAppTrap:(id)sender
{
    if ([self appTrapIsRunning])
    {
        [self terminateAppTrap];
    }
    else
    {
        [self launchAppTrap];
    }
}

- (IBAction)startOnLogin:(id)sender
{
    // Delegate login item management to the background process via notification,
    // since SMAppService.mainAppService can only be called from within AppTrap itself.
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:ATApplicationToggleLoginItemNotification
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}

- (IBAction)visitWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://onnati.net/apptrap/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

// Sparkle auto-update is not supported in this build.
// Update to Sparkle 2.x (https://sparkle-project.org) for arm64 support.
- (IBAction)automaticallyCheckForUpdate:(id)sender {}
- (IBAction)checkForUpdate:(id)sender {}

@end
