//
//  ConsumerDataExtViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ConsumerDataExtViewController.h"


const static int kDebugLevel = 2;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonGenKeysMessage = "Yes, generate new keys.";

@interface ConsumerDataExtViewController ()
@end

@implementation ConsumerDataExtViewController

@synthesize our_data = _our_data;
@synthesize provider_list_controller = _provider_list_controller;
@synthesize picker_row = _picker_row;
@synthesize fetch_data_toggle = _fetch_data_toggle;
@synthesize delegate = _delegate;
@synthesize state_change = _state_change;
@synthesize add_self_status = _add_self_status;
@synthesize gen_pub_keys_button = _gen_pub_keys_button;
@synthesize add_self_button = _add_self_button;
@synthesize toggle_fetch_data_button = _toggle_fetch_data_button;
@synthesize picker = _picker;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider_list_controller = nil;
        _picker_row = 0;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list_controller = nil;
        _picker_row = 0;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:viewDidLoad: called.");
    
   [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:viewDidUnload: called.");
    
    [self setPicker:nil];
    [self setGen_pub_keys_button:nil];
    [self setToggle_fetch_data_button:nil];
    [self setAdd_self_button:nil];
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:configureView: called.");
        
    // Tell UIPickerView to refresh its display.
    [_picker reloadAllComponents];
    
    // Set text for enabling/disabling location sharing.
    if (_fetch_data_toggle) {
        [_toggle_fetch_data_button setTitle:@"Disable Fetching Data" forState:UIControlStateNormal];
        _toggle_fetch_data_button.alpha = 0.5;
    } else {
        [_toggle_fetch_data_button setTitle:@"Enable Fetching Data" forState:UIControlStateNormal];
        _toggle_fetch_data_button.alpha = 1.0;
    }
    
    // See if we should grey out the "Add Self as Provider" button.
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
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation  {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowProviderListDataView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataExtViewController:prepareForSeque: Segue'ng to ShowProviderListDataView.");
        
        // Get the provider sets in the picker.
        Provider* tmp_provider = [_provider_list_controller objectInListAtIndex:_picker_row];
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderListDataViewController* view_controller = (ProviderListDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.provider = tmp_provider;
        view_controller.delegate = self;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataExtViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:done: called.");
    
    [[self delegate] consumerDataExtViewControllerDidFinish:_our_data providerList:_provider_list_controller fetchDataToggle:_fetch_data_toggle addSelfStatus:_add_self_status];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:cancel: called.");
    
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] consumerDataExtViewControllerDidCancel:self];
    }
}

- (IBAction)toggleFetchData:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:toggleFetchData: called.");
    
    // Set flag to tell our parent to *enable* or *disable* location data fetching.
    
    if (_fetch_data_toggle)
        _fetch_data_toggle = false;
    else
        _fetch_data_toggle = true;
    
    // _state_change = true;  // we can still back out of this change
    [self configureView];
}

- (IBAction) addSelfToProviders:(id)sender {
    _add_self_status = true;
}

- (IBAction) genPubKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:genPubKeys: called.");
    
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    if (public_key_ref != NULL)
        NSLog(@"ConsumerDataExtViewController:genPubKeys: XXX public_key_ref was *not* NULL!");
    
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    if (private_key_ref != NULL)
        NSLog(@"ConsumerDataExtViewController:genPubKeys: XXX private_key_ref was *not* NULL!");
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_our_data genAsymmetricKeys];
        _state_change = true;
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:@"Keys already exist.  Are you sure you want to generate new keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
    
    [self configureView];
}


// Data source functions.

// UIPickerView DataSource protocol.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:pickerView:numberOfRowsInComponent: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerDataExtViewController:pickerView:numberOfRowsInComponent: returning %d rows.", (int)[_provider_list_controller countOfList]);
    
    return [_provider_list_controller countOfList];
}

- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:pickerView:titleForRow:forComponent: called.");
    
    Provider* tmp_provider = [_provider_list_controller objectInListAtIndex:row];
    return tmp_provider.identity;
}


// Delegate functions.

// UIPickerView delegate functions.
-(void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:pickerView:didSelectRow:inComponent: called.");
    
    // Set our state variable (for use when we segue).
    _picker_row = row;
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataExtViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        
        [_our_data genAsymmetricKeys];
        _state_change = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataExtViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ConsumerDataExtViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

// ProviderListDataViewController delegate functions.
- (void) providerListDataViewControllerDidFinish:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:providerListDataViewControllerDidFinish: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerDataExtViewController:providerListDataViewControllerDidFinish: received provider: %s.", [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Update our provider list.
#if 0
    // XXX addProvider delete now.
    if ([_provider_list_controller containsObject:provider]) {
        NSString* error_msg = [_provider_list_controller deleteProvider:provider];
        if (error_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerDataExtViewController:providerListDataViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
    }
#endif
    
    NSString* error_msg = [_provider_list_controller addProvider:provider];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerDataExtViewController:providerListDataViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    _state_change = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

- (void) providerListDataViewControllerDidCancel:(ProviderListDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:providerListDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) providerListDataViewControllerDidDelete:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataExtViewController:providerListDataViewControllerDidDelete: called.");
    
    if (![_provider_list_controller containsObject:provider])
        return;
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerDataExtViewController:providerListDataViewControllerDidDelete: deleting provider \"%s\".", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* error_msg = [_provider_list_controller deleteProvider:provider saveState:true];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerDataExtViewController:providerListDataViewControllerDidDelete:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    _state_change = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

@end
