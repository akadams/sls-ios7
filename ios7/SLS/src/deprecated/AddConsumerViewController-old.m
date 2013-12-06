//
//  AddConsumerViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/2/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "NSData+Base64.h"

#import "AddConsumerViewController.h"
#import "security-defines.h"


static const int kDebugLevel = 1;

@interface AddConsumerViewController ()
@end

@implementation AddConsumerViewController

@synthesize our_data = _our_data;
@synthesize consumer = _consumer;
@synthesize delegate = _delegate;
@synthesize identity_input = _identity_input;
@synthesize mobile_input = _mobile_input;
@synthesize email_input = _email_input;
@synthesize bluetooth_button = _bluetooth_button;

#if 0
enum {
    MODE_SCAN_PK = 0,
    MODE_SCAN_KD = 1,
    MODE_PRINT_PK = 2
};

const int kNumModes = 2;
#endif

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
        _identity_input = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:nibNameOrNill: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
        _identity_input = nil;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)        
        NSLog(@"AddConsumerViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setIdentity_input:nil];
    [self setConsumer:nil];
    [self setOur_data:nil];
    [self setBluetooth_button:nil];
    [self setMobile_input:nil];
    [self setEmail_input:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:viewDidLoad: called.");
    
    // Disable the bluetooth button.
    [_bluetooth_button setEnabled:false];
    [_bluetooth_button setAlpha:0.5];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowBluetoothRequestView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerViewController:prepareForSeque: Segue'ng to ShowBluetoothRequestView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        BluetoothRequestViewController* view_controller = (BluetoothRequestViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.consumer = _consumer;
        view_controller.our_data = _our_data;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowAddConsumerQRView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerViewController:prepareForSeque: Segue'ng to ShowAddConsumerQRView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddConsumerQRViewController* view_controller = (AddConsumerQRViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.consumer = _consumer;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerViewController:prepareForSegue: ShowAddConsumerQRView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerViewController:prepareForSeque: ERROR: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:done: called.");
    
    [[self delegate] addConsumerViewControllerDidFinish:_consumer];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:cancel: called.");
    
    [[self delegate] addConsumerViewControllerDidCancel:self];
}

- (IBAction)showPeoplePicker:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderDataViewController:showPeoplePicker: called.");
    
    ABPeoplePickerNavigationController* picker = [[ABPeoplePickerNavigationController alloc] init];    
    picker.peoplePickerDelegate = self;
#if 0
    // XXX TODO(aka) I think if we do this, we'll get the other delegate function ...
    NSArray* props = [NSArray arrayWithObjects:
                      [NSNumber numberWithInt:kABPersonFirstNameProperty], 
                      [NSNumber numberWithInt:kABPersonMiddleNameProperty], 
                      [NSNumber numberWithInt:kABPersonLastNameProperty], 
                      [NSNumber numberWithInt:kABPersonPhoneProperty],
                      [NSNumber numberWithInt:kABPersonEmailProperty], nil];
    picker.displayedProperties = props;
#endif
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction) sendEmail:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:sendEmail: called.");
 
    // TODO(aka) I'm not sure this makes sense as a provider ... would they ever initiate the key exchange?
    
#if 0    
    // Build our app's custom URI to send to our consumer.
    NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
    NSString* host = @"";  // app processing doesn't use host
    NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
    
    NSString* address = [PersonalDataController getKeyDepositAddress:consumer.key_deposit];
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:sendSymmetricKey: sending address:%s e-mail message: %s.", [address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Send our custom URI as the body of the e-mail message (so the consumer can install it when reading the message).
    
    MFMailComposeViewController* msg_controller = 
    [[MFMailComposeViewController alloc] init];
    if([MFMailComposeViewController canSendMail]) {
        [msg_controller setToRecipients:[NSArray arrayWithObjects:address, nil]];
        [msg_controller setSubject:@"SLS symmetric key and file store"];
        [msg_controller setMessageBody:[sls_url absoluteString] isHTML:NO];
        msg_controller.mailComposeDelegate = self;
        [self presentModalViewController:msg_controller animated:YES];
    } else {
        NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: ERROR: TODO(aka) hmm, we can't send SMS messages!");
        break;  // leave inner for loop
    }
#endif
}

- (IBAction) sendSMS:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:sendSMS: called.");
    
#if 0
    MFMessageComposeViewController* msg_controller = 
    [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText]) {
        msg_controller.body = [sls_url absoluteString];
        msg_controller.recipients = [NSArray arrayWithObjects:phone_number, nil];
        msg_controller.messageComposeDelegate = self;
        [self presentModalViewController:msg_controller animated:YES];
    } else {
        NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: ERROR: TODO(aka) hmm, we can't send SMS messages!");
        break;  // leave inner for loop
    }
#endif
}


// Delegate functions.

// UITextField delegate functions.
- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:textFieldShouldReturn:textField: called.");
    
    if (text_field == _identity_input) {
        if (_consumer == nil)
            _consumer = [[Consumer alloc] initWithIdentity:_identity_input.text];
        else
            _consumer.identity = _identity_input.text;
        
        // Revoke text_field's firstResponder status, to blow away the keyboard!
        [text_field resignFirstResponder];  
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerViewController:textFieldShouldReturn:textField: identity set to: %s.", [_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if (text_field == _mobile_input) {
        if ([_mobile_input.text length]) {
            _consumer.mobile_number = _mobile_input.text;
        }
        
        [text_field resignFirstResponder];
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderViewController:textFieldShouldReturn: provider's mobile phone set to: %s.", [_consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if (text_field == _email_input) {
        if ([_email_input.text length]) {
            _consumer.email_address = _email_input.text;
        }
        
        [text_field resignFirstResponder];
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderViewController:textFieldShouldReturn: provider's email set to: %s.", [_consumer.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    return YES;
}

// BluetoothRequestViewController delegate functions.
- (void) bluetoothRequestViewControllerDidFinish:(Consumer*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:bluetoothRequestViewControllerDidFinish: called.");
    
    _consumer = consumer;
    [[self delegate] addConsumerViewControllerDidFinish:consumer];
}

- (void) bluetoothRequestViewControllerDidCancel:(BluetoothRequestViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:btRequestViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];  
}

// AddConsumerQRViewController delegate functions.
- (void) addConsumerQRViewControllerDidFinish:(Consumer*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:addConsumerQRViewControllerDidFinish: called.");
    
    _consumer = consumer;
    
    NSLog(@"AddConsumerViewController:addConsumerQRViewControllerDidFinish: TODO(aka) Need to make sure we got all parts!");
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerViewController:addConsumerQRViewControllerDidFinish: identity: %s, key deposit %s, public key: %s.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:_consumer.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Head back to delegate (we we'll never actually use done() then).
    [[self delegate] addConsumerViewControllerDidFinish:consumer];
}

- (void) addConsumerQRViewControllerDidCancel:(AddConsumerQRViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:addConsumerQRViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];  
}

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
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
    
    if (_consumer == nil)
        _consumer = [[Consumer alloc] initWithIdentity:identity];
    else
        _consumer.identity = identity;
    
    if (kDebugLevel > 1)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity set to: %s.", [_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _identity_input.text = _consumer.identity;
    
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: TODO(aka) Need to print out cell phone or e-mail.");
    
    // Look for other data we could use, specifically; mobile phone number, e-mail address.
    NSString* mobile_number = nil;
    ABMultiValueRef phone_numbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int i = 0; i < ABMultiValueGetCount(phone_numbers); ++i) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(phone_numbers, i);
        if (CFStringCompare(kABPersonPhoneMobileLabel, label, kCFCompareCaseInsensitive) == 0)
            mobile_number = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
    }
    _consumer.mobile_number = mobile_number;
    _mobile_input.text = mobile_number;
    
    // Unlike the cell phone, we'll take the first e-mail address listed.
    NSString* email_address = nil;
    NSString* email_label = nil;
    ABMultiValueRef email_addresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(email_addresses) > 0) {
        email_address = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(email_addresses, 0);
        email_label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(email_addresses, 0);
    }
#if 0
    else {
        email = @"[None]";
        email_label = @"Unknown";
    }
#endif
    _consumer.email_address = email_address;
    _email_input.text = email_address;
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: Got phone (%s): %s, e-mail (%s): %s.", [(NSString*)kABPersonPhoneMobileLabel cStringUsingEncoding:[NSString defaultCStringEncoding]], [mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_label cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return YES;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];  
}

@end
