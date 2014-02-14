//
//  AddConsumerCTViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "AddConsumerCTViewController.h"
#import "NSData+Base64.h"

static const int kDebugLevel = 1;


@interface AddConsumerCTViewController ()
@end

@implementation AddConsumerCTViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize consumer = _consumer;

#pragma mark - Local variables
@synthesize current_state = _current_state;  // track our status through CT steps

#pragma mark - Images
@synthesize checkbox_empty = _checkbox_empty;
@synthesize checkbox_checked = _checkbox_checked;

#pragma mark - Outlets
@synthesize encode_key_button = _encode_key_button;
@synthesize encode_key_image = _encode_key_image;

@synthesize decode_challenge_button = _decode_challenge_button;
@synthesize decode_challenge_label = _decode_challenge_label;
// XXX @synthesize decode_response_label = _decode_response_label;  // deprecated
@synthesize decode_challenge_image = _decode_challenge_image;

@synthesize encode_deposit_button = _encode_deposit_button;
@synthesize encode_deposit_image = _encode_deposit_image;

@synthesize decode_key_button = _decode_key_button;
@synthesize decode_key_image = _decode_key_image;

@synthesize encode_challenge_button = _encode_challenge_button;
// XXX @synthesize encode_response_label = _encode_response_label;  // deprecated
@synthesize encode_challenge_image = _encode_challenge_image;
@synthesize encode_challenge_label = _encode_challenge_label;

@synthesize encode_response_yes_button = _encode_response_yes_button;
@synthesize encode_response_no_button = _encode_response_no_button;
@synthesize encode_response_image = _encode_response_image;
@synthesize end_label = _end_label;

@synthesize done_button = _done_button;

#pragma mark - Modes of challenge operation
int _response;
int _challenge;

// Possible states to be in.
enum {
    MODE_INITIAL = 0,
    MODE_DECODE_PK = 1,
    MODE_ENCODE_CHALLENGE = 2,
    MODE_ENCODE_RESPONSE_NO = 3,  // deprecated
    MODE_ENCODE_RESPONSE_YES = 4,
    MODE_ENCODE_PK = 5,
    MODE_DECODE_CHALLENGE = 6,
    MODE_DECODE_RESPONSE = 7,  // deprecated
    MODE_DECODE_DEPOSIT = 8,
    MODE_ENCODE_DEPOSIT = 9,
};

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    _checkbox_empty = [UIImage imageNamed:@"checkbox_empty_T"];
    _checkbox_checked = [UIImage imageNamed:@"checkbox_checked_T"];
    
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:configureView: called: %d.", _current_state);
    
    if (_consumer == nil) {
        NSLog(@"AddConsumerCTViewController:configureView: TODO(aka) _consumer is nil!");
        return;
    }
    
    // Highlight, add images, etc., based on what state we are currently in.
    switch (_current_state) {
        case MODE_INITIAL :
        {
            // Set default view.
            [_decode_key_button setAlpha:1.0];
            [_decode_key_image setImage:_checkbox_empty];
            
            [_encode_challenge_button setAlpha:0.5];
            [_encode_challenge_label setText:@"Did Consumer respond with ..."];
            [_encode_challenge_label setAlpha:0.5];
            // XXX [_encode_response_label setText:@""];  // deprecated
            [_encode_challenge_image setImage:_checkbox_empty];
            
            [_encode_response_no_button setAlpha:0.5];
            [_encode_response_yes_button setAlpha:0.5];
            [_encode_response_image setImage:_checkbox_empty];
            
            [_encode_key_button setAlpha:0.5];
            [_encode_key_image setImage:_checkbox_empty];
            
            [_decode_challenge_button setAlpha:0.5];
            [_decode_challenge_label setText:[NSString stringWithFormat:@"Respond to challenge with ..."]];
            [_decode_challenge_label setAlpha:0.5];
            [_decode_challenge_image setImage:_checkbox_empty];
            // XXX [_decode_response_label setText:@""];  // deprecated
            
            [_encode_deposit_button setAlpha:0.5];
            [_encode_deposit_image setImage:_checkbox_empty];
            [_decode_deposit_button setAlpha:0.5];
            [_decode_deposit_image setImage:_checkbox_empty];
            
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
            
            [_encode_response_no_button setAlpha:1.0];
            [_encode_response_yes_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENCODE_RESPONSE_YES :
        {
            [_encode_response_yes_button setAlpha:0.5];
            [_encode_response_no_button setAlpha:0.5];
            [_encode_response_image setImage:_checkbox_checked];
            
            [_encode_key_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_RESPONSE :  // TODO(aka) Is this used?
        {
            NSLog(@"AddConsumerCTViewController:configureView: TODO(aka) We are in MODE_DECODE_RESPONSE!");
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
            // XXX [_decode_response_label setText:[NSString stringWithFormat:@"%d", _response]];
            
            [_decode_deposit_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_DEPOSIT :
        {
            [_decode_challenge_label setAlpha:0.5];
            
            [_decode_deposit_button setAlpha:0.5];
            [_decode_deposit_image setImage:_checkbox_checked];
            
            [_encode_deposit_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENCODE_DEPOSIT :
        {
            [_encode_deposit_button setAlpha:0.5];
            [_encode_deposit_image setImage:_checkbox_checked];

            [_end_label setText:@"Pairing complete, hit DONE!"];
        }
            break;
            
        default :
            NSLog(@"AddConsumerCTViewController:configureView: ERROR: TODO(aka) unknown mode: %d.", _current_state);
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
        NSLog(@"AddConsumerCTViewController:prepareForSeque: called.");
    
    // TODO(aka) The QR[Encode|Decode] VCs should really be called CT[Encode|Decode] VCs!
    
    if ([[segue identifier] isEqualToString:@"UnwindToProviderMasterViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: unwinding to ProviderMasterViewController.");
        
        // User hit DONE, I don't think we need to do anything ...
    } else if ([[segue identifier] isEqualToString:@"UnwindToAddConsumerViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: unwinding to AddConsumerViewController.");
        
        // User hit CANCEL, nothing to do.
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodePKViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QREncodePKView.");
        
                // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodePKViewController* view_controller = (QREncodePKViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerCTViewController:prepareForSegue: ShowQREncodePKView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringDeposit:view_controller.our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodePKViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QRDecodePKView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodePKViewController* view_controller = (QRDecodePKViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeChallengeViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QREncodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeChallengeViewController* view_controller = (QREncodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        _challenge = arc4random() % 9999;  // get a four digit challenge (response will have + 1, so <= 9998)
        NSString* encrypted_challenge = nil;
        NSString* error_msg = [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", _challenge] publicKeyRef:[_consumer publicKeyRef] encryptedString:&encrypted_challenge];
        if (error_msg) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerCTViewController:prepareForSeque:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
        
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: using encrypted challenge: %s.", [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        view_controller.encrypted_challenge = encrypted_challenge;
        
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSegue: ShowQREncodeChallengeView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, consumer's identity: %s and challenge: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringDeposit:view_controller.our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeChallengeViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QRDecodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeChallengeViewController* view_controller = (QRDecodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeDepositViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QREncodeDepositView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeDepositViewController* view_controller = (QREncodeDepositViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddConsumerCTViewController:prepareForSegue: ShowQREncodeDepositView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, and consumer's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[PersonalDataController absoluteStringDeposit:view_controller.our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeDepositViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: Segue'ng to QRDecodeDepositView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeDepositViewController* view_controller = (QRDecodeDepositViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _consumer.identity;
        view_controller.delegate = self;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddConsumerCTViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) encodeResponseYes:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:encodeResponseYes: called.");
    
    _current_state = MODE_ENCODE_RESPONSE_YES;
    [self configureView];
}

- (IBAction) encodeResponseNo:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:encodeResponseNo: called.");
    
    _current_state = MODE_INITIAL;  // re-do scan of their key
    [_decode_key_image setImage:_checkbox_empty];
    [_encode_challenge_image setImage:_checkbox_empty];
    [_encode_challenge_label setText:@"Did Consumer respond with ..."];
    [_encode_challenge_label setAlpha:0.5];
    [_encode_response_no_button setAlpha:0.5];
    [_encode_response_yes_button setAlpha:0.5];
    [self configureView];
}

#pragma mark - Delegate routines

// QREncodePKViewController delegate functions.
- (void) qrEncodePKViewControllerDidFinish {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodePKViewControllerDidFinish: called.");
    
    NSLog(@"AddConsumerCTViewController:qrEncodePKViewControllerDidFinish: identity: %s.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    _current_state = MODE_ENCODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodePKViewControllerDidCancel:(QREncodePKViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodePKViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodePKViewController delegate functions.
- (void) qrDecodePKViewControllerDidFinish:(NSString*)identity_hash publicKey:(NSData*)public_key {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrDecodePKViewControllerDidFinish: called.");
    
    if (identity_hash != nil || public_key == nil) {
#if 1  // SIMULATOR HACK:
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"qrDecodePKViewControllerDidFinish: Found device iPhone Simulator.");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodePKViewControllerDidFinish:" message:[NSString stringWithFormat:@"done: called, but using simulator, so faking hash and key."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            identity_hash = [PersonalDataController hashMD5String:_consumer.identity];
            public_key = [_our_data getPublicKey];  // TODO(aka) for now, let's just use our PK
        }
        
        // Fall through so idenity_hash & public key can be processed as a success.
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodePKViewControllerDidFinish:" message:@"Scan was unsuccessful, canceling operation." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
#endif
    }
    
    // Add our identity hash and new public key to our Consumer object.
    _consumer.identity_hash = identity_hash;
    [_consumer setPublicKey:public_key];
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:qrDecodePKViewControllerDidFinish: identity: %s, hash: %s, public key: %s, publicKeyRef: %d.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [_consumer.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], ([_consumer publicKeyRef] == NULL ? false : true));
    
    _current_state = MODE_DECODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodePKViewControllerDidCancel:(QRDecodePKViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrDecodePKViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeChallengeViewController delegate functions.
- (void) qrEncodeChallengeViewControllerDidFinish {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodeChallengeViewControllerDidFinish: called.");
    
    _current_state = MODE_ENCODE_CHALLENGE;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeChallengeViewControllerDidCancel:(QREncodeChallengeViewController *)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeChallengeViewController delegate functions.
- (void) qrDecodeChallengeViewControllerDidFinish:(NSString*)scan_results {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidFinish: called.");
    
    if (scan_results == nil) {
#if 1  // SIMULATOR HACK:
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidFinish: TOOD(aka) Found device iPhone Simulator.");
            
            _response = 1234;
            _current_state = MODE_DECODE_CHALLENGE;
        }
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidFinish: TODO(aka)" message:@"scan result is nil" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
#endif
        
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidFinish: decrypting: %s.", [scan_results cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Decrypt the challenge.
    NSString* challenge_str = nil;
    NSString* error_msg = [_our_data decryptString:scan_results decryptedString:&challenge_str];
    if (error_msg) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidFinish: TODO(aka)" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    _response = [challenge_str intValue] + 1;
    _current_state = MODE_DECODE_CHALLENGE;
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeChallengeViewControllerDidCancel:(QRDecodeChallengeViewController*)controller {
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:qrDecodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeDepositViewController delegate functions.
- (void) qrEncodeDepositViewControllerDidFinish {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodeDepositViewControllerDidFinish: called.");
    
    _current_state = MODE_ENCODE_DEPOSIT;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeDepositViewControllerDidCancel:(QREncodeDepositViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrEncodeDepositViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeDepositViewController delegate functions.
- (void) qrDecodeDepositViewControllerDidFinish:(NSMutableDictionary*)deposit {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidFinish: called.");
    
    if (deposit == nil) {
#if 1  // SIMULATOR HACK:
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"qrDecodeDepositViewControllerDidFinish: Found device iPhone Simulator.");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodeDepositViewControllerDidFinish:" message:[NSString stringWithFormat:@"done: called, but using simulator, so faking deposit."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            NSArray* obj_dict = [[NSArray alloc] initWithObjects:@"412-268-5142", nil];
            NSArray* key_dict = [[NSArray alloc] initWithObjects:@"sms", nil];
            deposit = [[NSMutableDictionary alloc] initWithObjects:obj_dict forKeys:key_dict];
            
            // Fall-through so deposit can be processed.
        }
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidFinish: TODO(aka)" message:@"scan result is nil" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
#endif
    }
    
    // Add our new file-store deposit to our Consumer object.
    [_consumer setDeposit:deposit];
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidFinish: identity: %s, deposit %s, public key: %s.", [_consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringDeposit:_consumer.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _current_state = MODE_DECODE_DEPOSIT;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeDepositViewControllerDidCancel:(QRDecodeDepositViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
