//
//  ProviderDataViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/22/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "ProviderDataViewController.h"
#import "FileStoreDataViewController.h"

static const int kDebugLevel = 4;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonGenKeysMessage = "Yes, generate new keys.";
static const char* kAlertButtonGenSymKeysMessage = "Yes, generate new symmetric keys.";


@interface ProviderDataViewController ()
@end

@implementation ProviderDataViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize location_controller = _location_controller;
@synthesize symmetric_keys = _symmetric_keys;
@synthesize track_self_status = _track_self_status;

#pragma mark - Local variables

#pragma mark - Variables returned via unwind callback
@synthesize identity_changed = _identity_changed;
@synthesize deposit_changed = _deposit_changed;
@synthesize pub_keys_changed = _pub_keys_changed;
@synthesize sym_keys_changed = _sym_keys_changed;
@synthesize location_sharing_toggle_changed = _location_sharing_toggle_changed;
@synthesize file_store_changed = _file_store_changed;
@synthesize power_savings_toggle_changed = _power_savings_toggle_changed;
@synthesize distance_filter_changed = _distance_filter_changed;

#pragma mark - Outlets
@synthesize done_button = _done_button;
@synthesize identity_label = _identity_label;
@synthesize identity_hash_label = _identity_hash_label;
@synthesize deposit_label = _deposit_label;
@synthesize pub_hash_label = _pub_hash_label;
@synthesize gen_pub_keys_button = _gen_pub_keys_button;
@synthesize gen_sym_keys_button = _gen_sym_keys_button;
@synthesize location_sharing_switch = _location_sharing_switch;
@synthesize file_store_label = _file_store_label;
@synthesize track_self_button = _track_self_button;
@synthesize toggle_power_saving_button = _toggle_power_saving_button;
@synthesize distance_filter_slider = _distance_filter_slider;
@synthesize distance_filter_label = _distance_filter_label;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _track_self_status = false;
        _identity_changed = false;
        _deposit_changed = false;
        _pub_keys_changed = false;
        _sym_keys_changed = false;
        _location_sharing_toggle_changed = false;
        _file_store_changed = false;
        _power_savings_toggle_changed = false;
        _distance_filter_changed = false;
        
        _done_button = nil;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _gen_pub_keys_button = nil;
        _gen_sym_keys_button = nil;
        _location_sharing_switch = nil;
        _file_store_label = nil;
        _track_self_button = nil;
        _toggle_power_saving_button = nil;
        _distance_filter_slider = nil;
        _distance_filter_label = nil;
    }
    
    return self;
    
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _track_self_status = false;
        _identity_changed = false;
        _deposit_changed = false;
        _pub_keys_changed = false;
        _sym_keys_changed = false;
        _location_sharing_toggle_changed = false;
        _file_store_changed = false;
        _power_savings_toggle_changed = false;
        _distance_filter_changed = false;
        
        _done_button = nil;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _gen_pub_keys_button = nil;
        _gen_sym_keys_button = nil;
        _location_sharing_switch = nil;
        _file_store_label = nil;
        _track_self_button = nil;
        _toggle_power_saving_button = nil;
        _distance_filter_slider = nil;
        _distance_filter_label = nil;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _location_controller = nil;
        _symmetric_keys = nil;
        _track_self_status = false;
        _identity_changed = false;
        _deposit_changed = false;
        _pub_keys_changed = false;
        _sym_keys_changed = false;
        _location_sharing_toggle_changed = false;
        _file_store_changed = false;
        _power_savings_toggle_changed = false;
        _distance_filter_changed = false;
        
        _done_button = nil;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _gen_pub_keys_button = nil;
        _gen_sym_keys_button = nil;
        _location_sharing_switch = nil;
        _file_store_label = nil;
        _track_self_button = nil;
        _toggle_power_saving_button = nil;
        _distance_filter_slider = nil;
        _distance_filter_label = nil;
    }
    
    return self;
}

#pragma mark - View management

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

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:configureView: called.");
    
    // Show our identity.
    if (_our_data != nil && [_our_data.identity length]) {
        NSLog(@"ProviderDataViewController:configureView: setting identity: %@.", _our_data.identity);
        [_identity_label setText:_our_data.identity];
        [_identity_hash_label setText:_our_data.identity_hash];
        
        // And our deposit.
        if (_our_data != nil && _our_data.deposit != nil && [PersonalDataController isDepositComplete:_our_data.deposit]) {
            // Note, if we ever go back to e-mail file-store deposits, then we'd need to change this!
            NSLog(@"ConsumerDataViewController:configureView: setting deposit: %@.", [PersonalDataController getDepositPhoneNumber:_our_data.deposit]);
            _deposit_label.text = [PersonalDataController getDepositPhoneNumber:_our_data.deposit];
        } else {
            // If we have an identity, but not a deposit, that's a problem.
            _deposit_label.text = @"ERROR: \"mobile\" entry does not exist!";
        }
    } else {
        [_identity_label setText:@""];
        [_identity_hash_label setText:@""];
        [_deposit_label setText:@""];
    }
    
    // And our deposit.
    if (_our_data != nil && _our_data.deposit != nil && [PersonalDataController isDepositComplete:_our_data.deposit]) {
        // Note, if we ever go back to e-mail file-store deposits, then we'd need to change this!
        NSLog(@"ConsumerDataViewController:configureView: setting deposit: %@.", [PersonalDataController getDepositPhoneNumber:_our_data.deposit]);
        _deposit_label.text = [PersonalDataController getDepositPhoneNumber:_our_data.deposit];
    } else {
        _deposit_label.text = @"";
    }
    
    // See if we should grey out the gen-pub-keys button.
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    
    if (kDebugLevel > 0) {
        if (public_key_ref == NULL)
            NSLog(@"ProviderDataViewController:configureView: public_key_ref is NULL!.");
        else if (private_key_ref == NULL)
            NSLog(@"ProviderDataViewController:configureView: private_key_ref is NULL.");
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

    // See if we should grey out the gen-sym-keys button.
    if ([_symmetric_keys haveKeys]) {
        [_gen_sym_keys_button setTitle:@"Re-generate Symmetric Keys" forState:UIControlStateNormal];
        _gen_sym_keys_button.alpha = 0.5;
    } else {
        [_gen_sym_keys_button setTitle:@"Generate Symmetric Keys" forState:UIControlStateNormal];
        _gen_sym_keys_button.alpha = 1.0;
    }

    // See what position to put the enable_location_sharing switch in.
    if (_location_controller.location_sharing_toggle)
        [_location_sharing_switch setOn:YES];
    else
        [_location_sharing_switch setOn:NO];
    
    // And our file-store.
    if (_our_data != nil && _our_data.file_store != nil) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:configureView: setting file-store: %@.", [PersonalDataController absoluteStringFileStore:_our_data.file_store]);
        
        _file_store_label.text = [PersonalDataController getFileStoreService:_our_data.file_store];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:configureView: file-store is nil!");
        
        _file_store_label.text = @"";
    }
    
    // See if we should grey out the "Track Self" button.
    if (_track_self_status)
        _track_self_button.alpha = 0.5;
    else
        _track_self_button.alpha = 1.0;
    
    // Set text for accuracy of location data (higher accuracy means more power!).
    if (_location_controller.power_saving_toggle) {
        [_toggle_power_saving_button setTitle:@"Frequent Updates" forState:UIControlStateNormal];
    } else {
        [_toggle_power_saving_button setTitle:@"Power Saving" forState:UIControlStateNormal];
    }
    
    _distance_filter_slider.value = _location_controller.distance_filter;
    [_distance_filter_label setText:[NSString stringWithFormat:@"%dm", (int)_distance_filter_slider.value]];
    
    if (kDebugLevel > 3)
        NSLog(@"ProviderDataViewController:configureView: exiting.");
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source

// UITableView
/*
 // Use super methods, as we are using static cells.
 - (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
 // Return the number of sections.
 return 0;
 }
 
 - (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
 // Return the number of rows in the section.
 return 0;
 }
 
 - (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 static NSString *CellIdentifier = @"Cell";
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
 
 // Configure the cell...
 
 return cell;
 }
 */

/*
 // Override to support conditional editing of the table view.
 - (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void) tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:didSelectRowAtIndexPath: called.");
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    NSLog(@"ProviderDataViewController:didSelectRowAtIndexPath: Configuring row %ld in section %ld.", (long)row, (long)section);
    
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
    } else if (section == 2 && row == 1) {
        // Second cell in File-store section; display a view to configured our file-store.
        [self performSegueWithIdentifier:@"ShowFileStoreDataViewID" sender:nil];
    }
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToProviderMasterViewID"]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderDataViewController:prepareForSeque: unwinding to ProviderMasterViewController.");
        
        if (sender != self.done_button) {
            // User hit CANCEL ...
            if (kDebugLevel > 0)
                NSLog(@"ProviderDataViewController:prepareForSeque: User hit CANCEL (pub_keys_chanaged: %d).", _pub_keys_changed);
            
            if (_pub_keys_changed) {
                // Note, asymmetric keys, if generated, would already have been saved in genPubKeys(), so if the user is requesting to cancel, point out to them that that was non-reverting action.
                
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Data" message:@"Note, asymmetric key (re)generation is irreversible." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            // Unset any state flags, if they were set.
            if (_identity_changed)
                _identity_changed = false;
            if (_file_store_changed)
                _file_store_changed = false;
            if (_track_self_status)
                _track_self_status = false;  // an idempotent operation, so we really don't care
        } else {
            if (kDebugLevel > 0)
                NSLog(@"ProviderDataViewController:prepareForSeque: User hit DONE.");
            
            // User hit DONE; state flags should have been set during actions, so go ahead and unwind!
        }
    } else if ([[segue identifier] isEqualToString:@"ShowFileStoreDataViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:prepareForSeque: Segue'ng to FileStoreDataViewController.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        FileStoreDataViewController* view_controller = (FileStoreDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
    } else {
        NSLog(@"ProviderDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) unwindToProviderData:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:unwindToProviderData: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[FileStoreDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderDataViewController:unwindToProviderData: FileStoreDataViewController callback.");
        
        FileStoreDataViewController* source = [segue sourceViewController];
        if (source.file_store_changed) {
            if (source.our_data == nil || source.our_data.file_store == nil) {
                NSLog(@"ProviderDataViewController:unwindToProviderData: TODO(aka) ERROR: PersonalDataController or File-store is nil!");
                return;
            }
            
            // Note, we don't save state here, as we can still cancel this back in the MasterViewController.
            _our_data.file_store = source.our_data.file_store;  // get the changes
            _file_store_changed = true;
        }
    } else {
        NSLog(@"ProviderDataViewController:unwindToProviderData: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView];
}

#pragma mark - Actions

- (IBAction) genPubKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:genPubKeys: called.");
    
    NSLog(@"ProviderDataViewController:genPubKeys: Not doing anything yet!");
    
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    if (public_key_ref != NULL)
        NSLog(@"ProviderDataViewController:genPubKeys: XXX public_key_ref was *not* NULL!");
    
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    if (private_key_ref != NULL)
        NSLog(@"ProviderDataViewController:genPubKeys: XXX private_key_ref was *not* NULL!");
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        [_our_data genAsymmetricKeys];
        _pub_keys_changed = true;
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:@"Keys already exist.  Are you sure you want to overwrite old keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
    
    [self configureView];
}

- (IBAction) genSymKeys:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:genSymmetricKeys: called.");
    
    if (![_symmetric_keys haveKeys]) {
        for (int i = 0; i < kNumPrecisionLevels; ++i) {
            [_symmetric_keys genSymmetricKey:[NSNumber numberWithInt:i]];
        }
        _sym_keys_changed = true;
        
        [self configureView];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Symmetric Key Generation" message:@"Keys already exist.  Are you sure you want to generate new keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenSymKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
}

- (IBAction)toggleLocationSharing:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:toggleLocationSharing: called.");
    
    // Set flag to tell our parent to *enable* or *disable* location data fetching.
    if (_location_controller.location_sharing_toggle && !_location_sharing_switch.on) {
        _location_controller.location_sharing_toggle = false;
        _location_sharing_toggle_changed = true;
    } else if (!_location_controller.location_sharing_toggle && _location_sharing_switch.on) {
        _location_controller.location_sharing_toggle = true;
        _location_sharing_toggle_changed = true;
    }
    
    [self configureView];
}

- (IBAction) addSelfToConsumers:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:addSelfToConsumers: called.");
    
    _track_self_status = true;
    [self configureView];
}

- (IBAction)togglePowerSaving:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:togglePowerSaving: called.");
    
    if (_location_controller.power_saving_toggle)
        _location_controller.power_saving_toggle = false;
    else
        _location_controller.power_saving_toggle = true;
    _power_savings_toggle_changed = true;
    
    [self configureView];
}

- (IBAction) distanceFilterSliderChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:distanceFilterSliderChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    _location_controller.distance_filter = slider.value;
    _distance_filter_changed = true;
    
    [self configureView];
}

#pragma mark - Delegate callbacks

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
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
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: phone label: %@.", phone_label);
    
    if (mobile_number != nil) {
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: mobile: %@.", mobile_number);
        
        [PersonalDataController setDeposit:_our_data.deposit type:@"sms"];
        [PersonalDataController setDeposit:_our_data.deposit phoneNumber:mobile_number];
        _deposit_changed = true;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];  // TODO(aka) Do we need this anymore?
    [self configureView];
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    // Note, since we dismiss the ABPeoplePicker in :peoplePickerNavigationController:shouldContinueAfterSelectingPerson:, this routine will never get called (i.e., the user can't select more specific properties in a record).
    
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        
        [_our_data genAsymmetricKeys];
        _pub_keys_changed = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ProviderDataViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

@end
