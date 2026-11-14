//
//  ovmsControlViewController.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 2/2/12.
//  Copyright (c) 2012 Open Vehicle Systems. All rights reserved.
//

#import "ovmsControlViewController.h"
#import "JHNotificationManager.h"
#import "ConnectionTypesController.h"

@implementation ovmsControlViewController
@synthesize m_chargemode;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Module control";
  self.view.backgroundColor = [UIColor colorWithRed:.047 green:.071 blue:.118 alpha:1];
  for (UIView *view in self.view.subviews)
    if ([view isKindOfClass:[UIButton class]])
      {
      UIButton *button=(UIButton *)view; button.backgroundColor=[UIColor colorWithRed:.086 green:.125 blue:.196 alpha:1]; button.layer.cornerRadius=12; button.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; button.titleLabel.adjustsFontForContentSizeCategory=YES; [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
      button.accessibilityHint=[button.currentTitle isEqualToString:@"Reset OVMS Module"] ? @"Restarts the remote vehicle module after confirmation" : [NSString stringWithFormat:@"Opens %@",button.currentTitle.lowercaseString];
      }
}

- (void)dealloc
{
  [self setM_chargemode:nil];
}

-(void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [[ovmsAppDelegate myRef] commandCancel];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)doneButton:(id)sender {
  //[self dismissModalViewControllerAnimated:YES];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)featuresButton:(id)sender {
}

- (IBAction)parametersButton:(id)sender {
}

- (IBAction)cellularUsageButton:(id)sender {
}

- (IBAction)resetModuleButton:(id)sender {
  UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Restart OVMS module?" message:@"The vehicle connection will be unavailable while the remote module restarts. This does not restart or operate the vehicle." preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Restart module" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){ [[ovmsAppDelegate myRef] commandDoReboot]; }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)handleConnections:(id)sender {
    NSLog(@"handleConnections: %@", self.carEditing);
    
    ConnectionTypesController *cnt = [[ConnectionTypesController alloc] initWithStyle:UITableViewStylePlain];
    cnt.carEditingId = self.carEditing;
    [self.navigationController pushViewController:cnt animated:YES];
}

@end
