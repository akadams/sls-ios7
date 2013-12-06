//
//  ConsumerDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/16/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//
//  Class to configure the data (or information) for the provider (i.e., the person that owns the mobile device).

#import "ConsumerDataViewController.h"


static const int kDebugLevel = 4;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonGenKeysMessage = "Yes, generate new keys.";

@implementation ConsumerDataViewController

#pragma mark - Inherited Data
@synthesize our_data = _our_data;
@synthesize provider_list_controller = _provider_list_controller;
@synthesize fetch_data_toggle = _fetch_data_toggle;

#pragma mark - Our Data
@synthesize delegate = _delegate;
@synthesize identity_changed = _identity_changed;
@synthesize pub_keys_changed = _pub_keys_changed;
@synthesize deposit_changed = _deposit_changed;
@synthesize fetch_toggle_changed = _fetch_toggle_changed;
@synthesize add_self_status = _add_self_status;

#pragma mark - Outlets
@synthesize identity_label = _identity_label;
@synthesize identity_hash_label = _identity_hash_label;
@synthesize address_label = _address_label;
@synthesize pub_hash_label = _pub_hash_label;
@synthesize map_focus_label = _map_focus_label;
@synthesize gen_pub_keys_button = _gen_pub_keys_button;
@synthesize add_self_button = _add_self_button;
@synthesize fetch_data_switch = _fetch_data_switch;
@synthesize done_button = _done_button;

/* XXX
 @synthesize identity_input = _identity_input;
 @synthesize picker = _picker;
 @synthesize setup_deposit_button = _setup_deposit_button;
*/

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider_list_controller = nil;
        _delegate = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _add_self_status = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _address_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _add_self_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
    
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list_controller = nil;
        _delegate = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _add_self_status = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _address_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _add_self_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list_controller = nil;
        _delegate = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _add_self_status = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _address_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _add_self_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
}

#pragma mark - Managing Views

- (void)viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:init: called.");
    
    // Note, this is where we clean up any *strong* references.
    // XXX
    /*
    [self setIdentity_input:nil];
    [self setPicker:nil];
    [self setSetup_deposit_button:nil];
     */
    [super viewDidUnload];
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:configureView: called.");
    
    // Show our identity.
    if (_our_data != nil && [_our_data.identity length]) {
        NSLog(@"ConsumerDataViewController:configureView: setting identity: %@.", _our_data.identity);
        [_identity_label setText:_our_data.identity];
        [_identity_hash_label setText:_our_data.identity_hash];
    } else {
        [_identity_label setText:@""];
        [_identity_hash_label setText:@""];
    }
    
    // And our deposit.
    if (_our_data != nil && _our_data.key_deposit != nil && [PersonalDataController isKeyDepositComplete:_our_data.key_deposit]) {
        // Note, if we ever go back to e-mail file-store deposits, then we'd need to change this!
        NSLog(@"ConsumerDataViewController:configureView: setting deposit: %@.", [PersonalDataController getKeyDepositPhoneNumber:_our_data.key_deposit]);
        _address_label.text = [PersonalDataController getKeyDepositPhoneNumber:_our_data.key_deposit];
    } else {
        _address_label.text = @"";
    }
    
    // Initialize what the picker shows.
    // XXX
    /*
    if (_picker != nil) {
        if (_our_data != nil && _our_data.key_deposit != nil) {
            NSString* type = [PersonalDataController getKeyDepositType:_our_data.key_deposit];
            if (type == nil) {
                if (kDebugLevel > 0)
                    NSLog(@"ConsumerDataViewController:viewDidLoad: file store service not set.");
                return;
            }
            
            // Look for our current file store in the list.
            NSArray* key_deposits = [PersonalDataController supportedKeyDeposits];
            
            int i;
            for (i = 0; i < [key_deposits count]; ++i) {
                if ([[key_deposits objectAtIndex:i] caseInsensitiveCompare:type] == NSOrderedSame)
                    break;
            }
            
            // If we found it, set the picker's initial view to our current file store.
            
            if (i < [key_deposits count]) {
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerDataViewController:viewDidLoad: setting picker's initial view to item %d.", i);
                
                [_picker selectRow:(NSInteger)i inComponent:0 animated:YES];
            }
        }
    }  // if (_picker != nil) {
    */
    
   // See if we should grey out the gen-keys button.
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    
    if (kDebugLevel > 0) {
        if (public_key_ref == NULL)
            NSLog(@"ConsumerDataViewController:configureView: public_key_ref is NULL!.");
        else if (private_key_ref == NULL)
            NSLog(@"ConsumerDataViewController:configureView: private_key_ref is NULL.");
    }
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_gen_pub_keys_button setTitle:@"Generate Private/Public Keys" forState:UIControlStateNormal];
        _gen_pub_keys_button.alpha = 1.0;
        _pub_hash_label.text = @"";
    } else {
        [_gen_pub_keys_button setTitle:@"Re-generate Private/Public Keys" forState:UIControlStateNormal];
        _gen_pub_keys_button.alpha = 0.5;
        _pub_hash_label.text = [PersonalDataController hashSHA256Data:[_our_data getPublicKey]];
    }
    
    // See what position to put the fetch_data_switch in.
    if (_fetch_data_toggle)
        [_fetch_data_switch setOn:YES];
    else
        [_fetch_data_switch setOn:NO];

    // See if we should grey out the "Add Self as Provider" button.
    if (_add_self_status)
        _add_self_button.alpha = 0.5;
    else
        _add_self_button.alpha = 1.0;

    if (kDebugLevel > 3)
        NSLog(@"ConsumerDataViewController:configureView: exiting.");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
     if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:prepareForSeque: called.");
    
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:prepareForSeque: Segue'ng to ShowConsumerMasterView.");
    if (sender != self.done_button) {
        // User hit CANCEL ...
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:prepareForSeque: User hit CANCEL (pub_keys_chanaged: %d).", _pub_keys_changed);
        
        if (_pub_keys_changed) {
            // Note, asymmetric keys, if generated, would already have been saved in genPubKeys(), so if the user is requesting to cancel, point out to them that that was non-reverting action.
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Note, asymmetric key (re)generation is irreversible." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
        
        // Unset any state flags, if they were set.
        if (_identity_changed)
            _identity_changed = false;
        if (_deposit_changed)
            _deposit_changed = false;
        if (_fetch_toggle_changed)
            _fetch_toggle_changed = false;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:prepareForSeque: User hit DONE.");
        
        // User hit DONE; state flags should have been set during actions, so go ahead and unwind!
    }
    
    /*  XXX No longer necessary, as we always segue to exit
     if ([[segue identifier] isEqualToString:@"ShowConsumerMasterView"]) {
     } else if ([[segue identifier] isEqualToString:@"ShowKeyDepositDataView"]) {
     if (kDebugLevel > 0)
     NSLog(@"ConsumerDataViewController:prepareForSeque: Segue'ng to ShowKeyDepositDataView.");
     
     // Send *our data* and set ourselves up as the delegate.
     UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
     KeyDepositDataViewController* view_controller = (KeyDepositDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
     view_controller.our_data = _our_data;
     view_controller.delegate = self;
     } else if ([[segue identifier] isEqualToString:@"ShowConsumerDataExtView"]) {
     if (kDebugLevel > 0)
     NSLog(@"ConsumerDataViewController:prepareForSeque: Segue'ng to ShowConsumerDataExtView.");
     
     // Send *our data* and set ourselves up as the delegate.
     UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
     ConsumerDataExtViewController* view_controller = (ConsumerDataExtViewController*)[[nav_controller viewControllers] objectAtIndex:0];
     view_controller.our_data = _our_data;
     view_controller.provider_list_controller = _provider_list_controller;
     view_controller.fetch_data_toggle = _fetch_data_toggle;
     view_controller.add_self_status = _add_self_status;
     view_controller.delegate = self;
     } else {
     if (kDebugLevel > 0)
     NSLog(@"ConsumerDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
     }
     */
}

#pragma mark - TableView Data Source

/* Disabled because we are using static cells.
 - (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
 if (kDebugLevel > 2)
 NSLog(@"ConsumerDataViewController:numberOfSectionsInTableView: TODO(aka) not implemented correctly!");
 
 return 6;  // return number of sections
 }
 
 - (NSInteger) tableView:(UITableView*)table_view numberOfRowsInSection:(NSInteger)section {
 if (kDebugLevel > 2)
 NSLog(@"ConsumerDataViewController:tableView:numberOfRowsInSection:%ld called.", (long)section);
 
 switch (section) {
 case 0: return 2;
 break;
 case 1: return 2;
 break;
 case 2: return 1;
 break;
 case 3: return 1;
 break;
 case 4: return 1;
 break;
 case 5: return 1;
 break;
 case 6: return 1;
 break;
 default:
 break;
 }
 
 return 0;
 }
 
 - (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
 if (kDebugLevel > 2)
 NSLog(@"ConsumerDataViewController:cellForRowAtIndexPath: called.");
 
 UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
 // XXX cell.accessoryType = UITableViewCellAccessoryNone;
 
 NSUInteger section = [indexPath section];
 NSUInteger row = [indexPath row];
 
 NSLog(@"ConsumerDataViewController:cellForRowAtIndexPath: Configuring row %ld in section %ld.", (long)row, (long)section);
 
 // Configure the cell...
 switch (section) {
 break;
 }
 
 return cell;
 }
 */

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:didSelectRowAtIndexPath: called.");
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    NSLog(@"ConsumerDataViewController:didSelectRowAtIndexPath: Configuring row %ld in section %ld.", (long)row, (long)section);
    
    if (section == 0 && row == 0) {
        // First cell; request authorization to Address Book
        ABAddressBookRef address_book_ref = ABAddressBookCreateWithOptions(NULL, NULL);
        
        __block BOOL access_explicitly_granted = NO;
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            // XXX if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
            dispatch_semaphore_t status = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(address_book_ref,
                                                     ^(bool granted, CFErrorRef error) {
                                                         access_explicitly_granted = granted;
                                                         dispatch_semaphore_signal(status);
                                                     });
            dispatch_semaphore_wait(status, DISPATCH_TIME_FOREVER);  // wait until user gives us access
        }
        
        if (!access_explicitly_granted &&
            ((ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ||
             (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined))) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Unable to set identity without access to Address Book." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;
            }
        
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark - Actions

// XXX Deprecated.
- (IBAction) showAddressBook:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:showAddressBook: called.");
    
    // Request authorization to Address Book
    ABAddressBookRef address_book_ref = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block BOOL access_explicitly_granted = NO;
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        // XXX if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
        dispatch_semaphore_t status = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(address_book_ref,
                                                 ^(bool granted, CFErrorRef error) {
                                                     access_explicitly_granted = granted;
                                                     dispatch_semaphore_signal(status);
                                                 });
        dispatch_semaphore_wait(status, DISPATCH_TIME_FOREVER);  // wait until user gives us access
    }
    
    if (!access_explicitly_granted &&
        ((ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ||
         (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined))) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Unable to set identity without access to Address Book." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        return;
    }

    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction) toggleFetchData:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:toggleFetchData: called.");
    
    // Set flag to tell our parent to *enable* or *disable* location data fetching.
    if (_fetch_data_toggle && !_fetch_data_switch.on) {
        _fetch_data_toggle = false;
        _fetch_toggle_changed = true;
    } else if (!_fetch_data_toggle && _fetch_data_switch.on) {
        _fetch_data_toggle = true;
        _fetch_toggle_changed = true;
    }
    
    [self configureView];
}

- (IBAction) genPubKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:genPubKeys: called.");
    
    NSLog(@"ConsumerDataViewController:genPubKeys: Not doing anything yet!");

    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    if (public_key_ref != NULL)
        NSLog(@"ConsumerDataViewController:genPubKeys: XXX public_key_ref was *not* NULL!");
    
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    if (private_key_ref != NULL)
        NSLog(@"ConsumerDataViewController:genPubKeys: XXX private_key_ref was *not* NULL!");
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_our_data genAsymmetricKeys];
        _pub_keys_changed = true;
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:@"Keys already exist.  Are you sure you want to overwrite old keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
    
    [self configureView];
}

// XXX TODO(aka) I dont' think we want this routine, as it makes more sense for the Provider to add itself as a consumer, not the other way around (i.e., how do we know the file-store is setup?).
- (IBAction) addSelfToProviders:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:addSelfToProviders: called.");
    
    NSLog(@"ConsumerDataViewController:addSelfToProviders: Not doing anything yet!");
    
}

/*
- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:done: called.");
    
    // Note, the key deposit should have been set and saved in KeyDepositDataViewController, and any keys would have been set (and saved) in ConsumerDataExtViewController and the provider list controller in ProviderListDataViewController, so our identity in _our_data should be the only state we need to worry about.
    
    // Grab our identity and save its state.
    if (_identity_input.text != nil && [_identity_input.text length] > 0) {
        _our_data.identity = _identity_input.text;
        _our_data.identity_hash = [PersonalDataController hashMD5String:_our_data.identity];
        [_our_data saveIdentityState];
    } else {
        // TOOD(aka) I don't think this is an error, i.e., we don't *have* to change the identity, right?
        NSLog(@"ConsumerDataViewController:done: WARN: identity_input is nil or empty!");
    }
    
    // Call our delegate, passing them ourselves.
    [[self delegate] consumerDataViewControllerDidFinish:_our_data providerList:_provider_list_controller fetchDataToggle:_fetch_data_toggle addSelfStatus:_add_self_status];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:cancel: called.");
    
    if (_state_change) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Changes have already been made, you must select DONE to leave." delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        [[self delegate] consumerDataViewControllerDidCancel:self];
    }
}

- (IBAction) showPeoplePicker:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:showPeoplePicker: called.");
    
    ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];    
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}
*/

#pragma mark - Data Source Routines

// UITableView data source functions.


/*
 - (UITableViewCell*) tableView:(UITableView*)table_view cellForRowAtIndexPath:(NSIndexPath*)index_path {
 if (kDebugLevel > 2)
 NSLog(@"ConsumerDataViewController:tableView:cellForRowAtIndexPath: called.");
 
 Consumer* consumer = [_consumer_list_controller objectInListAtIndex:index_path.row];
 
 NSLog(@"ConsumerDataViewController:tableView:cellForRowAtIndexPath: working on cell with consumer: %s, precision: %d, with index path: %ld.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue], (long)index_path.row);
 
 #if 0  // XXX Old way where we coudn't get slider to work.
 static NSString* cell_identifier = @"ConsumerCell";
 UITableViewCell* cell =
 [table_view dequeueReusableCellWithIdentifier:cell_identifier];
 UILabel* label = (UILabel*)[cell viewWithTag:1];  // 1 is set in IB
 label.text = consumer.identity;
 // label.tag = index_path.row;
 
 UISlider* slider = (UISlider*)[cell viewWithTag:2];  // 2 is set in IB
 slider.value = (float)[consumer.precision floatValue];
 NSLog(@"ConsumerDataViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %d.", index_path.row);
 slider.tag = index_path.row;
 #endif
 
 static NSString* cell_identifier = @"ConsumerCell";
 static NSString* cell_nib = @"ConsumerCell";
 
 ConsumerCellController* cell = (ConsumerCellController*)[table_view dequeueReusableCellWithIdentifier:cell_identifier];
 if (cell == nil) {
 NSArray* nib_objects = [[NSBundle mainBundle] loadNibNamed:cell_nib owner:self options:nil];
 cell = (ConsumerCellController*)[nib_objects objectAtIndex:0];
 cell.delegate = self;
 // XXX Do I need to nil out our view?
 }
 
 // Add data to cell.
 cell.label.text = consumer.identity;
 cell.label.tag = index_path.row;
 
 cell.slider.value = (float)[consumer.precision floatValue];
 NSLog(@"ConsumerDataViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %ld.", (long)index_path.row);
 cell.slider.tag = index_path.row;
 
 // For now, give button a label representing our tag number.
 NSString* button_title = [[NSString alloc] initWithFormat:@"%ld", (long)index_path.row];
 [cell.button setTitle:button_title forState:UIControlStateNormal];
 cell.button.tag = index_path.row;
 
 return cell;
 }
 */

// UIPickerView DataSource protocol.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:pickerView:numberOfRowsInComponent: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerDataViewController:pickerView:numberOfRowsInComponent: returning %lu rows.", (unsigned long)[[PersonalDataController supportedKeyDeposits] count]);
    
    return [[PersonalDataController supportedKeyDeposits] count];
}

- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:pickerView:titleForRow:forComponent: called.");
    
    return [[PersonalDataController supportedKeyDeposits] objectAtIndex:row];
}


#pragma mark - Delegate Routines

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
    NSString* first_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString* last_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString* middle_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    
    // Get our identity (from the contact selection) ...
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
    
    // ... and load it into our PersonalDataController.
    _our_data.identity = identity;
    _our_data.identity_hash = [PersonalDataController hashMD5String:_our_data.identity];
    _identity_changed = true;
    
    // Next, get the mobile phone number associated with this person (hopefully, us!).
    
    // TODO(aka) What we really want to do here is (i) load all the phone numbers in for this person and use them in a UIPickerView when the user taps on the next row.  This would allow for the case where they failed to set their mobile label, but would require us to keep this state around (or I guess we could simply get it from our AddressBook in our UIPickerView:shouldContinueAfterSelecting routine ...
    
    ABMultiValueRef phone_numbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSString* mobile_number = nil;
    NSString* phone_label = nil;
    for (CFIndex i = 0; i < ABMultiValueGetCount(phone_numbers); ++i) {
        phone_label = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phone_numbers, i);
        if([phone_label isEqualToString:(NSString*)kABPersonPhoneMobileLabel]) {
            mobile_number = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
            break;
        }
    }
    
    if (mobile_number != nil) {
        [PersonalDataController setKeyDeposit:_our_data.key_deposit type:@"sms"];
        [PersonalDataController setKeyDeposit:_our_data.key_deposit phoneNumber:mobile_number];
        _deposit_changed = true;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];  // TODO(aka) Do we need this anymore?
    [self configureView];
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    // Note, since we dismiss the ABPeoplePicker in :peoplePickerNavigationController:shouldContinueAfterSelectingPerson:, this routine will never get called (i.e., the user can't select more specific properties in a record).
    
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        
        [_our_data genAsymmetricKeys];
        _pub_keys_changed = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

// XXX All deprecated!

// KeyDepositDataViewController delegate functions.
- (void) keyDepositDataViewControllerDidFinish:(NSMutableDictionary*)key_deposit {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:keyDepositDataViewControllerDidFinish: called.");
    
    // Update our key deposit dictionary (state should've been save in the segue).
    _our_data.key_deposit = key_deposit;
    _deposit_changed = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

- (void) keyDepositDataViewControllerDidCancel:(KeyDepositDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:keyDepositDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// ConsumerDataExtViewController delegate functions.
- (void) consumerDataExtViewControllerDidFinish:(PersonalDataController*)our_data providerList:(ProviderListController*)provider_list fetchDataToggle:(BOOL)fetch_data_toggle addSelfStatus:(BOOL)add_self_status {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:consumerDataExtViewControllerDidFinish:providerList:fetchDataToggle: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerDataViewController:consumerDataExtViewControllerDidFinish: received %lu count provider list and fetch-data: %d.", (unsigned long)[provider_list countOfList], fetch_data_toggle);
    
    if (kDebugLevel > 1) {
        for (int i = 0; i < [provider_list countOfList]; ++i) {
            NSLog(@"ConsumerDataViewController:consumerDataExtViewControllerDidFinish: provider[%d]: %s.", i, [[[provider_list objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }

    // Update our data (state may have been saved in the segue).
    _our_data = our_data;
    _provider_list_controller = provider_list;
    _fetch_data_toggle = fetch_data_toggle;
    _add_self_status = add_self_status;
    // XXX _state_change = true;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

- (void) consumerDataExtViewControllerDidCancel:(ConsumerDataExtViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:consumerDataExtViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

/*
// UITextField delegate functions.
- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (text_field == _identity_input) {
        [text_field resignFirstResponder];
    }
    
    return YES;
}
*/

/* XXX

// UIPickerView delegate functions.
-(void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerDataViewController:pickerView:didSelectRow:inComponent: called.");
    
    NSString* type = [[PersonalDataController supportedKeyDeposits] objectAtIndex:row];
    
    if (_our_data == nil) {
        NSLog(@"ConsumerDataViewController:pickerView:didSelectRow:inComponent: TODO(aka) user selected %s, but _our_data is nil!", [type cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return;
    }
    
    // Set our key deposit type value.
    [PersonalDataController setKeyDeposit:_our_data.key_deposit type:type];
}
 */

@end
