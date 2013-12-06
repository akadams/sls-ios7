//
//  ProviderDataExtViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ProviderDataExtViewController.h"


static const int kDebugLevel = 1;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonGenPubKeysMessage = "Yes, generate new public/private keys.";
static const char* kAlertButtonGenSymKeysMessage = "Yes, generate new symmetric keys.";

@interface ProviderDataExtViewController ()
@end

@implementation ProviderDataExtViewController

@synthesize our_data = _our_data;
@synthesize location_controller = _location_controller;
@synthesize symmetric_keys = _symmetric_keys;
@synthesize delegate = _delegate;
@synthesize state_change = _state_change;
@synthesize add_self_status = _add_self_status;
@synthesize label = _label;
@synthesize toggle_location_sharing_button = _toggle_location_sharing_button;
@synthesize toggle_power_saving_button = _toggle_power_saving_button;
@synthesize distance_filter_slider = _distance_filter_slider;
@synthesize distance_filter_label = _distance_filter_label;
@synthesize gen_pub_keys_button = _gen_pub_keys_button;
@synthesize add_self_button = _add_self_button;
@synthesize gen_sym_keys_button = _gen_sym_keys_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (void)viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void)viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:viewDidUnload: called.");
    
    [self setLabel:nil];
    [self setToggle_location_sharing_button:nil];
    [self setToggle_power_saving_button:nil];
    [self setGen_sym_keys_button:nil];
    [self setGen_pub_keys_button:nil];
    [self setDistance_filter_slider:nil];
    [self setDistance_filter_label:nil];
    [self setAdd_self_button:nil];
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:configureView: called.");
    
    // Set main title.
    [_label setText:@"Manage Location Sharing"];
    
    // Set text for enabling/disabling location sharing.
    if (_location_controller.location_sharing_toggle) {
        [_toggle_location_sharing_button setTitle:@"Disable Location Sharing" forState:UIControlStateNormal];
        _toggle_location_sharing_button.alpha = 0.5;
        
        /* XXX  A method for changing the color of a button.
         loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
         [loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
         loginButton.backgroundColor = [UIColor whiteColor];
         loginButton.layer.borderColor = [UIColor blackColor].CGColor;
         loginButton.layer.borderWidth = 0.5f;
         loginButton.layer.cornerRadius = 10.0f;
         */
    } else {
        [_toggle_location_sharing_button setTitle:@"Enable Location Sharing" forState:UIControlStateNormal];
        _toggle_location_sharing_button.alpha = 1.0;
    }
    
    // Set text for accuracy of location data (higher accuracy means more power!).
    if (_location_controller.power_saving_toggle) {
        [_toggle_power_saving_button setTitle:@"Frequent Updates" forState:UIControlStateNormal];
    } else {
        [_toggle_power_saving_button setTitle:@"Power Saving" forState:UIControlStateNormal];
    }
    
    _distance_filter_slider.value = _location_controller.distance_filter;
    [_distance_filter_label setText:[NSString stringWithFormat:@"%dm", (int)_distance_filter_slider.value]];
    
    // See if we should grey out the "add self" button.
    if (_add_self_status)
        _add_self_button.alpha = 0.5;
    else
        _add_self_button.alpha = 1.0;
    
    // See if we should grey out the gen-keys button.
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    
    if (kDebugLevel > 0) {
        if (public_key_ref == NULL)
            NSLog(@"ProviderDataExtViewController:configureView: public_key_ref is NULL!.");
        else if (private_key_ref == NULL)
            NSLog(@"ProviderDataExtViewController:configureView: private_key_ref is NULL.");
    }
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_gen_pub_keys_button setTitle:@"Generate Private/Public Keys" forState:UIControlStateNormal];
        _gen_pub_keys_button.alpha = 1.0;
    } else {
        [_gen_pub_keys_button setTitle:@"Re-generate Private/Public Keys" forState:UIControlStateNormal];
        _gen_pub_keys_button.alpha = 0.5;
    }
    
    if ([_symmetric_keys haveKeys]) {
        [_gen_sym_keys_button setTitle:@"Re-generate Symmetric Keys" forState:UIControlStateNormal];
        _gen_sym_keys_button.alpha = 0.5;
    } else {
        [_gen_sym_keys_button setTitle:@"Generate Symmetric Keys" forState:UIControlStateNormal];
        _gen_sym_keys_button.alpha = 1.0;
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:done: called.");
    
    [[self delegate] providerDataExtViewControllerDidFinish:_our_data coreLocationController:_location_controller symmetricKeys:_symmetric_keys addSelf:_add_self_status];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:cancel: called.");
    
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] providerDataExtViewControllerDidCancel:self];
    }
}

- (IBAction) toggleLocationSharing:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:toggleSharing: called.");
    
    // Set flag that will (eventually) tell our delegate to set location sharing.
    if (_location_controller.location_sharing_toggle)
        _location_controller.location_sharing_toggle = false;
    else
        _location_controller.location_sharing_toggle = true;
    
    [self configureView];
}

- (IBAction) togglePowerSaving:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:toggleAccuracy: called.");
    
    // Set flag that will (eventually) tell our delegate to set the accuracy.
    if (_location_controller.power_saving_toggle)
        _location_controller.power_saving_toggle = false;
    else
        _location_controller.power_saving_toggle = true;
    
    [self configureView];
}

- (IBAction) addSelfToConsumers:(id)sender {
    _add_self_status = true;
}

- (IBAction) genPublicKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:genPublicKeys: called.");
    
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    if (public_key_ref == NULL)
        NSLog(@"ProviderDataExtViewController:gen_keys: XXX public_key_ref was NULL!");
    if (private_key_ref == NULL)
        NSLog(@"ProviderDataExtViewController:gen_keys: XXX private_key_ref was NULL!");
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_our_data genAsymmetricKeys];
        _state_change = true;
    
        [self configureView];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:@"Keys already exist.  Are you sure you want to generate new keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenPubKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
}

- (IBAction) genSymmetricKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:genSymmetricKeys: called.");
    
    if (![_symmetric_keys haveKeys]) {
        for (int i = 0; i < kNumPrecisionLevels; ++i) {
            [_symmetric_keys genSymmetricKey:[NSNumber numberWithInt:i]];
        }
        _state_change = true;
    
        [self configureView];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Symmetric Key Generation" message:@"Keys already exist.  Are you sure you want to generate new keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenSymKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
}

- (IBAction)distanceFilterChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:distanceFilterChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    _location_controller.distance_filter = slider.value;
    _state_change = true;    
    
    [self configureView];
}


// Delegate functions.

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenPubKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: matched GenPubKeysMessage.");
        
        [_our_data genAsymmetricKeys];
        _state_change = true;
    } else if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenSymKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: matched GenSymKeysMessage.");
        // Note, since the only way we can get here is *if* the symmetric keys existed, but we want to create new ones, we need to delete the keys currently in the key-chain!
        
        for (int i = 0; i < kNumPrecisionLevels; ++i) {
            [_symmetric_keys deleteSymmetricKey:[NSNumber numberWithInt:i]];
            [_symmetric_keys genSymmetricKey:[NSNumber numberWithInt:i]];
            
            NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: TODO(aka) Either we need to return NSArray new_keys, or we need to send our all our newly generated symmetric keys in here!  Perhaps make new_keys a data member in SymmetricKeysController?");
/*            
            // Add our precision to our *new keys* list.
            [new_keys addObject:[NSNumber numberWithInt:i]];
 */
       }
        _state_change = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ProviderDataExtViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
}

@end
