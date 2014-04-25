//
//  QRDecodeChallengeViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVMetadataObject.h>

#import "NSData+Base64.h"

#import "QRDecodeChallengeViewController.h"


static const int kDebugLevel = 3;


@interface QRDecodeChallengeViewController ()
@end

@implementation QRDecodeChallengeViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;

#pragma mark - Local variables
@synthesize device = _device;
@synthesize input = _input;
@synthesize output = _output;
@synthesize session = _session;
@synthesize preview_layer = _preview_layer;
@synthesize scan_view = _scan_view;
@synthesize scan_results = _scan_results;

@synthesize label = _label;
@synthesize scan_button = _scan_button;
@synthesize text_view = _text_view;
// XXX @synthesize done_button = _done_button;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _device = nil;
        _input = nil;
        _output = nil;
        _session = nil;
        _preview_layer = nil;
        
        _scan_results = nil;
        
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _device = nil;
        _input = nil;
        _output = nil;
        _session = nil;
        _preview_layer = nil;
        
        _scan_results = nil;

        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:configureView: called.");
    
    NSString* msg = [NSString stringWithFormat:@"Ask \"%s\" to print their challenge using QR encoding.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    [_label setText:msg];
    [_scan_button setTitle:@"Tap to Scan When Ready" forState:UIControlStateNormal];
    [_text_view setText:@""];
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:done: called.");
    
    [[self delegate] qrDecodeChallengeViewControllerDidFinish:_scan_results];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeChallengeViewController:cancel: called.");
    
    [[self delegate] qrDecodeChallengeViewControllerDidCancel:self];
}

- (IBAction) scanStart:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodeChallengeViewController:scanStart: called.");
    
    NSError* status = nil;
    
    // Setup an AVCaptureDevice an AVCaptureDeviceInput, AVCaptureOutput and an AVCaptureSession.
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"QRDecodeChallengeViewController:scanStart: TODO(aka) Need to set preset ... maybe!");
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&status];
    if (!_input || status != nil) {
        NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeChallengeViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    _session = [[AVCaptureSession alloc] init];
    
    // Add the output to the session.
    [_session addOutput:_output];
    
    
    // Add the input to the session.
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    } else {
        NSString* err_msg = @"AVCaptureSession:canAddInput: returned false.";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeChallengeViewController:scanStart: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Set us up to get AVCaptureMetadataOutput callbacks.
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Add the QR Type to our output ...
#if 0
    // Make sure we have a QR type.
    NSArray* types = [_output availableMetadataObjectTypes];
    if (types == nil || [types count] == 0) {
        NSString* err_msg = @"AVCaptureSession:availableMetadataObjectTypes: no types available!";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeChallengeViewController:scanStart: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    bool found = false;
    for (id object in types) {
        NSString* type = (NSString*)object;
        NSLog(@"QRDecodeChallengeViewController:scanStart: found type: %@.", type);
        if ([type isEqualToString:AVMetadataObjectTypeQRCode])
            found = true;
    }
    
    if (!found) {
        NSString* err_msg = @"AVCaptureSession:availableMetadataObjectTypes: TypeQRCode not found!";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeChallengeViewController:scanStart: availableMetadataObjectTypes:" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSArray* array = [NSArray arrayWithObject:AVMetadataObjectTypeQRCode];
    [_output setMetadataObjectTypes:array];
#else
    // TODO(aka) Perhaps I misunderstood the description of availableMetadataObjectTypes:, because the above doesn't work.  <sigh>
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
#endif
    
    // Build the preview layer.
    _session.sessionPreset = AVCaptureSessionPresetPhoto;  // TODO(aka) not sure if this is necessary ...
    _preview_layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    CGRect bounds = self.view.bounds;  // TODO(aka) self.view.layer.bounds?
    _scan_view = [[UIView alloc] initWithFrame:bounds];
    
#if 0 // TODO(aka) Not sure if we need this ...
    _preview_layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview_layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    AVCaptureConnection* con = _preview_layer.connection;
    con.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
#endif
    
    _preview_layer.frame = _scan_view.frame;
    [_scan_view.layer addSublayer:_preview_layer];
    [self.view addSubview:_scan_view];
    
    [_session startRunning];
}


#pragma mark - Delegate routines

// AVCaptureMetadataOutput delegate functions.
- (void) captureOutput:(AVCaptureOutput*)capture_output didOutputMetadataObjects:(NSArray*)metadata_objects fromConnection:(AVCaptureConnection*)connection {
    if (kDebugLevel > 0)
        NSLog(@"QRDecodeChallengeViewController:captureOutput:didOutputMetadataObjects:fromConnection: called.");
    
    if (metadata_objects == nil || [metadata_objects count] == 0) {
        NSString* err_msg = @"objects nil or empty!";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodeChallengeViewController:captureOutput:didOutputMetadataObjects: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [_session stopRunning];
        return;
    }
    
    if ([metadata_objects count] > 1)
        NSLog(@"QRDecodeChallengeViewController:captureOutput: TODO(aka) there are %ld metadata objects!", (unsigned long)[metadata_objects count]);
    
    _scan_results = [[metadata_objects objectAtIndex:0] stringValue];  // just grab the first result
    
    // Parse what was returned, and change our UIView to show it.
    NSString* message = [[NSString alloc] initWithFormat:@"If the contents below look correct, hit DONE, otherwise rescan with SCAN button above:\n\n"];
    message = [message stringByAppendingString:_scan_results];
    _text_view.text = message;
    
    [_session stopRunning];
    
    // And (hopefully), remove the preview layer.
    [self.view sendSubviewToBack:_scan_view];
}

@end
