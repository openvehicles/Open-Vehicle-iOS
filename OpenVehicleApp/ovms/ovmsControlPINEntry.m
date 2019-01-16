//
//  ovmsControlPINEntry.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 3/2/12.
//  Copyright (c) 2012 Open Vehicle Systems. All rights reserved.
//

#import "ovmsControlPINEntry.h"

@implementation ovmsControlPINEntry

@synthesize delegate;

@synthesize instructions = _instructions;
@synthesize formtitle = _formtitle;
@synthesize function = _function;

@synthesize m_pin;
@synthesize m_done;
@synthesize m_message = _m_message;
@synthesize m_navbar = _m_navbar;

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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)dealloc
{
  [self setM_pin:nil];
  [self setM_done:nil];
  [self setM_message:nil];
  [self setM_navbar:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
  {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    return YES;
  else
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
  }

-(void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [m_pin becomeFirstResponder];
  self.m_message.text = _instructions;
  m_done.title = _function;
  self.m_navbar.topItem.title = _formtitle;
}

- (IBAction)Edited:(id)sender {
}

- (IBAction)Cancel:(id)sender {

  if ([self.delegate conformsToProtocol:@protocol(ovmsControlPINEntryDelegate)])
    {
    [self.delegate omvsControlPINEntryDelegateDidCancel:_function];
    }

  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)Done:(id)sender {

  if ([self.delegate conformsToProtocol:@protocol(ovmsControlPINEntryDelegate)])
    {
    [self.delegate omvsControlPINEntryDelegateDidSave:_function pin:m_pin.text];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
