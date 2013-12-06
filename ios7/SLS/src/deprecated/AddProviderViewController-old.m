//
//  AddProviderViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "NSData+Base64.h"

#import "AddProviderViewController.h"
#import "security-defines.h"


static const int kDebugLevel = 1;

static const char* kSchemeSLS = URI_SCHEME_SLS;
static const char* kQueryKeyPubKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyKeyDepositURL = URI_QUERY_KEY_KD_URL;
static const char* kQueryKeyIdentity = URI_QUERY_KEY_IDENTITY;

@interface AddProviderViewController ()
@end

@implementation AddProviderViewController

@synthesize our_data = _our_data;
@synthesize provider = _provider;
@synthesize delegate = _delegate;
@synthesize identity_input = _identity_input;
@synthesize mobile_input = _mobile_input;
@synthesize email_input = _email_input;
@synthesize bluetooth_button = _bluetooth_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:init: XXXXXXX called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider = nil;
        _delegate = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider = [[Provider alloc] init];
        _delegate = nil;
    }

    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setOur_data:nil];
    [self setIdentity_input:nil];
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
        NSLog(@"AddProviderViewController:prepareForSegue: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:prepareForSegue: working with identity: %s, key-deposit: %s, public-key: %s, and provider's identity: %s.", [_our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:_our_data.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [_provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]); 
    
    if ([[segue identifier] isEqualToString:@"ShowAddProviderQRView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: Segue'ng to ShowAddProviderQRView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderQRViewController* view_controller = (AddProviderQRViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        
        view_controller.provider = _provider;
        view_controller.our_data = _our_data;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSegue: the ShowAddProviderQRView controller's identity: %s, key-deposit: %s, public-key: %s, and provider's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:view_controller.our_data.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:done: called.");
    
    [[self delegate] addProviderViewControllerDidFinish:_provider];
}

- (IBAction)cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:cancel: called.");
    
    [[self delegate] addProviderViewControllerDidCancel:self];
}

- (IBAction)showPeoplePicker:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:showPeoplePicker: called.");
    
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

- (IBAction)sendEmail:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:sendEmail: called.");
    
    // First, make sure we have an identity, email-address and sms number.  Note, those must be saved in our Provider object, as we need to have some state around for when the challenge comes in!
    
    if (_provider.identity == nil || [_provider.identity length] == 0 ||
        _provider.mobile_number == nil || [_provider.mobile_number length] == 0 ||
        _provider.email_address == nil || [_provider.email_address length] == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderViewController:sendEmail:" message:@"Provider identity, number or address is nil!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];    
        return;
    }
    
    // Get our key deposit.
    NSURL* key_deposit_url = [PersonalDataController absoluteURLKeyDeposit:_our_data.key_deposit];
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:sendEmail: Using key deposit URL: %s.", [[key_deposit_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Build our app's custom URI to send to our consumer.
    NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
    NSString* host = @"";  // app processing doesn't use host
    NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyPubKey, [[[_our_data getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyDepositURL, [[key_deposit_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderViewController:sendEmail: sending address:%s e-mail message: %s.", [_provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Send our custom URI as the body of the e-mail message (so the consumer can install it when reading the message).
    
    MFMailComposeViewController* msg_controller = 
    [[MFMailComposeViewController alloc] init];
    if([MFMailComposeViewController canSendMail]) {
        [msg_controller setToRecipients:[NSArray arrayWithObjects:_provider.email_address, nil]];
        [msg_controller setSubject:@"SLS: New consumer public key and key deposit"];
        [msg_controller setMessageBody:[sls_url absoluteString] isHTML:NO];
        msg_controller.mailComposeDelegate = self;
        [self presentViewController:msg_controller animated:YES completion:nil];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderViewController:sendEmail:" message:@"We can't send e-mail messages!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];    
    }
    
    [[self delegate] addProviderViewControllerDidFinish:_provider];
}

- (IBAction) sendSMS:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:sendSMS: called.");
    
    // First, make sure we have an identity, email-address and sms number.  Note, those must be saved in our Provider object, as we need to have some state around for when the challenge comes in!
    
    if (_provider.identity == nil || [_provider.identity length] == 0 ||
        _provider.mobile_number == nil || [_provider.mobile_number length] == 0 ||
        _provider.email_address == nil || [_provider.email_address length] == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderViewController:sendEmail:" message:@"Provider identity, number or address is nil!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];    
        return;
    }
    
    // Get our key deposit.
    NSURL* key_deposit_url = [PersonalDataController absoluteURLKeyDeposit:_our_data.key_deposit];
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:sendEmail: Using key deposit URL: %s.", [[key_deposit_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Build our app's custom URI to send to our consumer.
    NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
    NSString* host = @"";  // app processing doesn't use host
    NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyPubKey, [[[_our_data getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyDepositURL, [[key_deposit_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderViewController:sendEmail: sending address:%s e-mail message: %s.", [_provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Send our custom URI as the body of the e-mail message (so the consumer can install it when reading the message).
    
    MFMessageComposeViewController* msg_controller = 
    [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText]) {
        msg_controller.body = [sls_url absoluteString];
        msg_controller.recipients = [NSArray arrayWithObjects:_provider.mobile_number, nil];
        msg_controller.messageComposeDelegate = self;
        [self presentViewController:msg_controller animated:YES completion:nil];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderViewController:sendEmail:" message:@"We can't send SMS messages!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];    
    }
    
    [[self delegate] addProviderViewControllerDidFinish:_provider];
}

- (IBAction)showAddressBook:(id)sender {
}


// Delegate functions.

// MFMessageComposeViewController delegate functions.
- (void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result {
	switch (result) {
		case MessageComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderViewController:messageComposeViewController:didFinishWithResult: Cancelled.");
			break;
            
		case MessageComposeResultFailed:
        {
			NSLog(@"AddProviderViewController:messageComposeViewController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
		case MessageComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderViewController:messageComposeViewController:didFinishWithResult: Sent.");     
			break;
            
		default:
			NSLog(@"AddProviderViewController:messageComposeViewController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

// MFMailComposeViewController delegate functions.
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (error != nil) {
        NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: ERROR: TODO(aka) received: %s.", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
	switch (result) {
        case MFMailComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: Cancelled.");
			break;
            
        case MFMailComposeResultFailed:
        {
			NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
        case MFMailComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: Sent.");     
			break;
            
        case MFMailComposeResultSaved:
            NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: Saved: TODO(aka) What do we do?.");
			break;
            
		default:
			NSLog(@"AddProviderViewController:mailComposeController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

// UITextField delegate functions.
- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:textFieldShouldReturn: called.");
    
    // Because we *may* skip done() in here (due to us going straight back to ConsumerMasterView after hitting done() in AddProviderQRView, we need to set any changes in here, as opposed to our done().  However, this isn't really a problem, as the new provider won't be added to the list until back in ConsumerMasterView, so we still have time to cancel!
    
    if (text_field == _identity_input) {
        if ([_identity_input.text length]) {
            if (_provider == nil)
                _provider = [[Provider alloc] initWithIdentity:_identity_input.text];
            else
                _provider.identity = _identity_input.text;
        }
        
        [text_field resignFirstResponder];
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderViewController:textFieldShouldReturn: provider's identity set to: %s.", [_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if (text_field == _mobile_input) {
        if ([_mobile_input.text length]) {
            _provider.mobile_number = _mobile_input.text;
        }
        
        [text_field resignFirstResponder];
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderViewController:textFieldShouldReturn: provider's mobile phone set to: %s.", [_provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if (text_field == _email_input) {
        if ([_email_input.text length]) {
            _provider.email_address = _email_input.text;
        }
        
        [text_field resignFirstResponder];
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderViewController:textFieldShouldReturn: provider's email set to: %s.", [_provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    
    return YES;
}

// AddProviderQRViewController delegate functions.
- (void) addProviderQRViewControllerDidFinish:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:addProviderQRViewControllerDidFinish: called.");
   
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:addProviderQRViewControllerDidFinish: received provider: %s.", [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _provider = provider;
    
    // Let's jump right to the ConsumerMasterViewController.
    [[self delegate] addProviderViewControllerDidFinish:provider];
}

- (void) addProviderQRViewControllerDidCancel:(AddProviderQRViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:addProviderQRViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 2)
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
        _provider = [[Provider alloc] initWithIdentity:identity];
    else
        _provider.identity = identity;
    
    if (kDebugLevel > 1)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity set to: %s.", [_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _identity_input.text = _provider.identity;
    
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
    _mobile_input.text = mobile_number;
    
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
    _email_input.text = email_address;
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: Got phone (%s): %s, e-mail (%s): %s.", [(NSString*)kABPersonPhoneMobileLabel cStringUsingEncoding:[NSString defaultCStringEncoding]], [mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_label cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return YES;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    return NO;
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderViewController:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
