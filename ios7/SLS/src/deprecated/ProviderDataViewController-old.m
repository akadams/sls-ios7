//
//  ProviderDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/16/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Class to configure the data (or information) for the provider (i.e., the person that owns the mobile device).

#import <QuartzCore/QuartzCore.h>

#import "ProviderDataViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

@implementation ProviderDataViewController

@synthesize our_data = _our_data;
@synthesize location_controller = _location_controller;
@synthesize symmetric_keys = _symmetric_keys;
@synthesize delegate = _delegate;
@synthesize state_change = _state_change;
@synthesize add_self_status = _add_self_status;
@synthesize identity_input = _identity_input;
@synthesize picker = _picker;
@synthesize setup_store_button = _setup_store_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _identity_input = nil;
        _picker = nil;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _identity_input = nil;
        _picker = nil;
        _delegate = nil;
        _state_change = false;
        _add_self_status = false;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self configureView];
}

- (void)viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setIdentity_input:nil];
    [self setPicker:nil];
    [self setSetup_store_button:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:configureView: called.");
    
    if ([_our_data.identity length])
        _identity_input.text = _our_data.identity;
    
    // Initialize what the picker shows.
    if (_picker != nil) {
        if (_our_data != nil && _our_data.file_store != nil) {
            NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
            if (service == nil) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderDataViewController:viewDidLoad: file store service not set.");
                return;
            }
            
            // Look for our current file store in the list.
            NSArray* file_stores = [PersonalDataController supportedFileStores];
            
            int i;
            for (i = 0; i < [file_stores count]; ++i) {
                if ([[file_stores objectAtIndex:i] caseInsensitiveCompare:service] == NSOrderedSame)
                    break;
            }
            
            // If we found it, set the picker's initial view to our current file store.
            
            if (i < [file_stores count]) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderDataViewController:viewDidLoad: setting picker's initial view to item %d.", i);
                
                [_picker selectRow:(NSInteger)i inComponent:0 animated:YES];
            }
        }
    }  // if (_picker != nil) {
    
    // See if we should grey out file store setup.
    if (_our_data.file_store != nil && [PersonalDataController isFileStoreComplete:_our_data.file_store]) {
        _setup_store_button.alpha = 0.5;
    } else {
        _setup_store_button.alpha = 1.0;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowFileStoreDataView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:prepareForSeque: Segue'ng to ShowFileStoreDataView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        FileStoreDataViewController* view_controller = (FileStoreDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowProviderDataExtView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:prepareForSeque: Segue'ng to ShowProviderDataExtView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderDataExtViewController* view_controller = (ProviderDataExtViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.location_controller = _location_controller;
        view_controller.symmetric_keys = _symmetric_keys;
        view_controller.add_self_status = _add_self_status;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:prepareForSegue: ShowProviderDataExtView controller's identity: %s, file-store: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction)done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:done: called.");
    
    // Note, the file store should have been set and saved in FileStoreDataViewController, and the keys would have been set (and saved) in ProviderDataExtViewController, so our identity in _our_data should be the only state we need to save.
    
    // Grab our identity and save its state.
    if (_identity_input.text != nil && [_identity_input.text length] > 0) {
        _our_data.identity = _identity_input.text;
        [_our_data saveIdentityState];
    } else {
        // TOOD(aka) I don't think this is an error, i.e., we don't *have* to change the identity, right?
        NSLog(@"ProviderDataViewController:done: WARN: identity_input is nil or empty!");
    }
    
    // Call our delegate, passing them our locally modified data.
    [[self delegate] providerDataViewControllerDidFinish:_our_data coreLocationController:_location_controller symmetricKeys:_symmetric_keys addSelf:_add_self_status];
}

- (IBAction)cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:cancel: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderDataViewController:cancel: _our_data.identity: %s.", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] providerDataViewControllerDidCancel:self];
    }
}

- (IBAction)showPeoplePicker:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:showPeoplePicker: called.");
    
    ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

// UIPickerView DataSource protocol.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:pickerView:numberOfRowsInComponent: called.");
    
    NSLog(@"ProviderDataViewController:pickerView:numberOfRowsInComponent: returning %lu rows.", (unsigned long)[[PersonalDataController supportedFileStores] count]);
    
    return [[PersonalDataController supportedFileStores] count];
}

- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:pickerView:titleForRow:forComponent: called.");
    
    return [[PersonalDataController supportedFileStores] objectAtIndex:row];
}


// Delegate functions.

// UITextField delegate functions.
- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (text_field == _identity_input) {
        [text_field resignFirstResponder];
    }
    
    return YES;
}

// ABPeoplePickerNavigationController delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
    NSString* first_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString* last_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString* middle_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    
    // Build our identity (from the contact selection).
    NSString* identity = [[NSString alloc] init];
    if (first_name != nil) {
        identity = [identity stringByAppendingFormat:@"%s", [first_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (middle_name != nil)
            identity = [identity stringByAppendingFormat:@" %s", [middle_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (last_name != nil)
            identity = [identity stringByAppendingFormat:@" %s", [last_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    } else if (last_name != nil) {
        identity = [identity stringByAppendingFormat:@"%s", [last_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    } else {
        identity = @"Unknown";
    }
    _our_data.identity = identity;
    self.identity_input.text = _our_data.identity;
 
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return YES;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
   
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

// UIPickerView delegate functions.
-(void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:pickerView:didSelectRow:inComponent: called.");
    
    NSString* service = [[PersonalDataController supportedFileStores] objectAtIndex:row];
    
    if (_our_data == nil) {
        NSLog(@"ProviderDataViewController:pickerView:didSelectRow:inComponent: TODO(aka) user selected %s, but _our_data is nil!", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return;
    }
    
    // Set our file store service value.
    [PersonalDataController setFileStore:_our_data.file_store service:service];
}

// UIAlertView delegate functions.
- (void)alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
    
    NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: TODO(aka) we don't process unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
}

// FileStoreDataViewController delegate functions.
- (void) fileStoreDataViewControllerDidFinish:(NSMutableDictionary*)file_store {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:fileStoreDataViewControllerDidFinish: called.");
    
    // Update our file store dictionary (state should've been save in segue).
    _our_data.file_store = file_store;
    _state_change = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

- (void) fileStoreDataViewControllerDidCancel:(FileStoreDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:fileStoreDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// ProviderDataExtViewController delegate functions.
- (void) providerDataExtViewControllerDidFinish:(PersonalDataController*)our_data coreLocationController:(CoreLocationController*)location_controller symmetricKeys:(SymmetricKeysController*)symmetric_keys addSelf:(BOOL)add_self {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:providerDataExtViewControllerDidFinish: called.");
    
    // Update our data members.  Note, most state should've been save in the ProviderDataExtViewController.
    _our_data = our_data;
    _location_controller = location_controller;
    _symmetric_keys = symmetric_keys;
    _add_self_status = add_self;
    _state_change = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

- (void) providerDataExtViewControllerDidCancel:(ProviderDataExtViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:providerDataExtViewControllerDidCancel: called.");

    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
