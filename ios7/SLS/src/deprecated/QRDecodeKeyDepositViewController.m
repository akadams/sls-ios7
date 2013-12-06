//
//  QRDecodeKeyDepositViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVMetadataObject.h>

#import "QRDecodeKeyDepositViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;

@interface QRDecodeKeyDepositViewController ()
@end

@implementation QRDecodeKeyDepositViewController

@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize scan_results = _scan_results;
@synthesize delegate = _delegate;
@synthesize label = _label;
@synthesize scan_button = _scan_button;
@synthesize text_view = _text_view;
// XXX @synthesize done_button = _done_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _scan_results = nil;
        _delegate = nil;
        _scan_button = nil;
        _text_view = nil;
        // XXX _done_button = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _scan_results = nil;
        _delegate = nil;
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setScan_button:nil];
    [self setText_view:nil];
    // XXX [self setDone_button:nil];
    [self setLabel:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:configureView: called.");
    
    NSString* msg = [NSString stringWithFormat:@"Ask \"%s\" to print their key deposit using QR encoding.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    [_label setText:msg];
    [_text_view setText:@""];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:done: called.");
    
    if (_scan_results == nil) {
#if 1
        // For Debugging: the simulator can't scan, so we have to fake it.
        UIDevice* ui_device = [UIDevice currentDevice];
        if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
            NSLog(@"QRDecodeKeyDepositViewController:done: TOOD(aka) Found device iPhone Simulator.");
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyDepositViewController" message:[NSString stringWithFormat:@"done: called, but using simulator, so faking key deposit."] delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            _scan_results = @"sms:4125551212";
        }
#else
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Decode Key Deposit" message:@"Scan was unsuccessful, canceling operation." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [[self delegate] qrDecodeKeyDepositViewControllerDidCancel:self];
        return;
#endif
    }
    
    NSLog(@"QRDecodeKeyDepositViewController:done: _scan_results: %s.", [_scan_results cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Convert our scanned *string* encoded key deposit to a NSMutableDictionary* and return it to our caller.
    
    NSMutableDictionary* key_deposit = [PersonalDataController stringToKeyDeposit:_scan_results];
    [[self delegate] qrDecodeKeyDepositViewControllerDidFinish:key_deposit];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:cancel: called.");
    
    [[self delegate] qrDecodeKeyDepositViewControllerDidCancel:self];
}

- (IBAction) scanStart:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:scanStart: called.");
    
    NSError* status = nil;
    
    // Setup an AVCaptureSession, an AVCaptureDevice and Input, then add the Input to the session.
    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice* videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"QRDecodeKeyDepositViewController:scanStart: TODO(aka) Need to set preset!");
    
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&status];
    if (!videoInput || status != nil) {
        NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyDepositViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    } else {
        NSString* err_msg = @"AVCaptureSession:canAddInput: returned false.";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeKeyDepositViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    // Get a MetadataOutput, assign its delegate and type, then add it to our session.
    AVCaptureMetadataOutput* metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    NSLog(@"QRDecodeKeyDepositViewController:scanStart: TODO(aka) Need to check that TypeQRCode exists first with availableMetadataObjectTypes!");
    
    NSArray* array = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
    [metadataOutput setMetadataObjectTypes:array];
    [captureSession addOutput:metadataOutput];
    
    NSLog(@"QRDecodeKeyDepositViewController:scanStart: TODO(aka) starting captureSession, but not sure where to stop it!");
    
    [captureSession startRunning];
}

/* XXX
- (IBAction)scanOkay:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeKeyDepositViewController:scanOkay: called.");
    
    // Assign scanned object to Consumer object.
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeKeyDepositViewController:scanOkay: adding key deposit: %s.", [_scan_results cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSMutableDictionary* key_deposit = [PersonalDataController stringToKeyDeposit:_scan_results];
    [_identity setKey_deposit:key_deposit];
    
    [[self delegate] qrDecodeKeyDepositViewControllerDidFinish:_identity];        
}
*/


// Delegate functions.

// AVCaptureMetadataOutput delegate functions.
- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*)connection {
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeKeyDepositViewController:captureOutput:didOutputMetadataObjects:fromConnection: called.");
    
    // Get decoded result from array, store it, and change our UIView.
    NSLog(@"QRDecodeKeyDepositViewController:captureOutput:didOutputMetadataObjects:fromConnection: TODO(aka) Check to see if there is more than one object!");
    
    _scan_results = [metadataObjects objectAtIndex:0];  // just grab first element
    NSString* message = [[NSString alloc] initWithFormat:@"If the contents below look correct, hit DONE, otherwise rescan with SCAN button above:\n\n"];
    message = [message stringByAppendingString:_scan_results];
    _text_view.text = message;
    
    // XXX [_done_button setTitle:@"OKAY" forState:UIControlStateNormal];
    
    // XXX How do we stopRunning?  I tihnk we need to make it a property of this Class!
}

@end
