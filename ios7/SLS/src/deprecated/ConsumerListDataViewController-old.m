//
//  ConsumerListDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/15/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ConsumerListDataViewController.h"
#import "PersonalDataController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonDeleteConsumerMessage = "Yes, delete this consumer.";

@interface ConsumerListDataViewController ()
@end

@implementation ConsumerListDataViewController

@synthesize consumer = _consumer;
@synthesize delegate = _delegate;
@synthesize send_key = _send_key;
@synthesize state_change = _state_change;
@synthesize identity_label = _identity_label;
@synthesize key_deposit_label = _key_deposit_label;
@synthesize pub_key_label = _pub_key_label;
@synthesize precision_slider = _precision_slider;
@synthesize precision_label = _precision_label;
@synthesize send_key_button = _send_key_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:init: called.");
    
    if (self = [super init]) {
        _consumer = nil;
        _delegate = nil;
        _send_key = false;
        _state_change = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _consumer = nil;
        _delegate = nil;
        _send_key = false;
        _state_change = false;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    NSLog(@"ConsumerListDataViewController:viewDidLoad: TODO(aka) We need to add a \"Update Consumer as a Provider\" button!");
    
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:viewDidUnload: called.");
    
    [self setConsumer:nil];
    [self setIdentity_label:nil];
    [self setKey_deposit_label:nil];
    [self setPub_key_label:nil];
    [self setPrecision_slider:nil];
    [self setPrecision_label:nil];
    [self setSend_key_button:nil];
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:configureView: called.");
    
    _identity_label.text = _consumer.identity;
    _key_deposit_label.text = [PersonalDataController absoluteStringKeyDeposit:_consumer.key_deposit];
    _pub_key_label.text = [PersonalDataController hashAsymmetricKey:[_consumer getPublicKey]];
    
    // Setup the slider value.
    _precision_slider.value = [_consumer.precision floatValue];
    [_precision_label setText:[NSString stringWithFormat:@"%d", (int)_precision_slider.value]];
    
    if (_send_key) {
        [_send_key_button setAlpha:0.5];
    } else {
        [_send_key_button setAlpha:1.0];
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:done: called.");
    
    [[self delegate] consumerListDataViewControllerDidFinish:_consumer sendKey:_send_key];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:cancel: called.");
    
#if 0
    // TODO(aka) I'm pretty sure that no state can actually be saved in this Class, so it's not too late to cancel!
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] consumerListDataViewControllerDidCancel:self];
    }
#endif
    [[self delegate] consumerListDataViewControllerDidCancel:self];
}

- (IBAction) precisionValueChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:precisionValueChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    _consumer.precision = [NSNumber numberWithFloat:slider.value];
    
    _state_change = true;
    [self configureView];
}

- (IBAction) sendSymmetricKey:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:sendSymmetricKey: called.");
    
    if (_send_key)
        _send_key = false;
    else
        _send_key = true;
    
    _state_change = true;
    [self configureView];
}

- (IBAction) deleteConsumer:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerListDataViewController:deleteConsumer: called.");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Removal" message:@"Are you sure you want to delete this consumer?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonDeleteConsumerMessage encoding:[NSString defaultCStringEncoding]], nil];
    [alert show];
}


// Delegate functions.

// UIAlertView delegate functions.
- (void)alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonDeleteConsumerMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        [[self delegate] consumerListDataViewControllerDidDelete:_consumer];
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
}

@end
