//
//  ProviderListDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ProviderListDataViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonDeleteProviderMessage = "Yes, delete this provider.";

@interface ProviderListDataViewController ()
@end

@implementation ProviderListDataViewController

@synthesize provider = _provider;
@synthesize delegate = _delegate;
@synthesize state_change = _state_change;
@synthesize identity_label = _identity_label;
@synthesize file_store_label = _file_store_label;
@synthesize pub_key_label = _pub_key_label;
@synthesize symmetric_key_label = _symmetric_key_label;
@synthesize focus_button = _focus_button;
@synthesize freq_slider = _freq_slider;
@synthesize freq_label = _freq_label;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:init: called.");
    
    if (self = [super init]) {
        _provider = nil;
        _delegate = nil;
        _state_change = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _provider = nil;
        _delegate = nil;
        _state_change = false;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:init: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:viewDidUnload: called.");
    
    [self setProvider:nil];
    [self setIdentity_label:nil];
    [self setFile_store_label:nil];
    [self setPub_key_label:nil];
    [self setSymmetric_key_label:nil];
    [self setFocus_button:nil];
    [self setFreq_slider:nil];
    [self setFreq_label:nil];
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:configureView: called.");
    
    if (_provider == nil) {
        [_focus_button setEnabled:false];    
        _focus_button.alpha = 0.5;
        [_freq_slider setEnabled:false];
        return;
    }
    
    _identity_label.text = _provider.identity;
    _file_store_label.text = [_provider.file_store absoluteString];
    _pub_key_label.text = [[_provider getPublicKey] base64EncodedString];
    _symmetric_key_label.text = [_provider.key base64EncodedString];

    // Setup the slider value.
    _freq_slider.value = [_provider.frequency floatValue];
    [_freq_label setText:[NSString stringWithFormat:@"%ds", (int)_freq_slider.value]];
    
    // TODO(aka) And output it's value to the screen in a label (cause you really can't tell in the slider what the value is)!
    
    // Setup focus toggle button.
    if (_provider.is_focus) {
        [_focus_button setTitle:@"Disable Focus" forState:UIControlStateNormal];
        _focus_button.alpha = 0.5;
    } else {
        [_focus_button setTitle:@"Make Provider Map Focus" forState:UIControlStateNormal];
        _focus_button.alpha = 1.0;
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:done: called.");
  
    [[self delegate] providerListDataViewControllerDidFinish:_provider];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:cancel: called.");

#if 0
    // TODO(aka) I'm pretty no state can actually be saved in this Class, so it's not too late to cancel!
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] providerListDataViewControllerDidCancel:self];
    }
#endif
    [[self delegate] providerListDataViewControllerDidCancel:self];
}

- (IBAction) makeProviderFocus:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:makeProviderFocus: called.");
    
    if (_provider.is_focus)
        _provider.is_focus = false;
    else
        _provider.is_focus = true;
    
    _state_change = true;
    [self configureView];
}

- (IBAction) freqValueChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:freqValueChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    _provider.frequency = [NSNumber numberWithFloat:slider.value];
    
    _state_change = true;
    [self configureView];
}

- (IBAction) deleteProvider:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListDataViewController:deleteProvider: called.");

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Removal" message:@"Are you sure you want to delete this provider?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonDeleteProviderMessage encoding:[NSString defaultCStringEncoding]], nil];
    [alert show];
}


// Delegate functions.

// UIAlertView delegate functions.
- (void)alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonDeleteProviderMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        [[self delegate] providerListDataViewControllerDidDelete:_provider];
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
}

@end
