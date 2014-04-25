//
//  QRDecodePKViewController.m
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

#import "QRDecodePKViewController.h"


static const int kDebugLevel = 1;


@interface QRDecodePKViewController ()
@end

@implementation QRDecodePKViewController

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
@synthesize identity_hash = _identity_hash;
@synthesize public_key = _public_key;

@synthesize label = _label;
@synthesize scan_button = _scan_button;
@synthesize text_view = _text_view;
// XXX @synthesize done_button = _done_button;

#pragma mark - Initialization
- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _device = nil;
        _input = nil;
        _output = nil;
        _session = nil;
        _preview_layer = nil;
        _identity_hash = nil;
        _public_key = nil;
        
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:initWithNibName:bundle: called, but not implemented.");
    
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
        _identity_hash = nil;
        _public_key = nil;
        
        _scan_button = nil;
        _text_view = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:configureView: called.");
    
    NSString* msg = [NSString stringWithFormat:@"Ask \"%s\" to print their key using QR encoding.", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    [_label setText:msg];
    [_text_view setText:@""];
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:done: called.");
    
    [[self delegate] qrDecodePKViewControllerDidFinish:_identity_hash publicKey:_public_key];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:cancel: called.");
    
    [[self delegate] qrDecodePKViewControllerDidCancel:self];
}

- (IBAction) scanStart:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QRDecodePKViewController:scanStart: called.");
    
    NSError* status = nil;
    
    // Setup an AVCaptureDevice an AVCaptureDeviceInput, AVCaptureOutput and an AVCaptureSession.
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSLog(@"QRDecodePKViewController:scanStart: TODO(aka) Need to set preset ... maybe!");
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&status];
    if (!_input || status != nil) {
        NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodePKViewController:scanStart: deviceInputWithDevice()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodePKViewController:scanStart: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodePKViewController:scanStart: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
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
        NSLog(@"QRDecodePKViewController:captureOutput:didOutputMetadataObjects:fromConnection: called.");
    
    if (metadata_objects == nil || [metadata_objects count] == 0) {
        NSString* err_msg = @"objects nil or empty!";
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QRDecodePKViewController:captureOutput:didOutputMetadataObjects: " message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [_session stopRunning];
        return;
    }
    
    if ([metadata_objects count] > 1)
        NSLog(@"QRDecodePKViewController:captureOutput: TODO(aka) there are %ld metadata objects!", (unsigned long)[metadata_objects count]);
    
    NSString* scan_result = [[metadata_objects objectAtIndex:0] stringValue];  // just grab the first result

    // Parse what was returned, and change our UIView to show it.
    NSString* identity_hash = nil;
    NSString* public_key_b64 = nil;
    NSString* error_msg = [PersonalDataController parseQRScanResult:scan_result identityHash:&identity_hash publicKey:&public_key_b64];
    
    if (kDebugLevel > 0)
        NSLog(@"QRDecodePKViewController:captureOutput:didOutputMetadataObjects:fromConnection: scanned base64 key: %s.", [public_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
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
            NSLog(@"QRDecodePKViewController:captureOutput:didOutputMetadataObjects:fromConnection: QR-decoding PK(Hash: %s): %s.", [[PersonalDataController hashMD5Data:_public_key] cStringUsingEncoding:[NSString defaultCStringEncoding]], [public_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    _text_view.text = message;
    
    [_session stopRunning];
    
    // And (hopefully), remove the preview layer.
    [self.view sendSubviewToBack:_scan_view];
    /*
    CALayer* top = [self.view.layer.sublayers lastObject];
    [top removeFromSuperlayer];
     */
}

@end
