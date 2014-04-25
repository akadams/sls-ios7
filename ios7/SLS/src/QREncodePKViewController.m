//
//  QREncodePKViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "QREncodePKViewController.h"
#import "NSData+Base64.h"
#import "qrencode.h"


static const int kDebugLevel = 1;

//static const CGFloat kPadding = 10;  // used in QREncode


@interface QREncodePKViewController ()
@end

@implementation QREncodePKViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;

#pragma mark - Outlets
@synthesize image_label = _image_label;
@synthesize image_view = _image_view;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:configureView: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"QREncodePKViewController:configureView: QR-encoding PK(Hash: %s): %s.", [[PersonalDataController hashMD5Data:[_our_data getPublicKey]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[[_our_data getPublicKey] base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
#if 1
    UIImage* image = [_our_data printQRPublicKey:_image_view.bounds.size.width];
#else
    // Base64 our public key.
    NSString* public_key = [_our_data.getPublicKey base64EncodedString];
    
    // TODO(aka) Apparently, our *first* borrowed QR-encoder library does not have enough memory to QR encode our 191B base64 encoded public key.
    
    UIImage* image = [QREncoder encode:public_key size:8 correctionLevel:QRCorrectionLevelHigh];
#endif
    
    _image_view.image = image;
    
    // Set additional UIImageView parameters.
    _image_view.backgroundColor = [UIColor whiteColor];
    //CGFloat qrSize = _image_view.bounds.size.width - kPadding * 2;
    //_image_view.frame = CGRectMake(kPadding, (_view.bounds.size.height - qrSize) / 2, qrSize, qrSize);
    [_image_view layer].magnificationFilter = kCAFilterNearest;
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:done: called");
    
    [[self delegate] qrEncodePKViewControllerDidFinish];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodePKViewController:cancel: called");
    
    [[self delegate] qrEncodePKViewControllerDidCancel:self];
}

@end
