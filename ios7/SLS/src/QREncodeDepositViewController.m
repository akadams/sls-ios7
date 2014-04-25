//
//  QREncodeDepositViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "QREncodeDepositViewController.h"
#import "NSData+Base64.h"
#import "qrencode.h"


static const int kDebugLevel = 1;

// XXX static const CGFloat kPadding = 10;  // used in QREncode


@interface QREncodeDepositViewController ()
@end

@implementation QREncodeDepositViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize delegate = _delegate;

#pragma mark - Local variables
@synthesize image_label = _image_label;
@synthesize image_view = _image_view;
// XXX @synthesize change_button = _change_button;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_label = nil;
        _image_view = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _delegate = nil;
        _image_label = nil;
        _image_view = nil;
        // XXX _change_button = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:configureView: called.");
    
    // Get ASCII version of key deposit.
    NSString* deposit_str = [PersonalDataController serializeDeposit:_our_data.deposit];
    
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:configureView: QR-encoding Key-Deposit: %s.", [deposit_str cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    // Set the *image* to our QR-encoded key deposit.
    UIImage* image = [_our_data printQRDeposit:_image_view.bounds.size.width];
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
        NSLog(@"QREncodeDepositViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:done: called");
    
    [[self delegate] qrEncodeDepositViewControllerDidFinish];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeDepositViewController:cancel: called");
    
    [[self delegate] qrEncodeDepositViewControllerDidCancel:self];
}

@end
