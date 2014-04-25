//
//  AddProviderHCCViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 2/25/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "NSData+Base64.h"

#import "AddProviderHCCViewController.h"
#import "HCCPotentialPrincipal.h"
#import "sls-url-defines.h"


static const int kDebugLevel = 1;

static const char* kSchemeSLS = URI_SCHEME_SLS;

static const char* kPathHCCMsg1 = URI_PATH_HCC_MSG1;  // consumer's HCC pubkey & identity-token
static const char* kPathHCCMsg3 = URI_PATH_HCC_MSG3;  // consumer's HCC nonce response
static const char* kPathHCCMsg5 = URI_PATH_HCC_MSG5;  // consumer's HCC encrypted nonce challenge, secret-question reply & secret-question
static const char* kPathHCCMsg7 = URI_PATH_HCC_MSG7;  // consumer's HCC encrypted deposit & both nonces

static const char* kQueryKeyID = URI_QUERY_KEY_ID;
static const char* kQueryKeyPublicKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyChallenge = URI_QUERY_KEY_CHALLENGE;
static const char* kQueryKeyResponse = URI_QUERY_KEY_CHALLENGE_RESPONSE;
static const char* kQueryKeySecretQuestion = URI_QUERY_KEY_SECRET_QUESTION;
static const char* kQueryKeyAnswer = URI_QUERY_KEY_SQ_ANSWER;
static const char* kQueryKeyOurChallenge = URI_QUERY_KEY_OUR_CHALLENGE;
static const char* kQueryKeyTheirChallenge = URI_QUERY_KEY_THEIR_CHALLENGE;
static const char* kQueryKeyDeposit = URI_QUERY_KEY_DEPOSIT;

static NSString* answer = nil;


@interface AddProviderHCCViewController ()
@end

@implementation AddProviderHCCViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize potential_provider = _potential_provider;

#pragma mark - Local variables

#pragma mark - Outlets
@synthesize main_label = _main_label;
@synthesize main_input = _main_input;
@synthesize send_msg_button = _send_msg_button;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderHCCViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _potential_provider = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderHCCViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _potential_provider = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderHCCViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 0)
        NSLog(@"AddProviderHCCViewController:configureView: called.");
    
    if (_potential_provider == nil || _potential_provider.principal == nil ||
        _potential_provider.principal.identity == nil || [_potential_provider.principal.identity length] == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:configureView:" message:@"_provider or identity is nil" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    Principal* provider = _potential_provider.principal;
    int current_state = [_potential_provider.mode intValue];
    
    // Highlight, add images, etc., based on what state we are currently in.
    switch (current_state) {
        case HCC_MODE_INITIAL :
        {
            // Set default view.
            [_main_label setText:[NSString stringWithFormat:@"Using e-mail: %s", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Public Key"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_CONSUMER_PUBKEY_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Public key sent to %s", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_CONSUMER_CHALLENGE_RECEIVED :
        {
            [_main_label setText:[NSString stringWithFormat:@"Using phone number: %s", [provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Challenge Response"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
            
        }
            break;
            
        case HCC_MODE_CONSUMER_RESPONSE_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Response sent to %s", [provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_CONSUMER_PUBKEY_RECEIVED :
        {
            [_main_label setText:[NSString stringWithFormat:@"%s?", [_potential_provider.their_secret_question cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:FALSE];
            [_send_msg_button setTitle:@"" forState:UIControlStateNormal];
            [_send_msg_button setAlpha:0.5];
            
        }
            break;
            
        case HCC_MODE_CONSUMER_ANSWER_INPUT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Ask a question only %s would know:", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:FALSE];
            [_send_msg_button setTitle:@"" forState:UIControlStateNormal];
            [_send_msg_button setAlpha:0.5];
        }
            break;
            
        case HCC_MODE_CONSUMER_SECRET_QUESTION_INPUT :
        {
            [_main_label setText:[NSString stringWithFormat:@""]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Challenge"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_CONSUMER_CHALLENGE_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Challenge, answer and secret question sent to %s", [provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        case HCC_MODE_CONSUMER_RESPONSE_VETTED :
        {
            [_main_label setText:[NSString stringWithFormat:@"Using e-mail: %s", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Tap To Send Our Deposit"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
         }
            break;
            
        case HCC_MODE_CONSUMER_DEPOSIT_SENT :
        {
            [_main_label setText:[NSString stringWithFormat:@"Deposit sent to %s", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
            [_main_input setHidden:TRUE];
            [_send_msg_button setTitle:[NSString stringWithFormat:@"Hit DONE"] forState:UIControlStateNormal];
            [_send_msg_button setAlpha:1.0];
        }
            break;
            
        default :
            NSLog(@"AddProviderHCCViewController:configureView: ERROR: TODO(aka) unknown mode: %d.", current_state);
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
        NSLog(@"AddProviderHCCViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerMasterViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderHCCViewController:prepareForSeque: unwinding to ConsumerMasterViewController.");
        
        // User hit DONE.
    } else if ([[segue identifier] isEqualToString:@"UnwindToAddProviderViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderHCCViewController:prepareForSeque: unwinding to AddProviderViewController.");
        
        // User hit CANCEL, nothing to do.
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderHCCViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) send_msg:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderHCCViewController:send_msg: called.");
    
    Principal* provider = _potential_provider.principal;
    int current_state = [_potential_provider.mode intValue];
    
    // Depending on what state we are currently in with this potential provider ...
    switch (current_state) {
        case HCC_MODE_INITIAL :  // send them our public key & identity token
        {
            // Build the HCC msg1 *path*, which includes; (i) our identity token, and (ii) our public key base64 encoded.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* public_key = [[_our_data getPublicKey] base64EncodedString];
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s", kPathHCCMsg1, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyPublicKey, [public_key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: sending %s message: %s.", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of an e-mail message (so the provider can process it when reading the message).
            NSString* subject = [NSString stringWithFormat:@"Pairing request from %s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            // XXX NSArray* to_recipents = [NSArray arrayWithObject:_provider.email_address];
            MFMailComposeViewController* mail_vc = [[MFMailComposeViewController alloc] init];
            if([MFMailComposeViewController canSendMail]) {
                [mail_vc setSubject:subject];
                [mail_vc setMessageBody:[sls_url absoluteString] isHTML:NO];
                [mail_vc setToRecipients:[NSArray arrayWithObjects:provider.email_address, nil]];
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
            
        case HCC_MODE_CONSUMER_PUBKEY_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: PUBKEY_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_CONSUMER_CHALLENGE_RECEIVED :  // send them back the decrypted nonce
        {
            // Build the HCC msg3 *path*, which includes; (i) provider's nonce (challenge).
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%d", kPathHCCMsg3, kQueryKeyResponse, [_potential_provider.their_challenge intValue]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: sending %s SMS message: %s.", [provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
            MFMessageComposeViewController* msg_controller = [[MFMessageComposeViewController alloc] init];
            if([MFMessageComposeViewController canSendText]) {
                msg_controller.body = [sls_url absoluteString];
                msg_controller.recipients = [NSArray arrayWithObjects:provider.mobile_number, nil];
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
            
        case HCC_MODE_CONSUMER_RESPONSE_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: RESPONSE_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_CONSUMER_PUBKEY_RECEIVED :
        {
            // TODO(aka) Should we remind them to answer the question?
        }
            break;
            
        case HCC_MODE_CONSUMER_ANSWER_INPUT :
        {
            // TODO(aka) Should we remind them to answer the question?
        }
            break;
            
        case HCC_MODE_CONSUMER_SECRET_QUESTION_INPUT :  // send them back the answer and our challenge (nonce)
        {
            if (answer == nil || [answer length] == 0) {
                NSString* err_msg = [NSString stringWithFormat:@"You must first answer the secret question."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                // TODO(aka) If the user hits CANCEL here, we need to somehow delete this potential provder from our master dictionary!
                break;
            }
            
            if (_potential_provider.our_secret_question == nil || [_potential_provider.our_secret_question length] == 0) {
                NSString* err_msg = [NSString stringWithFormat:@"You must first enter a secret question."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];

                // TODO(aka) If the user hits CANCEL here, we need to somehow delete this potential provder from our master dictionary!
                break;
            }
            
            NSString* err_msg = nil;
            
            // Generate a challenge.
            _potential_provider.our_challenge = [NSNumber numberWithInt:(arc4random() % 9999)];  // get a four digit challenge (response will have + 1, so <= 9998)
            NSString* encrypted_challenge = nil;
            err_msg = [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", [_potential_provider.our_challenge intValue]] publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_challenge];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: using encrypted challenge: %s.", [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);

            // Encrypt answer.
            NSString* encrypted_answer = nil;
            err_msg = [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_answer];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            // Encrypt secret-question.
            NSString* encrypted_question = nil;
            err_msg = [PersonalDataController asymmetricEncryptString:_potential_provider.our_secret_question publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_question];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (kDebugLevel > 0)
                NSLog(@"AddConsumerHCCViewController:send_msg: using encrypted challenge: %s, encrypted answer: %s.", [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Build the HCC msg5 *path*, which includes; (i) encrypted nonce, (ii) answer to their SQ, and (iii) our encrypted SQ.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s?%s=%s?%s=%s", kPathHCCMsg5, kQueryKeyChallenge, [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyAnswer, [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeySecretQuestion, [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: sending %s SMS message: %s.", [provider.mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
            MFMessageComposeViewController* msg_controller = [[MFMessageComposeViewController alloc] init];
            if([MFMessageComposeViewController canSendText]) {
                msg_controller.body = [sls_url absoluteString];
                msg_controller.recipients = [NSArray arrayWithObjects:provider.mobile_number, nil];
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
            
        case HCC_MODE_CONSUMER_CHALLENGE_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: CHALLENGE_SENT, so ignoring.");
        }
            break;
            
        case HCC_MODE_CONSUMER_RESPONSE_VETTED :
        {
            NSString* err_msg = nil;
            
            // Encrypt our challenge and theirs.
            NSString* our_challenge_encrypted = nil;
            NSString* their_challenge_encrypted = nil;
            err_msg = [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&our_challenge_encrypted];
            err_msg = [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&their_challenge_encrypted];
            if (err_msg) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            // Build the HCC msg7 *path*, which includes; (i) our depost, and (ii) both encrypted nonces base64'd.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s&%s=%s", kPathHCCMsg7, kQueryKeyDeposit, [[PersonalDataController serializeDeposit:_our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyOurChallenge, [our_challenge_encrypted cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTheirChallenge, [their_challenge_encrypted cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            // Then build the SLS URL, which includes the path just built.
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: sending %s message: %s.", [provider.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of an e-mail message (so the provider can process it when reading the message).
            NSString* subject = [NSString stringWithFormat:@"Pairing completion from %s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            // XXX NSArray* to_recipents = [NSArray arrayWithObject:_provider.email_address];
            MFMailComposeViewController* mail_vc = [[MFMailComposeViewController alloc] init];
            if([MFMailComposeViewController canSendMail]) {
                [mail_vc setSubject:subject];
                [mail_vc setMessageBody:[sls_url absoluteString] isHTML:NO];
                [mail_vc setToRecipients:[NSArray arrayWithObjects:provider.email_address, nil]];
                mail_vc.mailComposeDelegate = self;
                [self presentViewController:mail_vc animated:YES completion:NULL];
            } else {
                err_msg = [NSString stringWithFormat:@"Device not able to send e-mail!"];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:send_msg:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;  // nothing we can do
            }
        }
            break;
            
        case HCC_MODE_CONSUMER_DEPOSIT_SENT :
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:send_msg: DEPOSIT_SENT, so ignoring.");
        }
            break;
            
        default :
            NSLog(@"AddProviderHCCViewController:send_msg: ERROR: TODO(aka) unknown mode: %d.", current_state);
            break;
    }
}

#pragma mark - Delegate routines

// MFMessageComposeViewController delegate functions.
- (void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result {
	switch (result) {
		case MessageComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:messageComposeViewController:didFinishWithResult: Cancelled.");
			break;
            
		case MessageComposeResultFailed:
        {
            NSString* err_msg = [NSString stringWithFormat:@"Unknown error in sending SMS to %s!", [_potential_provider.principal.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:messageComposeViewController:didFinishWithResult:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
		case MessageComposeResultSent:
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:messageComposeViewController:didFinishWithResult: Sent.");
            
            // Set our mode depending on what state we are currently in with this potential provider ...
            if ([_potential_provider.mode intValue] == HCC_MODE_CONSUMER_CHALLENGE_RECEIVED) {
                // We sent them our response.
                _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_RESPONSE_SENT];
            } else if ([_potential_provider.mode intValue] == HCC_MODE_CONSUMER_SECRET_QUESTION_INPUT) {
                // We sent them their answer, our challenge and our question.
                _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_CHALLENGE_SENT];
            } else {
                NSLog(@"AddProviderHCCViewController:messageComposeViewController:didFinishWithResult: TODO(aka) Success, but unknown mode: %d", [_potential_provider.mode intValue]);
            }
        }
			break;
            
		default:
			NSLog(@"AddProviderHCCViewController:messageComposeViewController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

// MFMailComposeViewController delegate functions.
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (error != nil) {
        NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: ERROR: TODO(aka) received: %s.", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
	switch (result) {
        case MFMailComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: Cancelled.");
			break;
            
        case MFMailComposeResultFailed:
        {
            NSString* err_msg = [NSString stringWithFormat:@"Unknown error in sending e-mail to %s!", [_potential_provider.principal.email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderHCCViewController:mailComposeController:didFinishWithResult:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
        case MFMailComposeResultSent:
        {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: Sent.");

            // Set our mode depending on what state we are currently in with this potential provider ...
            if ([_potential_provider.mode intValue] == HCC_MODE_INITIAL) {
                // We sent them our public key & identity token.
                _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_PUBKEY_SENT];
            } else if ([_potential_provider.mode intValue] == HCC_MODE_CONSUMER_RESPONSE_VETTED) {
                    // We sent them our deposit.
                    _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_DEPOSIT_SENT];
            } else {
                   NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: TODO(aka) Success, but unknown mode: %d", [_potential_provider.mode intValue]);
            }
        }
			break;
            
        case MFMailComposeResultSaved:
            NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: Saved: TODO(aka) What do we do?.");
			break;
            
		default:
			NSLog(@"AddProviderHCCViewController:mailComposeController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
    [self configureView];
}

// UITextField delegate functions.
- (void) textFieldDidBeginEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldDidBeginEditing: called.");
    
}

- (BOOL) textFieldShouldEndEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldShouldEndEditing: called.");
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldShouldReturn: called.");
    
    if (text_field == _main_input) {
        if ([_potential_provider.mode intValue] == HCC_MODE_CONSUMER_PUBKEY_RECEIVED) {
            // Store input as our answer.
            answer = text_field.text;
            _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_ANSWER_INPUT];
        } else if ([_potential_provider.mode intValue] == HCC_MODE_CONSUMER_ANSWER_INPUT) {
            _potential_provider.our_secret_question = text_field.text;
            _potential_provider.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_SECRET_QUESTION_INPUT];
        } else {
            NSLog(@"AddConsumerHCCViewController:textFieldShouldReturn: XXX TODO(aka) unknown mode: %d!", [_potential_provider.mode intValue]);
        }
    }

    [text_field resignFirstResponder];
    
    return YES;
}

@end
