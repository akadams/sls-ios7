//
//  ConsumerDataViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "ConsumerDataViewController.h"
#import "ProviderListViewController.h"
#import "Principal.h"

static const int kDebugLevel = 5;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonGenKeysMessage = "Yes, generate new keys.";


@interface ConsumerDataViewController ()
@end

@implementation ConsumerDataViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize provider_list = _provider_list;
@synthesize fetch_data_toggle = _fetch_data_toggle;

#pragma mark - Local variables

#pragma mark - Variables returned via unwind callback
@synthesize identity_changed = _identity_changed;
@synthesize pub_keys_changed = _pub_keys_changed;
@synthesize deposit_changed = _deposit_changed;
@synthesize fetch_toggle_changed = _fetch_toggle_changed;

#pragma mark - Outlets
@synthesize done_button = _done_button;
@synthesize identity_label = _identity_label;
@synthesize identity_hash_label = _identity_hash_label;
@synthesize deposit_label = _deposit_label;
@synthesize pub_hash_label = _pub_hash_label;
@synthesize map_focus_label = _map_focus_label;
@synthesize gen_pub_keys_button = _gen_pub_keys_button;
@synthesize show_providers_button = _show_providers_button;
@synthesize fetch_data_switch = _fetch_data_switch;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider_list = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _show_providers_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
    
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _show_providers_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list = nil;
        _identity_changed = false;
        _pub_keys_changed = false;
        _deposit_changed = false;
        _fetch_toggle_changed = false;
        _fetch_data_toggle = false;
        _identity_label = nil;
        _identity_hash_label = nil;
        _deposit_label = nil;
        _pub_hash_label = nil;
        _map_focus_label = nil;
        _gen_pub_keys_button = nil;
        _show_providers_button = nil;
        _fetch_data_switch = nil;
        _done_button = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:viewDidLoad: called (%d).", [NSThread isMainThread]);
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) viewDidUnload {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:viewDidUnload: called (%d).", [NSThread isMainThread]);
    
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:viewDidAppear: called (%d).", [NSThread isMainThread]);
    
    [super viewDidAppear:animated];
    
    [self configureView];  // call configureView: to get the work done
}

- (void) configureView {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:configureView: called (%d).", [NSThread isMainThread]);
    
    // Show our identity.
    if (_our_data != nil && _our_data.identity != nil && [_our_data.identity length] > 0) {
        [_identity_label setText:_our_data.identity];
        [_identity_hash_label setText:_our_data.identity_hash];
    } else {
        [_identity_label setText:@"TOUCH TO SELECT"];
        [_identity_hash_label setText:@"UNKNOWN"];
        [_deposit_label setText:@"UNKNOWN"];
    }
    
    // And our deposit.
    if (_our_data != nil && _our_data.deposit != nil && [PersonalDataController isDepositComplete:_our_data.deposit]) {
        // Note, if we ever go back to e-mail file-store deposits, then we'd need to change this!
        _deposit_label.text = [PersonalDataController getDepositPhoneNumber:_our_data.deposit];
    } else {
        // Okay, we don't have a deposit.  However, if we *have* an identity, but not a deposit, that's a problem.
        if (_our_data != nil && _our_data.identity != nil && [_our_data.identity length]) {
            _deposit_label.text = @"ERROR: \"mobile\" entry does not exist!";
        } else {
            _deposit_label.text = @"UNKNOWN";
        }
    }

    // See if we should grey out the gen-keys button.
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    
    if (kDebugLevel > 0) {
        if (public_key_ref == NULL)
            NSLog(@"ConsumerDataVC:configureView: public_key_ref is NULL!.");
        else if (private_key_ref == NULL)
            NSLog(@"ConsumerDataVC:configureView: private_key_ref is NULL.");
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
    
    // See if we should grey out the "Show Providers" button and map focus label.
    if (_provider_list == nil || [_provider_list countOfList] == 0) {
        _show_providers_button.alpha = 0.5;
        _map_focus_label.text = @"";
    } else {
        // Display the map focus, if one is selected.
        NSString* focus_identity = nil;
        for (int i = 0; i < [_provider_list countOfList]; ++i) {
            // Get the provider's information.
            Principal* provider = [_provider_list objectInListAtIndex:i];
            if (provider.is_focus) {
                focus_identity = provider.identity;
                break;
            }
        }
        if (focus_identity != nil)
            _map_focus_label.text = focus_identity;
        else
            _map_focus_label.text = @"None Selected";
    }
    
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:configureView: exiting (%d).", [NSThread isMainThread]);
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source

// UITableView
/* 
// Override as we are using static cells.
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
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:didSelectRowAtIndexPath: called.");
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    NSLog(@"ConsumerDataVC:didSelectRowAtIndexPath: Configuring row %ld in section %ld.", (long)row, (long)section);
    
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

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerMasterViewID"]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerDataVC:prepareForSeque: unwinding to ConsumerMasterViewController.");
        
        if (sender != self.done_button) {
            // User hit CANCEL ...
            if (kDebugLevel > 0)
                NSLog(@"ConsumerDataVC:prepareForSeque: User hit CANCEL (pub_keys_chanaged: %d).", _pub_keys_changed);
            
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
                NSLog(@"ConsumerDataVC:prepareForSeque: User hit DONE.");
            
            // User hit DONE; state flags should have been set during actions, so go ahead and unwind!
        }
    } else if ([[segue identifier] isEqualToString:@"ShowProviderListViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataVC:prepareForSeque: Segue'ng to ShowProviderListView.");
        
        // Send *our data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderListViewController* view_controller = (ProviderListViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.provider_list = _provider_list;
        view_controller.current_provider = 0;
    } else {
        NSLog(@"ConsumerDataVC:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) unwindToConsumerData:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:unwindToConsumerData: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[ProviderListViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerDataVC:unwindToConsumerData: ProviderListViewController callback.");
        
        ProviderListViewController* source = [segue sourceViewController];
        if (source.provider_list_changed) {
            if (source.provider_list == nil) {
                NSLog(@"ConsumerDataVC:unwindToConsumerData: TODO(aka) ERROR: ProviderListController is nil!");
                return;
            }
            
            // Get our changes, and save the new state.
            _provider_list = source.provider_list;
            [_provider_list saveState];
        }
    } else {
        NSLog(@"ConsumerDataVC:unwindToConsumerData: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView];
}

#pragma mark - Actions

- (IBAction) genPubKeys:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:genPubKeys: called.");
    
    NSLog(@"ConsumerDataVC:genPubKeys: Not doing anything yet!");
    
    SecKeyRef public_key_ref = [_our_data publicKeyRef];
    if (public_key_ref != NULL)
        NSLog(@"ConsumerDataVC:genPubKeys: XXX public_key_ref was *not* NULL!");
    
    SecKeyRef private_key_ref = [_our_data privateKeyRef];
    if (private_key_ref != NULL)
        NSLog(@"ConsumerDataVC:genPubKeys: XXX private_key_ref was *not* NULL!");
    
    if (public_key_ref == NULL || private_key_ref == NULL) {
        NSString* err_msg = [_our_data genAsymmetricKeys];
        if (err_msg != nil) {
            NSString* alert_msg = [NSString stringWithFormat:@"Key generation failed: %@", err_msg];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:alert_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
        } else
            _pub_keys_changed = true;
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Asymmetric Key Generation" message:@"Keys already exist.  Are you sure you want to overwrite old keys?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    }
    
    [self configureView];
}

- (IBAction) toggleFetchData:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:toggleFetchData: called.");
    
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

#pragma mark - Delegate callbacks

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called (%d).", [NSThread isMainThread]);
    
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
        if([phone_label isEqualToString:(NSString*)kABPersonPhoneMobileLabel] || [phone_label isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel]) {
            mobile_number = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
            break;
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: phone label: %@.", phone_label);
    
    if (mobile_number != nil) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: mobile number: %@.", mobile_number);
        
        [PersonalDataController setDeposit:_our_data.deposit type:@"sms"];
        [PersonalDataController setDeposit:_our_data.deposit phoneNumber:mobile_number];
        _deposit_changed = true;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        [self dismissViewControllerAnimated:YES completion:nil];  // in 8.0+ people picker dismisses by itself
    }
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    // Note, since we dismiss the ABPeoplePicker in :peoplePickerNavigationController:shouldContinueAfterSelectingPerson:, this routine will never get called (i.e., the user can't select more specific properties in a record).
    
    return NO;
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationController:didSelectingPerson: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person];
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person     property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationController:didSelectingPerson:property:identifier: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person property:property identifier:identifier];
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataVC:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonGenKeysMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataVC:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        
        [_our_data genAsymmetricKeys];
        _pub_keys_changed = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataVC:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ConsumerDataVC:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

@end
