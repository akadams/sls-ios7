//
//  ProviderListViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 12/3/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "ProviderListViewController.h"
#import "Principal.h"
#import "PersonalDataController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonDeleteProviderMessage = "Yes, delete this provider.";


@interface ProviderListViewController ()
@end

@implementation ProviderListViewController

#pragma mark - Inherited data
@synthesize provider_list = _provider_list;

#pragma mark - Local variables
@synthesize provider_list_changed = _provider_list_changed;

#pragma mark - Outlets
@synthesize done_button = _done_button;
@synthesize picker_view = _picker_view;
@synthesize identity_hash_label = _identity_hash_label;
@synthesize file_store_label = _file_store_label;
@synthesize pub_key_label = _pub_key_label;
@synthesize symmetric_key_label = _symmetric_key_label;
@synthesize focus_button = _focus_button;
@synthesize freq_slider = _freq_slider;
@synthesize freq_label = _freq_label;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:init: called.");
    
    if (self = [super init]) {
        _provider_list = nil;
        _current_provider = 0;
        _provider_list_changed = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _provider_list = nil;
        _current_provider = 0;
        _provider_list_changed = false;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:init: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:configureView: called.");
    
    if (_provider_list == nil || [_provider_list countOfList] == 0) {
        _identity_hash_label.text = @"";
        _pub_key_label.text = @"";
        _symmetric_key_label.text = @"";
        _file_store_label.text = @"";
        [_focus_button setEnabled:false];
        _focus_button.alpha = 0.5;
        [_freq_slider setEnabled:false];
        return;
    }
    
    // Initialize what the picker shows.
    [_picker_view selectRow:_current_provider inComponent:0 animated:YES];

    // Display the information for the selected provider.
    Principal* provider = [_provider_list objectInListAtIndex:_current_provider];
    _identity_hash_label.text = provider.identity_hash;
    _pub_key_label.text = [[provider getPublicKey] base64EncodedString];
    _symmetric_key_label.text = [provider.key base64EncodedString];
    _file_store_label.text = [provider.file_store_url absoluteString];
    
    // Setup the slider value.
    _freq_slider.value = [provider.frequency floatValue];
    [_freq_label setText:[NSString stringWithFormat:@"%ds", (int)_freq_slider.value]];
    
    // TODO(aka) Add label to display slider value (cause you really can't tell in the slider what the value is)!
    
    // Setup focus toggle button.
    if (provider.is_focus) {
        [_focus_button setTitle:@"Disable Focus" forState:UIControlStateNormal];
        _focus_button.alpha = 0.5;
    } else {
        [_focus_button setTitle:@"Make Provider Map Focus" forState:UIControlStateNormal];
        _focus_button.alpha = 1.0;
    }
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:configureView: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source

// UIPickerView.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:pickerView:numberOfRowsInComponent: called.");
    
    if (_provider_list != nil) {
        NSLog(@"ProviderListViewController:pickerView:numberOfRowsInComponent: returning %lu rows.", (unsigned long)[_provider_list countOfList]);
        
        return [_provider_list countOfList];
    } else {
        return 0;
    }
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerDataViewID"]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderListViewController:prepareForSeque: unwinding to ConsumerDataViewController.");
        
        if (sender != self.done_button) {
            // User hit CANCEL ...
            if (kDebugLevel > 3)
                NSLog(@"ProviderListViewController:prepareForSeque: User hit CANCEL (status: %d).", _provider_list_changed);
            
            // Unset any state flags, if they were set.
            if (_provider_list_changed)
                _provider_list_changed = false;
        } else {
            if (kDebugLevel > 3)
                NSLog(@"ProviderListViewController:prepareForSeque: User hit DONE.");
            
            // User hit DONE; state flags should have been set during actions, so go ahead and unwind!
        }
    } else {
        NSLog(@"ProviderListViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) toggleMapFocus:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:toggleMapFocus: called.");
    
    Principal* provider = [_provider_list objectInListAtIndex:_current_provider];
    if (provider.is_focus)
        provider.is_focus = false;
    else
        provider.is_focus = true;
    
    _provider_list_changed = true;
    
    [self configureView];
}

- (IBAction) freqValueChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:freqValueChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    Principal* provider = [_provider_list objectInListAtIndex:_current_provider];
    provider.frequency = [NSNumber numberWithFloat:slider.value];
    
    _provider_list_changed = true;
    
    [self configureView];
}

- (IBAction) deleteProvider:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:deleteProvider: called.");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Removal" message:@"Are you sure you want to delete this provider?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonDeleteProviderMessage encoding:[NSString defaultCStringEncoding]], nil];
    [alert show];
}

#pragma mark - Delegate routines

// UIPickerView delegate functions.
- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:pickerView:titleForRow:forComponent: called with row: %ld.", (long)row);
    
    return [[_provider_list objectInListAtIndex:row] identity];
}

- (void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:pickerView:didSelectRow:inComponent: called.");
    
    // Set the selected provider.
    _current_provider = row;
    
    [self configureView];
}

// UIAlertView delegate functions.
- (void)alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderListViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonDeleteProviderMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderListViewController:alertView:clickedButtonAtIndex: matched DeleteProviderMessage.");
        Principal* provider = [_provider_list objectInListAtIndex:_current_provider];
        NSString* error_msg = [_provider_list deleteProvider:provider saveState:FALSE];
        if (error_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderListViewController:clickedButtonAtIndex:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        } else {
            _current_provider = (_current_provider > 0) ? _current_provider-- : 0;
        }
        [[self picker_view] reloadAllComponents];
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderListViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ProviderListViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

@end
