//
//  AddConsumerQRViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/29/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "AddConsumerQRViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

@interface AddConsumerQRViewController ()
@end

@implementation AddConsumerQRViewController

@synthesize our_data = _our_data;
@synthesize consumer = _consumer;
@synthesize delegate = _delegate;
@synthesize checkbox_empty = _checkbox_empty;
@synthesize checkbox_checked = _checkbox_checked;

@synthesize decode_key_button = _decode_key_button;
@synthesize decode_key_image = _decode_key_image;

@synthesize encode_challenge_button = _encode_challenge_button;
@synthesize encode_challenge_label = _encode_challenge_label;
@synthesize encode_challenge_image = _encode_challenge_image;

@synthesize encode_response_label = _encode_response_label;
@synthesize encode_response_yes_button = _encode_response_yes_button;
@synthesize encode_response_no_button = _encode_response_no_button;
@synthesize encode_response_image = _encode_response_image;

@synthesize decode_key_deposit_button = _decode_key_deposit_button;
@synthesize decode_key_deposit_image = _decode_key_deposit_image;

@synthesize encode_key_button = _encode_key_button;
@synthesize encode_key_image = _encode_key_image;

@synthesize decode_challenge_button = _decode_challenge_button;
@synthesize decode_challenge_label = _decode_challenge_label;
@synthesize decode_challenge_image = _decode_challenge_image;

@synthesize end_label = _end_label;

@synthesize done_button = _done_button;
@synthesize cancel_button = _cancel_button;

@synthesize current_state = _current_state;

int _response;
int _challenge;

// Possible states to be in.
enum {
    MODE_INITIAL = 0,
    MODE_DECODE_PK = 1,
    MODE_ENCODE_CHALLENGE = 2,
    MODE_ENOCDE_RESPONSE = 3,
    MODE_ENCODE_RESPONSE_NO = 4,  // deprecated
    MODE_ENCODE_RESPONSE_YES = 5, 
    MODE_DECODE_KD = 6,
    MODE_ENCODE_PK = 7,
    MODE_DECODE_CHALLENGE = 8,
    MODE_DECODE_RESPONSE = 9  // deprecated
};


- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    _checkbox_empty = [UIImage imageNamed:@"checkbox_empty_T"];
    _checkbox_checked = [UIImage imageNamed:@"checkbox_checked_T"];
    
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:viewDidUnload: called.");
    
    [self setEncode_key_button:nil];
    [self setDecode_key_button:nil];
    [self setEncode_challenge_button:nil];
    [self setEncode_challenge_label:nil];
    [self setDecode_key_deposit_button:nil];
    [self setEncode_key_button:nil];
    [self setDecode_challenge_button:nil];
    [self setDecode_key_image:nil];
    [self setEncode_challenge_image:nil];
    [self setEncode_challenge_label:nil];
    [self setDecode_challenge_label:nil];
    [self setEnd_label:nil];
    [self setEncode_response_yes_button:nil];
    [self setEncode_response_no_button:nil];
    [self setEncode_response_image:nil];
    [self setDecode_key_deposit_button:nil];
    [self setDecode_key_deposit_image:nil];
    [self setEncode_key_image:nil];
    [self setDecode_challenge_image:nil];
    [self setEncode_key_button:nil];
    [self setDone_button:nil];
    [self setCancel_button:nil];
    [self setDecode_challenge_image:nil];
    [super viewDidUnload];
    
    // Note, this is where we clean up any *strong* references.
    _our_data = nil;
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:configureView: called.");
    
    // Highlight, add images, etc., based on what state we are currently in.
    switch (_current_state) {
        case MODE_INITIAL :
        {
            // Set default view.
            [_decode_key_button setAlpha:1.0];
            [_decode_key_image setImage:_checkbox_empty];
            
            [_encode_challenge_button setAlpha:0.5];
            [_encode_challenge_label setText:@"Did the Consumer respond with ..."];
            [_encode_challenge_label setAlpha:0.5];
            [_encode_challenge_image setImage:_checkbox_empty];
            [_encode_response_label setText:@""];  // deprecated
            
            [_encode_response_no_button setAlpha:0.5];
            [_encode_response_yes_button setAlpha:0.5];
            [_encode_response_image setImage:_checkbox_empty];
            
            [_decode_key_deposit_button setAlpha:0.5];
            [_decode_key_deposit_image setImage:_checkbox_empty];
            
            [_encode_key_button setAlpha:0.5];
            [_encode_key_image setImage:_checkbox_empty];
            
            [_decode_challenge_button setAlpha:0.5];
            [_decode_challenge_label setText:@"Respond to challenge with ..."];
            [_decode_challenge_label setAlpha:0.5];
            [_decode_challenge_image setImage:_checkbox_empty];
            
            [_end_label setText:@""];
        }
            break;
            
        case MODE_DECODE_PK :
        {
            [_decode_key_button setAlpha:0.5];
            [_decode_key_image setImage:_checkbox_checked];
            
            [_encode_challenge_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENCODE_CHALLENGE :
        {
            [_encode_challenge_button setAlpha:0.5];
            [_encode_challenge_image setImage:_checkbox_checked];
            
            [_encode_challenge_label setText:[NSString stringWithFormat:@"Did Consumer respond with %d?", _challenge + 1]];
            [_encode_challenge_label setAlpha:1.0];
            [_encode_response_no_button setAlpha:1.0];
            [_encode_response_yes_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENCODE_RESPONSE_YES :
        {
            [_encode_response_yes_button setAlpha:0.5];
            [_encode_response_no_button setAlpha:0.5];
            [_encode_response_image setImage:_checkbox_checked];
            [_encode_challenge_label setAlpha:0.5];
            
            [_encode_key_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENOCDE_RESPONSE :
        {
            NSLog(@"AddConsumerQRViewController:configureView: TODO(aka) in MODE_ENCODE_RESPONSE.");
        }
            break;
            
        case MODE_ENCODE_PK :
        {
            [_encode_key_button setAlpha:0.5];
            [_encode_key_image setImage:_checkbox_checked];
            
            [_decode_challenge_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_CHALLENGE :
        {
            [_decode_challenge_button setAlpha:0.5];
            [_decode_challenge_image setImage:_checkbox_checked];
            [_decode_challenge_label setText:[NSString stringWithFormat:@"Respond to challenge with: %d", _response]];
            [_decode_challenge_label setAlpha:1.0];
 
            [_decode_key_deposit_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_RESPONSE :
        {
            NSLog(@"AddConsumerQRViewController:configureView: TODO(aka) We are in MODE_DECODE_RESPONSE!");
        }
            break;
            
        case MODE_DECODE_KD :
        {
            [_decode_key_deposit_button setAlpha:0.5];
            [_decode_key_deposit_image setImage:_checkbox_checked];
            
            [_end_label setText:@"Communionable Trust complete, hit DONE!"];
        }
            break;
            
        default :
            NSLog(@"AddConsumerQRViewController:configureView: ERROR: TODO(aka) unknown mode: %d.", _current_state);
            break;
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:prepareForSegue: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowQRDecodeKeyView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: Segue'ng to ShowQRDecodeKeyView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeKeyViewController* view_controller = (QRDecodeKeyViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: ShowQRDecodeKeyView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeChallengeView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: Segue'ng to ShowQREncodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeChallengeViewController* view_controller = (QREncodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        
        NSLog(@"AddConsumerQRViewController:prepareForSegue: Consumer's identity: %s, hash: %s, public key: %s, publicKeyRef: %d.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [_consumer.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], ([_consumer publicKeyRef] == NULL ? false : true));
        
        view_controller.identity = _consumer.identity;
        _challenge = arc4random() % 9999;  // get a four digit challenge (response will have + 1)
        NSString* encrypted_challenge = nil;
        NSString* error_msg = [PersonalDataController encryptString:[NSString stringWithFormat:@"%d", _challenge] publicKeyRef:[_consumer publicKeyRef] encryptedString:&encrypted_challenge];
        if (error_msg) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerQRViewController:prepareForSegue: TODO(aka)" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
        
        view_controller.encrypted_challenge = encrypted_challenge;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: ShowQREncodeChallengeView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s, challenge: %d.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], _challenge);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeKeyDepositView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: Segue'ng to ShowQRDecodeKeyDepositView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeKeyDepositViewController* view_controller = (QRDecodeKeyDepositViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: ShowQRDecodeKeyDepositView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeKeyView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: Segue'ng to ShowQREncodeKeyView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeKeyViewController* view_controller = (QREncodeKeyViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: ShowQREncodeKeyView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeChallengeView"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: Segue'ng to ShowQRDecodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeChallengeViewController* view_controller = (QRDecodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: ShowQRDecodeChallengeView controller's identity: %s, hash: %s, file-store: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringFileStore:view_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerQRViewController:prepareForSegue: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:done: called.");
    
    if ([_consumer publicKeyRef] == NULL || _consumer.key_deposit == nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Add Consumer via QR" message:@"Key or key deposit not successfully obtained, canceling operation." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [[self delegate] addConsumerQRViewControllerDidCancel:self];
    }
    
    [[self delegate] addConsumerQRViewControllerDidFinish:_consumer];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:cancel: called.");
    
    [[self delegate] addConsumerQRViewControllerDidCancel:self];
}

- (IBAction)encodeResponseYes:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:encodeResponseYes: called.");
    
    _current_state = MODE_ENCODE_RESPONSE_YES;
    [self configureView];
}

- (IBAction)encodeResponseNo:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:encodeResponseNo: called.");
    
    _current_state = MODE_INITIAL;  // re-do scan of their key
    [_decode_key_image setImage:_checkbox_empty];
    [_encode_challenge_image setImage:_checkbox_empty];
    [_encode_challenge_label setText:@"Did Consumer respond with ..."];
    [_encode_challenge_label setAlpha:0.5];
    [_encode_response_no_button setAlpha:0.5];
    [_encode_response_yes_button setAlpha:0.5];
    [self configureView];
}


// Delegate functions.

// QRDecodeKeyViewController delegate functions.
- (void) qrDecodeKeyViewControllerDidFinish:(NSString*)identity_hash publicKey:(NSData*)public_key {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeKeyViewControllerDidFinish: called.");
    
    NSLog(@"AddConsumerQRViewController:qrDecodeKeyViewControllerDidFinish: TODO(aka) Check for nil identity-hash and/or publick key!");
    
    // Add our identity hash and new public key to our Consumer object.
    _consumer.identity_hash = identity_hash;
    [_consumer setPublicKey:public_key];
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerQRViewController:qrDecodeKeyViewControllerDidFinish: identity: %s, hash: %s, public key: %s, publicKeyRef: %d.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [_consumer.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], ([_consumer publicKeyRef] == NULL ? false : true));
    
    _current_state = MODE_DECODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeKeyViewControllerDidCancel:(QRDecodeKeyViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeKeyViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeChallengeViewController delegate functions.
- (void) qrEncodeChallengeViewControllerDidFinish {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrEncodeChallengeViewControllerDidFinish: called.");
    
    _current_state = MODE_ENCODE_CHALLENGE;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeChallengeViewControllerDidCancel:(QREncodeChallengeViewController *)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrEncodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeKeyDepositViewController delegate functions.
- (void) qrDecodeKeyDepositViewControllerDidFinish:(NSMutableDictionary*)key_deposit {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeKeyDepositViewControllerDidFinish: called.");
    
    // Add our new key deposit to our Consumer object.
    [_consumer setKey_deposit:key_deposit];
    
    NSLog(@"AddConsumerQRViewController:qrDecodeDepositKeyViewControllerDidFinish: identity: %s, key deposit %s, public key: %s.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:_consumer.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);

    _current_state = MODE_DECODE_KD;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeKeyDepositViewControllerDidCancel:(QRDecodeKeyDepositViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeKeyDepositViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeKeyViewController delegate functions.
- (void) qrEncodeKeyViewControllerDidFinish {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrEncodeKeyViewControllerDidFinish: called.");
  
    _current_state = MODE_ENCODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeKeyViewControllerDidCancel:(QREncodeKeyViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrEncodeKeyViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeChallengeViewController delegate functions.
- (void) qrDecodeChallengeViewControllerDidFinish:(NSString*)scan_results {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeChallengeViewControllerDidFinish: called.");
    
    if (scan_results == nil) {
#if 1
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"AddConsumerQRViewController:qrDecodeChallengeViewControllerDidFinish: TOOD(aka) Found device iPhone Simulator.");
            
            _response = 1234;
            _current_state = MODE_DECODE_CHALLENGE;
            
            [self configureView];
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }
#endif
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerQRViewController:qrDecodeChallengeViewControllerDidFinish: TODO(aka)" message:@"scan result is nil" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Decrypt the challenge.
    NSString* challenge_str = nil;
    NSString* error_msg = [_our_data decryptString:scan_results decryptedString:&challenge_str];
    if (error_msg) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerQRViewController" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    _response = [challenge_str intValue] + 1;
    _current_state = MODE_DECODE_CHALLENGE;
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeChallengeViewControllerDidCancel:(QRDecodeChallengeViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerQRViewController:qrDecodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
