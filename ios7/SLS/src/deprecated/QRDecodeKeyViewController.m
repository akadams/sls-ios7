//
//  QRDecodeKeyViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVMetadataObject.h>

#import "QRDecodeKeyViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

@interface QRDecodeKeyViewController ()
@end

@implementation QRDecodeKeyViewController

@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize identity_hash = _identity_hash;
@synthesize public_key = _public_key;
@synthesize delegate = _delegate;
@synthesize label = _label;
@synthesize scan_button = _scan_button;
@synthesize text_view = _text_view;
// XXX @synthesize done_button = _done_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _identity_hash = nil;
        _public_key = nil;
        _delegate = nil;
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _identity_hash = nil;
        _public_key = nil;
        _delegate = nil;
        _scan_button = nil;
        _text_view = nil;
    }

    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setScan_button:nil];
    [self setText_view:nil];
    // XXX [self setDone_button:nil];
    [self setLabel:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:configureView: called.");
    
    NSString* msg = [NSString stringWithFormat:@"Ask \"%s\" to print their key using QR encoding.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    [_label setText:msg];
    [_text_view setText:@""];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:done: called.");
    
    if (_identity_hash == nil) {
#if 1
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"QRDecodeKeyViewController:done: TOOD(aka) Found device iPhone Simulator.");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyViewController" message:[NSString stringWithFormat:@"done: called, but using simulator, so faking hash and key."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            _identity_hash = [PersonalDataController hashMD5String:_identity];
            
            // For the public key, if this is my cell phone, grab my public key from my file store.
            
            if ([_identity isEqualToString:@"Andrew K. Adams"]) {
                NSURL* pub_key_url = [[NSURL alloc] initWithString:@"https://s3.amazonaws.com/aka-tmp-sls-shadow/public-key.b64"];
                NSError* status = nil;
                NSString* public_key_b64 = [[NSString alloc] initWithContentsOfURL:pub_key_url encoding:[NSString defaultCStringEncoding] error:&status];
                if (status) {
                    NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];    
                } else {
                    _public_key = [NSData dataFromBase64String:public_key_b64];
                }
            } else {
                NSLog(@"QRDecodeKeyViewController:done: working with _identity: %s, so just setting public key to simulators.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
               // Just use the simulator's public key.
                _public_key = [_our_data getPublicKey];  
            }
            
            [[self delegate] qrDecodeKeyViewControllerDidFinish:_identity_hash publicKey:_public_key];
            return;
        }
#endif
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Decode Key" message:@"Scan was unsuccessful, canceling operation." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [[self delegate] qrDecodeKeyViewControllerDidCancel:self];
        return;
    }
    
    [[self delegate] qrDecodeKeyViewControllerDidFinish:_identity_hash publicKey:_public_key];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:cancel: called.");
    
    [[self delegate] qrDecodeKeyViewControllerDidCancel:self];
}

- (IBAction) scanStart:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:scanStart: called.");
    
    NSError* status = nil;
    
    // Setup an AVCaptureSession, an AVCaptureDevice and Input, then add the Input to the session.
    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice* videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"QRDecodeKeyViewController:scanStart: TODO(aka) Need to set preset!");
    
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&status];
    if (!videoInput || status != nil) {
        NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    } else {
        NSString* err_msg = @"AVCaptureSession:canAddInput: returned false.";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    // Get a MetadataOutput, assign its delegate and type, then add it to our session.
    AVCaptureMetadataOutput* metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    NSLog(@"QRDecodeKeyViewController:scanStart: TODO(aka) Need to check that TypeQRCode exists first with availableMetadataObjectTypes!");
    
    NSArray* array = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
    [metadataOutput setMetadataObjectTypes:array];
    [captureSession addOutput:metadataOutput];
    
    NSLog(@"QRDecodeKeyViewController:scanStart: TODO(aka) starting captureSession, but not sure where to stop it!");
    
    [captureSession startRunning];
}

/* XXX
- (IBAction)scanOkay:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyViewController:scanOkay: called.");
 
    // Not currently used.
}
*/

// Delegate functions.

// AVCaptureMetadataOutput delegate functions.
- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*)connection {
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeKeyViewController:captureOutput:didOutputMetadataObjects:fromConnection: called.");

    // Get decode results from array.
    NSLog(@"QRDecodeKeyViewController:captureOutput:didOutputMetadataObjects:fromConnection: TODO(aka) Check to see if there is more than one object!");
    
    NSString* scan_result = [metadataObjects objectAtIndex:0];  // just grab first element
    
    // Parse what was returned, and change our UIView to show it.
    NSString* identity_hash = nil;
    NSString* public_key_b64 = nil;
    NSString* error_msg = [PersonalDataController parseQRScanResult:scan_result identityHash:&identity_hash publicKey:&public_key_b64];
    
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeKeyViewController:captureOutput:didOutputMetadataObjects:fromConnection: scanned base64 key: %s.", [public_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* message = nil;
    if (error_msg != nil) {
        message = [[NSString alloc] initWithFormat:@"Scan failed, rescan with SCAN button above:\n\nERROR: "];
        message = [message stringByAppendingString:error_msg];
    } else if (identity_hash == nil || [identity_hash length] == 0 || public_key_b64 == nil || [public_key_b64 length] == 0) {
        message = [[NSString alloc] initWithFormat:@"Scan failed, rescan with SCAN button above:\n\nDebugging:\n"];
        message = [message stringByAppendingString:scan_result];
    } else {
        message = [[NSString alloc] initWithFormat:@"Scanned successful, hit DONE to move to the next phase.\n\nDebugging:\n"];
        message = [message stringByAppendingString:scan_result];
        // XXX [_done_button setTitle:@"OKAY" forState:UIControlStateNormal];
        
        _identity_hash = identity_hash;
        _public_key = [NSData dataFromBase64String:public_key_b64];
        
        if (kDebugLevel > 0)
            NSLog(@"QRDecodeKeyViewController:captureOutput:didOutputMetadataObjects:fromConnection: QR-decoding PK(Hash: %s): %s.", [[PersonalDataController hashMD5Data:_public_key] cStringUsingEncoding:[NSString defaultCStringEncoding]], [public_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    _text_view.text = message;
    
    // XXX How do we stopRunning?  I tihnk we need to make it a property of this Class!
}

@end
