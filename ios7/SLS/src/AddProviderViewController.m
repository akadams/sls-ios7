//
//  AddProviderViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

// XXX #import <MessageUI/MFMessageComposeViewController.h>
// XXX #import <MessageUI/MFMailComposeViewController.h>

#import "NSData+Base64.h"

#import "AddProviderViewController.h"
#import "AddProviderCTViewController.h"
#import "AddProviderHCCViewController.h"
#import "security-defines.h"


static const int kDebugLevel = 4;

/* XXX TODO(aka) Do we need this?
static const char* kSchemeSLS = URI_SCHEME_SLS;
static const char* kQueryKeyPubKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyDepositURL = URI_QUERY_KEY_DEPOSIT_URL;
static const char* kQueryKeyIdentity = URI_QUERY_KEY_IDENTITY;
 */

@interface AddProviderViewController ()
@end

@implementation AddProviderViewController

#pragma mark - Inherited data (from the MasterViewController)
@synthesize our_data = _our_data;

#pragma mark - Local variables
@synthesize provider = _provider;
@synthesize chosen_protocol = _chosen_protocol;
@synthesize identity_label = _identity_label;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider = nil;
        _chosen_protocol = 0;
        _identity_label = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider = [[Principal alloc] init];
        _chosen_protocol = 0;
        _identity_label = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:configureView: called.");
    
    static bool first_time_in = true;
    
    // USER-HELP:
    NSString* help_msg = nil;
    if (first_time_in) {
        help_msg = [NSString stringWithFormat:@"If the person you want to \"pair\" (exchange cryptographic keys) with is present, choose \"QR-Codes\", otherwise, choose \"SMS & E-mail\".  Make sure that the other person is pairing as a PROVIDER."];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        first_time_in = false;
    }
    
    if (_provider.identity != nil && [_provider.identity length] > 0)
        _identity_label.text = _provider.identity;
    else
        _identity_label.text = @"";
    
    // TOOD(aka) Want to set a default pairing protocol?
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source routines

// UIPickerView.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:pickerView:numberOfRowsInComponent: called.");
    
    
    NSLog(@"AddProviderViewController:pickerView:numberOfRowsInComponent: returning %lu rows.", (unsigned long)[[AddProviderViewController supportedPairingProtocols] count]);
    
    return [[AddProviderViewController supportedPairingProtocols] count];
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:prepareForSegue: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:prepareForSegue: our identity: %s, deposit: %s, public-key: %s, and provider's identity: %s.", [_our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [_provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerMasterViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: unwinding to ConsumerMasterViewController.");
        
        // User hit CANCEL; clear our provider object if it's set.
        if (_provider != nil)
            _provider = nil;  // probably not necessary, as the ConsumerMasterVC ignores unwinds from here
    } else if ([[segue identifier] isEqualToString:@"ShowAddProviderCTViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: Segue'ng to AddProviderCTViewController.");
        
        // Pass in *our_data* and (potentially) new provider's info from our AddressBook.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderCTViewController* view_controller = (AddProviderCTViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        
        view_controller.our_data = _our_data;
        view_controller.provider = _provider;
        
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSegue: the ShowAddProviderCTView controller's now has identity: %s, deposit: %s, public-key: %s, and provider's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowAddProviderHCCViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: Segue'ng to AddProviderHCCViewController.");
        
        // Pass in *our_data* and (potentially) new provider's info from our AddressBook.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderHCCViewController* view_controller = (AddProviderHCCViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        
        view_controller.our_data = _our_data;
        
        // Note, we should only segue to AddProviderHCC VC at the start of HCC, so we can safely build the HCCPotentialPrincipal in here (which will get passed back to the Master VC during the unwind!
        
        HCCPotentialPrincipal* potential_provider = [[HCCPotentialPrincipal alloc] initWithPrincipal:_provider];  // sets mode to INITIAL
        view_controller.potential_provider = potential_provider;
        
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSegue: the ShowAddProviderHCCView controller's now has identity: %s, deposit: %s, public-key: %s, and provider's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.potential_provider.principal.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) unwindToAddProvider:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:unwindToAddProvider: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[AddProviderCTViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"AddProviderViewController:unwindToAddProvider: AddProviderCTView callback.");
        
        // User hit CANCEL.
    } else {
        NSLog(@"AddProviderViewController:unwindToAddProvider: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView];
}

#pragma mark - Actions

- (IBAction) showAddressBook:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:showAddressBook: called.");
    
    // First request authorization to Address Book
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
            CFRelease(address_book_ref);
            return;
        }
    
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    CFRelease(address_book_ref);
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)startPairing:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:startPairing: called, chosen_protocol: %ld.", (long)_chosen_protocol);

    if (_chosen_protocol == 0)
        [self performSegueWithIdentifier:@"ShowAddProviderCTViewID" sender:nil];
    else if (_chosen_protocol == 1)
        [self performSegueWithIdentifier:@"ShowAddProviderHCCViewID" sender:nil];
}

#pragma mark - Utility routines

+ (NSArray*) supportedPairingProtocols {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:supportedPairingProtocols: called.");
    
    static NSArray* protocols = nil;
    
    if (protocols == nil)
        protocols = [[NSArray alloc] initWithObjects:@"QR Codes", @"E-mail & SMS", nil];
    
    return protocols;
}

#pragma mark - Delegate callbacks

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
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
    
    if (_provider == nil)
        _provider = [[Principal alloc] initWithIdentity:identity];
    else
        _provider.identity = identity;
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity set to: %s.", [_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _identity_label.text = _provider.identity;
    
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: TODO(aka) Need to see if we have a cell phone or e-mail.");
    
    // Look for other data we could use, specifically; mobile phone number, e-mail address.
    NSString* mobile_number = nil;
    ABMultiValueRef phone_numbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int i = 0; i < ABMultiValueGetCount(phone_numbers); ++i) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(phone_numbers, i);
        if (CFStringCompare(kABPersonPhoneMobileLabel, label, kCFCompareCaseInsensitive) == 0)
            mobile_number = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
    }
    _provider.mobile_number = mobile_number;
    // XXX TODO(aka) _mobile_input.text = mobile_number;
    
    // Unlike our cell phone, we'll take the first e-mail address specified.
    NSString* email_address = nil;
    NSString* email_label = nil;
    ABMultiValueRef email_addresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(email_addresses) > 0) {
        email_address = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(email_addresses, 0);
        email_label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(email_addresses, 0);
    }
#if 0
    else {
        email_address = @"[None]";
        email_label = @"Unknown";
    }
#endif
    _provider.email_address = email_address;
    // XXX TODO(aka) _email_input.text = email_address;
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: Got phone (%s): %s, e-mail (%s): %s.", [(NSString*)kABPersonPhoneMobileLabel cStringUsingEncoding:[NSString defaultCStringEncoding]], [mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_label cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// UIPickerView delegate functions.
- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:pickerView:titleForRow:forComponent: called with row: %ld.", (long)row);
    
    return [[AddProviderViewController supportedPairingProtocols] objectAtIndex:row];
}

- (void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderViewController:pickerView:didSelectRow:inComponent: called.");

    // Mark which pairing protocol was selected.
    if (row > [[AddProviderViewController supportedPairingProtocols] count])
        _chosen_protocol = 0;
    else
        _chosen_protocol = row;
}

@end
