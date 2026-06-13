//
//  APTApplicationDelegate.m
//  AppTrap
//
//  Created by Kumaran Vijayan on 2013-07-31.
//

#import "APTApplicationDelegate.h"

#import "ATNotifications.h"
#import <ServiceManagement/ServiceManagement.h>

@interface APTApplicationDelegate () <NSApplicationDelegate, NSMenuDelegate>

@property (nonatomic) IBOutlet NSWindow *window;
@property (nonatomic) IBOutlet NSViewController *mainViewController;
@property (nonatomic, strong) NSStatusItem *statusItem;

@end



@implementation APTApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self.window setContentView:self.mainViewController.view];
    [self setupStatusItem];

    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self
            selector:@selector(handleToggleLoginItem:)
                name:ATApplicationToggleLoginItemNotification
              object:nil
  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
}

- (void)handleToggleLoginItem:(NSNotification *)notification
{
    if (@available(macOS 13.0, *))
    {
        SMAppService *service = [SMAppService mainAppService];
        NSError *error = nil;
        if (service.status == SMAppServiceStatusEnabled)
        {
            [service unregisterAndReturnError:&error];
        }
        else
        {
            [service registerAndReturnError:&error];
        }
        if (error)
        {
            NSLog(@"SMAppService error: %@", error);
        }
        BOOL enabled = (service.status == SMAppServiceStatusEnabled);
        NSDictionary *info = @{ATLoginItemStatusKey: @(enabled)};
        [[NSDistributedNotificationCenter defaultCenter]
            postNotificationName:ATApplicationLoginItemStatusNotification
                          object:nil
                        userInfo:info
              deliverImmediately:YES];

        // Keep menu in sync
        [self.statusItem.menu itemWithTitle:@"Start at Login"].state =
            enabled ? NSControlStateValueOn : NSControlStateValueOff;
    }
}

- (void)setupStatusItem
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSImage *icon = [NSImage imageWithSystemSymbolName:@"trash.circle" accessibilityDescription:@"AppTrap"];
    icon.template = YES;
    self.statusItem.button.image = icon;
    self.statusItem.button.toolTip = @"AppTrap";
    self.statusItem.menu = [self buildMenu];
}

- (NSMenu *)buildMenu
{
    NSMenu *menu = [[NSMenu alloc] init];
    menu.delegate = self;

    NSMenuItem *titleItem = [[NSMenuItem alloc] initWithTitle:@"AppTrap is Active" action:nil keyEquivalent:@""];
    titleItem.enabled = NO;
    [menu addItem:titleItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *loginItem = [[NSMenuItem alloc] initWithTitle:@"Start at Login"
                                                       action:@selector(toggleLoginItem:)
                                                keyEquivalent:@""];
    loginItem.target = self;
    loginItem.state = [self isLoginItemEnabled] ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:loginItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit AppTrap"
                                                      action:@selector(terminate:)
                                               keyEquivalent:@"q"];
    [menu addItem:quitItem];

    return menu;
}

- (BOOL)isLoginItemEnabled
{
    if (@available(macOS 13.0, *))
    {
        return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
    }
    return NO;
}

- (void)toggleLoginItem:(NSMenuItem *)sender
{
    if (@available(macOS 13.0, *))
    {
        SMAppService *service = [SMAppService mainAppService];
        NSError *error = nil;
        if (service.status == SMAppServiceStatusEnabled)
        {
            [service unregisterAndReturnError:&error];
        }
        else
        {
            [service registerAndReturnError:&error];
        }
        if (error)
        {
            NSLog(@"SMAppService error: %@", error);
        }
        sender.state = [self isLoginItemEnabled] ? NSControlStateValueOn : NSControlStateValueOff;
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:ATApplicationTerminatedNotification
                                      object:nil];
}

@end
