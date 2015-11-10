//
//  AddProviderCTViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "NSData+Base64.h"

#import "AddProviderCTViewController.h"
#import "security-defines.h"


static const int kDebugLevel = 1;

// ACCESS_GROUPS:
static const char* kAccessGroupCT = KC_ACCESS_GROUP_CT;


@interface AddProviderCTViewController ()
@end

@implementation AddProviderCTViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize provider = _provider;

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
    MODE_ENCODE_PK = 1,
    MODE_DECODE_CHALLENGE = 2,
    MODE_DECODE_RESPONSE = 3,  // deprecated
    MODE_DECODE_PK = 4,
    MODE_ENCODE_CHALLENGE = 5,
    MODE_ENCODE_RESPONSE_NO = 6,  // deprecated
    MODE_ENCODE_RESPONSE_YES = 7,
    MODE_ENCODE_DEPOSIT = 8,
    MODE_DECODE_DEPOSIT = 9,
};

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _provider = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider = nil;
        _current_state = MODE_INITIAL;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    _checkbox_empty = [UIImage imageNamed:@"checkbox_empty-42"];
    _checkbox_checked = [UIImage imageNamed:@"checkbox_checked-42"];
    
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 0)
        NSLog(@"AddProviderCTViewController:configureView: called: %d.", _current_state);
    
    if (_provider == nil) {
        NSLog(@"AddProviderCTViewController:configureView: TODO(aka) _provider is nil!");
        return;
    }
    
    // Highlight, add images, etc., based on what state we are currently in.
    switch (_current_state) {
        case MODE_INITIAL :
        {
            // Set default view.
            [_encode_key_button setAlpha:1.0];
            [_encode_key_image setImage:_checkbox_empty];
            
            [_decode_challenge_button setAlpha:0.5];
            [_decode_challenge_label setText:[NSString stringWithFormat:@"Respond to challenge with ..."]];
            [_decode_challenge_label setAlpha:0.5];
            [_decode_challenge_image setImage:_checkbox_empty];
            // XXX [_decode_response_label setText:@""];  // deprecated
            
            [_decode_key_button setAlpha:0.5];
            [_decode_key_image setImage:_checkbox_empty];
            
            [_encode_challenge_button setAlpha:0.5];
            [_encode_challenge_label setText:@"Did Provider respond with ..."];
            [_encode_challenge_label setAlpha:0.5];
            // XXX [_encode_response_label setText:@""];  // deprecated
            [_encode_challenge_image setImage:_checkbox_empty];
            
            [_encode_response_no_button setAlpha:0.5];
            [_encode_response_yes_button setAlpha:0.5];
            [_encode_response_image setImage:_checkbox_empty];
            
            [_encode_deposit_button setAlpha:0.5];
            [_encode_deposit_image setImage:_checkbox_empty];
            [_decode_deposit_button setAlpha:0.5];
            [_decode_deposit_image setImage:_checkbox_empty];
            
            [_end_label setText:@""];
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
            
            [_decode_key_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_PK :
        {
            [_decode_challenge_label setAlpha:0.5];
            [_decode_key_button setAlpha:0.5];
            [_decode_key_image setImage:_checkbox_checked];
            
            [_encode_challenge_button setAlpha:1.0];
        }
            break;
            
        case MODE_ENCODE_CHALLENGE :
        {
            [_encode_challenge_button setAlpha:0.5];
            [_encode_challenge_image setImage:_checkbox_checked];
            [_encode_challenge_label setText:[NSString stringWithFormat:@"Did Provider respond with %d?", _challenge + 1]];
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
            
            [_encode_deposit_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_RESPONSE :
        {
            NSLog(@"AddProviderCTViewController:configureView: TODO(aka) We are in MODE_DECODE_RESPONSE!");
        }
            break;
            
        case MODE_ENCODE_DEPOSIT :
        {
            [_decode_challenge_label setAlpha:0.5];
            
            [_encode_deposit_button setAlpha:0.5];
            [_encode_deposit_image setImage:_checkbox_checked];
            
            [_decode_deposit_button setAlpha:1.0];
        }
            break;
            
        case MODE_DECODE_DEPOSIT :
        {
            [_decode_deposit_button setAlpha:0.5];
            [_decode_deposit_image setImage:_checkbox_checked];

            [_end_label setText:@"Pairing complete, hit DONE!"];
        }
            break;
            
        default :
            NSLog(@"AddProviderCTViewController:configureView: ERROR: TODO(aka) unknown mode: %d.", _current_state);
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
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToConsumerMasterViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: unwinding to ConsumerMasterViewController.");
        
        // User hit DONE.
    } else if ([[segue identifier] isEqualToString:@"UnwindToAddProviderViewID"]) {
            if (kDebugLevel > 0)
                NSLog(@"AddProviderCTViewController:prepareForSeque: unwinding to AddProviderViewController.");
            
            // User hit CANCEL, nothing to do.
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodePKViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QREncodePKView.");
        
                // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodePKViewController* view_controller = (QREncodePKViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderCTViewController:prepareForSegue: ShowQREncodePKView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, and provider's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodePKViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QRDecodePKView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodePKViewController* view_controller = (QRDecodePKViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeChallengeViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QREncodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeChallengeViewController* view_controller = (QREncodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
        _challenge = arc4random() % 9999;  // get a four digit challenge (response will have + 1)
        NSString* encrypted_challenge = nil;
        NSString* err_msg = [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", _challenge] publicKeyRef:[_provider publicKeyRef] encryptedString:&encrypted_challenge];
        if (err_msg) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:prepareForSeque:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        } else {
            NSString* msg = [NSString stringWithFormat:@"%ld byte b64 challenge: %@", (unsigned long)[encrypted_challenge length], encrypted_challenge];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:prepareForSeque:" message:msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
        
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: using encrypted challenge: %s.", [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        view_controller.encrypted_challenge = encrypted_challenge;
        
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSegue: ShowQREncodeChallengeView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, provider's identity: %s and challenge: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeChallengeViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QRDecodeChallengeView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeChallengeViewController* view_controller = (QRDecodeChallengeViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowQREncodeDepositViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QREncodeDepositView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QREncodeDepositViewController* view_controller = (QREncodeDepositViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
        
        if (kDebugLevel > 1)
            NSLog(@"AddProviderCTViewController:prepareForSegue: ShowQREncodeDepositView controller's identity: %s, hash: %s, deposit: %s, public-key: %s, and provider's identity: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [view_controller.our_data.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]],[[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [view_controller.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowQRDecodeDepositViewID"]) {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: Segue'ng to QRDecodeDepositView.");
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        QRDecodeDepositViewController* view_controller = (QRDecodeDepositViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.identity = _provider.identity;
        view_controller.delegate = self;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"AddProviderCTViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) encodeResponseYes:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:encodeResponseYes: called.");
    
    _current_state = MODE_ENCODE_RESPONSE_YES;
    [self configureView];
}

- (IBAction) encodeResponseNo:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:encodeResponseNo: called.");
    
    _current_state = MODE_ENCODE_DEPOSIT;  // re-do scan of their key
    [_decode_key_image setImage:_checkbox_empty];
    [_encode_challenge_image setImage:_checkbox_empty];
    [_encode_challenge_label setText:@"Did Provider respond with ..."];
    [_encode_challenge_label setAlpha:0.5];
    [_encode_response_no_button setAlpha:0.5];
    [_encode_response_yes_button setAlpha:0.5];
    [self configureView];
}

#pragma mark - Delegate routines

// QREncodePKViewController delegate functions.
- (void) qrEncodePKViewControllerDidFinish {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodePKViewControllerDidFinish: called.");
    
    NSLog(@"AddProviderCTViewController:qrEncodePKViewControllerDidFinish: identity: %s.", [_provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    _current_state = MODE_ENCODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodePKViewControllerDidCancel:(QREncodePKViewController*)controller {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodePKViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodePKViewController delegate functions.
- (void) qrDecodePKViewControllerDidFinish:(NSString*)identity_hash publicKey:(NSData*)public_key {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrDecodePKViewControllerDidFinish: called.");
    
    if (identity_hash == nil) {
#if 1  // SIMULATOR HACK:  Fake identity hash and download public key from file-store.
        {
            UIDevice* ui_device = [UIDevice currentDevice];
            if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
                NSLog(@"qrDecodePKViewControllerDidFinish: Found device iPhone Simulator.");
                
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodePKViewControllerDidFinish:" message:[NSString stringWithFormat:@"done: called, but using simulator, so faking hash and key."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                identity_hash = [PersonalDataController hashMD5String:_provider.identity];
                
                NSURL* pub_key_url = [[NSURL alloc] initWithString:@"https://googledrive.com/host/0B_Z2PRmWhpcKeEx4MlhjRlVaNTg/public-key.b64"];
                NSError* status = nil;
                NSString* public_key_b64 = [[NSString alloc] initWithContentsOfURL:pub_key_url encoding:[NSString defaultCStringEncoding] error:&status];
                if (status) {
                    NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodePKViewControllerDidFinish: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    [self configureView];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    return;
                }
                public_key = [NSData dataFromBase64String:public_key_b64];
            }
        }
        
        // Fall-through so idenity_hash & public key can be processed as a success.
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodePKViewControllerDidFinish:" message:@"Scan was unsuccessful, canceling operation." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
#endif
    }

    // Add our identity hash and new public key to our Provider object.
    if (identity_hash != nil)
        _provider.identity_hash = identity_hash;
    if (public_key != nil) {
#if 1  // ACCESS_GROUP
        NSString* err_msg = [_provider setPublicKey:public_key accessGroup:[NSString stringWithFormat:@"%s", kAccessGroupCT]];
#else
        NSString* err_msg = [_provider setPublicKey:public_key accessGroup:nil];
#endif
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodePKViewControllerDidFinish:" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderCTViewController:qrDecodePKViewControllerDidFinish: identity: %s, hash: %s, public key: %s, publicKeyRef: %d.", [_provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [_provider.identity_hash cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_provider.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]], ([_provider publicKeyRef] == NULL ? false : true));
    
    _current_state = MODE_DECODE_PK;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodePKViewControllerDidCancel:(QRDecodePKViewController*)controller {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrDecodePKViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeChallengeViewController delegate functions.
- (void) qrEncodeChallengeViewControllerDidFinish {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodeChallengeViewControllerDidFinish: called.");
    
    _current_state = MODE_ENCODE_CHALLENGE;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeChallengeViewControllerDidCancel:(QREncodeChallengeViewController *)controller {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeChallengeViewController delegate functions.
- (void) qrDecodeChallengeViewControllerDidFinish:(NSString*)scan_results {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidFinish: called.");
    
    NSString* challenge_b64 = nil;
    
    if (scan_results == nil) {
#if 1  // SIMULATOR HACK: Download the challenge from the file-store.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidFinish: TOOD(aka) Found device iPhone Simulator.");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodeChallengeViewControllerDidFinish:" message:[NSString stringWithFormat:@"done: called, but using simulator, so downloading challenge."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            NSURL* challenge_url = [[NSURL alloc] initWithString:@"https://googledrive.com/host/0B_Z2PRmWhpcKeEx4MlhjRlVaNTg/challenge.b64"];
            NSError* status = nil;
            challenge_b64 = [[NSString alloc] initWithContentsOfURL:challenge_url encoding:[NSString defaultCStringEncoding] error:&status];
            if (status) {
                NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"qrDecodeChallengeViewControllerDidFinish: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [self configureView];
                [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
        }
        
        // Fall-through to process encrypted challenge string.
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidFinish:" message:@"Scan was unsuccessful, canceling operation!" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
#endif
    } else {
        challenge_b64 = scan_results;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidFinish: decrypting: %s.", [scan_results cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Decrypt the challenge.
    NSString* challenge_str = nil;
    NSString* err_msg = [PersonalDataController asymmetricDecryptString:challenge_b64 privateKeyRef:_our_data.privateKeyRef string:&challenge_str];
    if (err_msg) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidFinish: TODO(aka)" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
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
        NSLog(@"AddProviderCTViewController:qrDecodeChallengeViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QREncodeDepositViewController delegate functions.
- (void) qrEncodeDepositViewControllerDidFinish {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodeDepositViewControllerDidFinish: called.");
    
    _current_state = MODE_ENCODE_DEPOSIT;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrEncodeDepositViewControllerDidCancel:(QREncodeDepositViewController*)controller {
    if (kDebugLevel > 4)
        NSLog(@"AddProviderCTViewController:qrEncodeDepositViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// QRDecodeDepositViewController delegate functions.
- (void) qrDecodeDepositViewControllerDidFinish:(NSMutableDictionary*)deposit {
    if (kDebugLevel > 4)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidFinish: called.");
    
    if (deposit == nil) {
#if 1  // SIMULATOR HACK:  Simulator can't scan, so fake the deposit, since we can't send SMS anyways!
        // For Debugging:
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"AddProviderCTViewController:qrDecodeDepositViewControllerDidFinish:" message:@"Scan was unsuccessful, canceling operation!" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        
        [self configureView];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
#endif
    }
    
    // Add our new key deposit to our Consumer object.
    [_provider setDeposit:deposit];
    
    if (kDebugLevel > 0)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositKeyViewControllerDidFinish: identity: %s, key deposit %s, public key: %s.", [_provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_provider.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_provider.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    _current_state = MODE_DECODE_DEPOSIT;
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) qrDecodeDepositViewControllerDidCancel:(QRDecodeDepositViewController*)controller {
    if (kDebugLevel > 4)
        NSLog(@"AddConsumerCTViewController:qrDecodeDepositViewControllerDidCancel: called.");
    
    [self configureView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
