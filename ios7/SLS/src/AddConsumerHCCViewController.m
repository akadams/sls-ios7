//
//  AddConsumerHCCViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 2/27/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "NSData+Base64.h"

#import "AddConsumerHCCViewController.h"
#import "HCCPotentialPrincipal.h"
#import "sls-url-defines.h"


static const int kDebugLevel = 1;

static const char* kSchemeSLS = URI_SCHEME_SLS;

static const char* kPathHCCMsg2 = URI_PATH_HCC_MSG2;  // provider's HCC encrypted nonce challenge
static const char* kPathHCCMsg4 = URI_PATH_HCC_MSG4;  // provider's HCC pubkey, identity-token & encrypted secret-question
static const char* kPathHCCMsg6 = URI_PATH_HCC_MSG6;  // provider's HCC encrypted nonce response & secret-question reply
static const char* kPathHCCMsg8 = URI_PATH_HCC_MSG8;  // provider's HCC encrypted deposit

static const char* kQueryKeyID = URI_QUERY_KEY_ID;
static const char* kQueryKeyPublicKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyChallenge = URI_QUERY_KEY_CHALLENGE;
static const char* kQueryKeyResponse = URI_QUERY_KEY_CHALLENGE_RESPONSE;
static const char* kQueryKeySecretQuestion = URI_QUERY_KEY_SECRET_QUESTION;
static const char* kQueryKeyAnswer = URI_QUERY_KEY_SQ_ANSWER;
static const char* kQueryKeyDeposit = URI_QUERY_KEY_DEPOSIT;

static NSString* answer = nil;


@interface AddConsumerHCCViewController ()
@end

@implementation AddConsumerHCCViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize potential_consumer = _potential_consumer;

#pragma mark - Local variables

#pragma mark - Outlets
@synthesize main_label = _main_label;
@synthesize main_input = _main_input;
@synthesize send_msg_button = _send_msg_button;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _potential_consumer = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _potential_consumer = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerHCCViewController:configureView: called.");
    
    if (_potential_consumer == nil || _potential_consumer.principal == nil) {
        NSLog(@"AddConsumerHCCViewController:configureView: TODO(aka) _potential_consumer is nil!");
        return;
    }
    
    Principal* consumer = _potential_consumer.principal;
    int current_state = [_potential_consumer.mode intValue];
    
    // Highlight, add images, etc., based on what state we are currently in.
    switch (current_state) {
        case HCC_MODE_INITIAL :
        {
            NSLog(@"AddConsumerHCCViewController:configureView: XXX TODO(aka) called with mode: %d.", current_state);
        }
            break;
            
        case HCC_MODE_PROVIDER_PUBKEY_RECEIVED :
        {
            [_main_label setText:[NSString stringWithFormat:@"SMS number for %s: %s", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Challenge"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_PROVIDER_CHALLENGE_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Challenge sent to %s", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_PROVIDER_RESPONSE_VETTED :
        {
            [_main_label setText:[NSString stringWithFormat:@"Ask a question only %s would know:", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:FALSE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@""] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:0.5];
        }
            break;
            
        case HCC_MODE_PROVIDER_SECRET_QUESTION_INPUT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Using e-mail address: %s", [consumer.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Secret Question"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_PROVIDER_PUBKEY_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Secret question and public key sent to %s", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_PROVIDER_CHALLENGE_RECEIVED :
        {
            [_main_label setText:[NSString stringWithFormat:@"%s?", [_potential_consumer.their_secret_question cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:FALSE];
            [_send_msg_button setTitle:@"" forState:UIControlStateNormal];
            [_send_msg_button setAlpha:0.5];
            
        }
            break;
            
        case HCC_MODE_PROVIDER_ANSWER_INPUT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Using phone number: %s", [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Challenge Response"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
            
        }
            break;
            
        case HCC_MODE_PROVIDER_RESPONSE_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Response and answer sent to %s", [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_PROVIDER_DEPOSIT_RECEIVED :
        {
            [_main_label setText:[NSString stringWithFormat:@"Using e-mail address: %s", [consumer.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Deposit"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
            
        }
            break;
            
        case HCC_MODE_PROVIDER_DEPOSIT_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Deposit sent to %s", [consumer.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Pairing Complete, Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        default :
            NSLog(@"AddConsumerHCCViewController:configureView: ERROR: TODO(aka) unknown mode: %d.", current_state);
            break;
    }
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerMasterViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerHCCViewController:prepareForSeque: unwinding to ConsumerMasterViewController.");
        
        // User hit DONE.
    } else if ([[segue identifier] isEqualToString:@"UnwindToAddConsumerViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerHCCViewController:prepareForSeque: unwinding to AddConsumerViewController.");
        
        // User hit CANCEL, nothing to do.
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerHCCViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) send_msg:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:send_msg: called.");
    
    Principal* consumer = _potential_consumer.principal;
    int current_state = [_potential_consumer.mode intValue];
    
    // Depending on what state we are currently in with this potential provider ...
    switch (current_state) {
        case HCC_MODE_PROVIDER_PUBKEY_RECEIVED :  // send our challenge via alternate channel (SMS)
        {
            // Generate a challenge.
            _potential_consumer.our_challenge = [NSNumber numberWithInt:(arc4random() % 9999)];  // get a four digit challenge (response will have + 1, so <= 9998)
            NSString* encrypted_challenge = nil;
            NSString* err_msg = [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", [_potential_consumer.our_challenge intValue]] publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_challenge];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: using encrypted challenge: %s.", [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);            
            
            // Build the HCC msg2 *path*, which includes; (i) our encrypted nonce challenge base64 encoded.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s", kPathHCCMsg2, kQueryKeyChallenge, [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: sending %s SMS message: %s.", [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
            MFMessageComposeViewController* msg_controller = [[MFMessageComposeViewController alloc] init];
            if([MFMessageComposeViewController canSendText]) {
                msg_controller.body = [sls_url absoluteString];
                msg_controller.recipients = [NSArray arrayWithObjects:consumer.mobile_number, nil];
                msg_controller.messageComposeDelegate = self;
                [self presentViewController:msg_controller animated:YES completion:nil];
            } else {
                NSString* err_msg = [NSString stringWithFormat:@"Device not able to send SMS!"];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;  // nothing we can do
            }
        }
            break;
            
        case HCC_MODE_PROVIDER_CHALLENGE_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: CHALLENGE_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_PROVIDER_RESPONSE_VETTED :
        {
            // TODO(aka) Should we display an alert?
        }
            break;
            
        case HCC_MODE_PROVIDER_SECRET_QUESTION_INPUT :  // send our encrypted secret question, pub key & ID via main channel (e-mail)
        {
            if (_potential_consumer.our_secret_question == nil || [_potential_consumer.our_secret_question length] == 0) {
                NSString* err_msg = [NSString stringWithFormat:@"You must first enter a secret question."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                break;
            }
            
            // Encrypt secret-question.
            NSString* encrypted_question = nil;
            NSString* err_msg = [PersonalDataController asymmetricEncryptString:_potential_consumer.our_secret_question publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_question];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: using encrypted challenge: %s.", [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Build the HCC msg4 *path*, which includes; (i) our identity token, (ii) our public key, and (iii) our encrypted secret-question base64 encoded.
            
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* public_key = [[_our_data getPublicKey] base64EncodedString];
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s?%s=%s?%s=%s", kPathHCCMsg4, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyPublicKey, [public_key cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeySecretQuestion, [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: sending %s e-mail message: %s.", [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of an e-mail message (so the consumer can process it when reading the message).
            NSString* subject = [NSString stringWithFormat:@"Pairing response from %s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            MFMailComposeViewController* mail_vc = [[MFMailComposeViewController alloc] init];
            if([MFMailComposeViewController canSendMail]) {
                [mail_vc setSubject:subject];
                [mail_vc setMessageBody:[sls_url absoluteString] isHTML:NO];
                [mail_vc setToRecipients:[NSArray arrayWithObjects:consumer.email_address, nil]];
                mail_vc.mailComposeDelegate = self;
                [self presentViewController:mail_vc animated:YES completion:NULL];
            } else {
                NSString* err_msg = [NSString stringWithFormat:@"Device not able to send e-mail!"];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;  // nothing we can do
            }
        }
            break;
            
        case HCC_MODE_PROVIDER_PUBKEY_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: PUBKEY_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_PROVIDER_CHALLENGE_RECEIVED :
        {
            // TODO(aka) Should we display an alert?
        }
            break;
            
        case HCC_MODE_PROVIDER_ANSWER_INPUT :
        {
            if (answer == nil || [answer length] == 0) {
                NSString* err_msg = [NSString stringWithFormat:@"You must first answer the secret question."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                // TODO(aka) If the user hits CANCEL here, we need to somehow delete this potential provder from our master dictionary!
                break;
            }
            
            NSString* err_msg = nil;
            
            // Encrypt answer.
            NSString* encrypted_answer = nil;
            err_msg = [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_answer];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: using encrypted answer: %s.", [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Build the HCC msg6 *path*, which includes; (i) response nonce, and (ii) answer to their SQ.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%d?%s=%s", kPathHCCMsg6, kQueryKeyResponse, [_potential_consumer.their_challenge intValue], kQueryKeyAnswer, [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: sending %s SMS message: %s.", [consumer.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
            MFMessageComposeViewController* msg_controller = [[MFMessageComposeViewController alloc] init];
            if([MFMessageComposeViewController canSendText]) {
                msg_controller.body = [sls_url absoluteString];
                msg_controller.recipients = [NSArray arrayWithObjects:consumer.mobile_number, nil];
                msg_controller.messageComposeDelegate = self;
                [self presentViewController:msg_controller animated:YES completion:nil];
            } else {
                NSString* err_msg = [NSString stringWithFormat:@"Device not able to send SMS!"];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;  // nothing we can do
            }
        }
            break;
            
        case HCC_MODE_PROVIDER_RESPONSE_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: RESPONSE_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_PROVIDER_DEPOSIT_RECEIVED :
        {
            // Build the HCC msg8 *path*, which includes; (i) our depost.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s", kPathHCCMsg8, kQueryKeyDeposit, [[PersonalDataController serializeDeposit:_our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: sending %s message: %s.", [consumer.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of an e-mail message (so the provider can process it when reading the message).
            NSString* subject = [NSString stringWithFormat:@"Pairing completion from %s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            // XXX NSArray* to_recipents = [NSArray arrayWithObject:_provider.email_address];
            MFMailComposeViewController* mail_vc = [[MFMailComposeViewController alloc] init];
            if([MFMailComposeViewController canSendMail]) {
                [mail_vc setSubject:subject];
                [mail_vc setMessageBody:[sls_url absoluteString] isHTML:NO];
                [mail_vc setToRecipients:[NSArray arrayWithObjects:consumer.email_address, nil]];
                mail_vc.mailComposeDelegate = self;
                [self presentViewController:mail_vc animated:YES completion:NULL];
            } else {
                NSString* err_msg = [NSString stringWithFormat:@"Device not able to send e-mail!"];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;  // nothing we can do
            }
        }
            break;
            
        case HCC_MODE_PROVIDER_DEPOSIT_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: DEPOSIT_SENT, so ignoring.");
        }
            break;
            
        default :
            NSLog(@"AddConsumerHCCViewController:send_msg: ERROR: TODO(aka) unknown mode: %d.", current_state);
            break;
    }
}

#pragma mark - Delegate routines

// MFMessageComposeViewController delegate functions.
- (void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result {
	switch (result) {
		case MessageComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:messageComposeViewController:didFinishWithResult: Cancelled.");
			break;
            
		case MessageComposeResultFailed:
        {
            NSString* err_msg = [NSString stringWithFormat:@"Unknown error in sending SMS to %s!", [_potential_consumer.principal.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:messageComposeViewController:didFinishWithResult:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
		case MessageComposeResultSent:
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:messageComposeViewController:didFinishWithResult: Sent.");

            // Set our mode depending on what state we are currently in with this potential provider ...
            if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_PUBKEY_RECEIVED) {
                // We sent them our challenge.
                _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_CHALLENGE_SENT];
            } else if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_ANSWER_INPUT) {
                    // We sent them our response & answer.
                    _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_RESPONSE_SENT];
            } else {
                NSLog(@"AddConsumerHCCViewController:messageComposeViewController:didFinishWithResult: TODO(aka) Success, but unknown mode: %d", [_potential_consumer.mode intValue]);
            }
        }
			break;
            
		default:
			NSLog(@"AddConsumerHCCViewController:messageComposeViewController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

// MFMailComposeViewController delegate functions.
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (error != nil) {
        NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: ERROR: TODO(aka) received: %s.", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
	switch (result) {
        case MFMailComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: Cancelled.");
			break;
            
        case MFMailComposeResultFailed:
        {
            NSString* err_msg = [NSString stringWithFormat:@"Unknown error in sending e-mail to %s!", [_potential_consumer.principal.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
        case MFMailComposeResultSent:
        {
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: Sent.");
            
            // Set our mode depending on what state we are currently in with this potential provider ...
            if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_SECRET_QUESTION_INPUT) {
                // We sent them our identity token, public key & secret question.
                _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_PUBKEY_SENT];
            } else if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_DEPOSIT_RECEIVED) {
                // We sent them our deposit.
                _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_DEPOSIT_SENT];
            } else {
                NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: TODO(aka) Success, but unknown mode: %d", [_potential_consumer.mode intValue]);
            }
        }
			break;
            
        case MFMailComposeResultSaved:
            NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: Saved: TODO(aka) What do we do?.");
			break;
            
		default:
			NSLog(@"AddConsumerHCCViewController:mailComposeController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

// UITextField delegate functions.
- (void) textFieldDidBeginEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:textFieldDidBeginEditing: called.");
    
}

- (BOOL) textFieldShouldEndEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:textFieldShouldEndEditing: called.");
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerHCCViewController:textFieldShouldReturn: called.");
    
    // I don't think we need to worry about untainting here, as this is coming from the user.
    if (text_field == _main_input) {
        if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_RESPONSE_VETTED) {
            // Store input as our secret question.
            _potential_consumer.our_secret_question = text_field.text;
            _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_SECRET_QUESTION_INPUT];
        } else if ([_potential_consumer.mode intValue] == HCC_MODE_PROVIDER_CHALLENGE_RECEIVED) {
                // Store answer temporarily.
                answer = text_field.text;
                _potential_consumer.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_ANSWER_INPUT];
        } else {
            NSLog(@"AddConsumerHCCViewController:textFieldShouldReturn: XXX TODO(aka) unknown mode: %d!", [_potential_consumer.mode intValue]);
        }
    }
    
    [text_field resignFirstResponder];
    
    return YES;
}

@end
