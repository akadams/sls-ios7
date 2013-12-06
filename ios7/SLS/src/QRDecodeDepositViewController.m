//
//  QRDecodeDepositViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVMetadataObject.h>

#import "QRDecodeDepositViewController.h"
#import "NSData+Base64.h"


static const int kDebugLevel = 1;


@interface QRDecodeDepositViewController ()
@end

@implementation QRDecodeDepositViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;

#pragma mark - Local variables
@synthesize scan_results = _scan_results;
@synthesize label = _label;
@synthesize scan_button = _scan_button;
@synthesize text_view = _text_view;
// XXX @synthesize done_button = _done_button;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _scan_results = nil;
        _scan_button = nil;
        _text_view = nil;
        // XXX _done_button = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _scan_results = nil;
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:configureView: called.");
    
    NSString* msg = [NSString stringWithFormat:@"Ask \"%s\" to print their key deposit using QR encoding.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    [_label setText:msg];
    [_text_view setText:@""];
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:done: called.");
    
    NSLog(@"QRDecodeDepositViewController:done: _scan_results: %s.", [_scan_results cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Convert our scanned *string* encoded key deposit to a NSMutableDictionary* and return it to our caller.
    NSMutableDictionary* deposit = [PersonalDataController stringToDeposit:_scan_results];
    
    [[self delegate] qrDecodeDepositViewControllerDidFinish:deposit];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:cancel: called.");
    
    [[self delegate] qrDecodeDepositViewControllerDidCancel:self];
}

- (IBAction) scanStart:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeDepositViewController:scanStart: called.");
    
    NSError* status = nil;
    
    // Setup an AVCaptureSession, an AVCaptureDevice and Input, then add the Input to the session.
    AVCaptureSession* captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice* videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"QRDecodeDepositViewController:scanStart: TODO(aka) Need to set preset!");
    
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&status];
    if (!videoInput || status != nil) {
        NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeDepositViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    } else {
        NSString* err_msg = @"AVCaptureSession:canAddInput: returned false.";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeDepositViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Get a MetadataOutput, assign its delegate and type, then add it to our session.
    AVCaptureMetadataOutput* metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // If we have a QR type, add it to our session.
    NSArray* types = [metadataOutput availableMetadataObjectTypes];
    bool found = false;
    for (id object in types) {
        NSString* type = (NSString*)object;
        NSLog(@"QRDecodePKViewController:scanStart: found type: %@.", type);
        if ([type isEqualToString:AVMetadataObjectTypeQRCode])
            found = true;
    }
    
    if (!found) {
        NSString* err_msg = @"AVCaptureSession:availableMetadataObjectTypes: TypeQRCode not found!";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodePKViewController:scanStart: availableMetadataObjectTypes:" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSArray* array = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
    [metadataOutput setMetadataObjectTypes:array];
    [captureSession addOutput:metadataOutput];
    
    NSLog(@"QRDecodeDepositViewController:scanStart: TODO(aka) starting captureSession, but not sure where to stop it!");
    
    [captureSession startRunning];
}

#pragma mark - Delegate routines

// AVCaptureMetadataOutput delegate functions.
- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*)connection {
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeDepositViewController:captureOutput:didOutputMetadataObjects:fromConnection: called.");
    
    // Get decoded result from array, store it, and change our UIView.
    NSLog(@"QRDecodeDepositViewController:captureOutput:didOutputMetadataObjects:fromConnection: TODO(aka) Check to see if there is more than one object!");
    
    _scan_results = [metadataObjects objectAtIndex:0];  // just grab first element
    NSString* message = [[NSString alloc] initWithFormat:@"If the contents below look correct, hit DONE, otherwise rescan with SCAN button above:\n\n"];
    message = [message stringByAppendingString:_scan_results];
    _text_view.text = message;
    
    // XXX [_done_button setTitle:@"OKAY" forState:UIControlStateNormal];
    
    NSLog(@"QRDecodeDepositViewController:captureOutput:didOutputMetadataObjects:fromConnection: XXX TODO(aka) How do we stopRunning?  I tihnk we need to make it a property of this Class!");
}

@end
