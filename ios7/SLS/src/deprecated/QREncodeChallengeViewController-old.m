//
//  QREncodeChallengeViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/4/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <QuartzCore/CALayer.h>
//#import <QREncoder/QREncoder.h>         // deprecated

#import "QREncodeChallengeViewController.h"
#import "AddProviderViewController.h"     // for checking delegate
#import "AddConsumerViewController.h"     // for checking delegate
#import "NSData+Base64.h"
#import "qrencode.h"


static const int kDebugLevel = 1;

static const CGFloat kPadding = 10;  // used in QREncode

@interface QREncodeChallengeViewController ()
@end

@implementation QREncodeChallengeViewController

@synthesize our_data = _our_data;
@synthesize identity = _identity;
@synthesize encrypted_challenge = _encrypted_challenge;
@synthesize delegate = _delegate;
@synthesize image_label = _image_label;
@synthesize image_view = _image_view;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _identity = nil;
        _encrypted_challenge = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _identity = nil;
        _encrypted_challenge = nil;
        _delegate = nil;
        _image_view = nil;
        _image_label = nil;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    _our_data = nil;
    _identity = nil;
    [self setImage_label:nil];
    [self setImage_view:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:configureView: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"QREncodeChallengeViewController:configureView: QR-encoding challenge: %s.", [_encrypted_challenge cStringUsingEncoding: [NSString defaultCStringEncoding]]);
    
    // Set the *image* to our QR-encoded challenge.
    UIImage* image = nil;
    NSString* error_msg = [PersonalDataController printQRString:_encrypted_challenge width:_image_view.bounds.size.width image:&image];
    if (error_msg) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"QREncodeChallengeViewController:configureView:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        _image_view.image = image;
        
        // Set additional UIImageView parameters.
        _image_view.backgroundColor = [UIColor whiteColor];
        //CGFloat qrSize = _image_view.bounds.size.width - kPadding * 2;
        //_image_view.frame = CGRectMake(kPadding, (_view.bounds.size.height - qrSize) / 2, qrSize, qrSize);
        [_image_view layer].magnificationFilter = kCAFilterNearest;
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:done: called");
    
    [[self delegate] qrEncodeChallengeViewControllerDidFinish];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:cancel: called");
    
    [[self delegate] qrEncodeChallengeViewControllerDidCancel:self];
}

/* XXX
- (IBAction) buttonPressed:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"QREncodeChallengeViewController:buttonPressed: called");
    
    [self viewDidLoad];  // XXX TODO(aka) I think we just want configureView here!
}
*/

// Delegate functions.

@end

