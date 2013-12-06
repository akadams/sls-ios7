//
//  KeyDepositDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/20/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "KeyDepositDataViewController.h"


static const int kDebugLevel = 0;

@interface KeyDepositDataViewController ()

@end

@implementation KeyDepositDataViewController

@synthesize our_data = _our_data;
@synthesize delegate = _delegate;
@synthesize label1 = _label1;
@synthesize label2 = _label2;
@synthesize label3 = _label3;
@synthesize label4 = _label4;
@synthesize label5 = _label5;
@synthesize label2_input = _label2_input;
@synthesize label3_input = _label3_input;
@synthesize label4_input = _label4_input;
@synthesize label5_input = _label5_input;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
    }
    
    return self;    
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
    }

    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.

    [self configureView];  // update the view with correct labels
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:viewDidUnload: called.");
    
    [self setLabel2:nil];
    [self setLabel2_input:nil];
    [self setLabel3:nil];
    [self setLabel3_input:nil];
    [self setLabel4:nil];
    [self setLabel4_input:nil];
    [self setLabel5:nil];
    [self setLabel5_input:nil];
    [super viewDidUnload];
    
    // Note, this is where we clean up any *strong* references.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:configureView: called.");
    
    // Update the user interface based on chosen service.
    if ([PersonalDataController isKeyDepositTypeSMS:_our_data.key_deposit]) {
        _label1.text = @"SMS Parameters";
        _label2.text = @"Phone Number";
        _label3.text = @"";
        [_label3_input setHidden:TRUE];
        _label4.text = @"";
        [_label4_input setHidden:TRUE];
        _label5.text = @"";
        [_label5_input setHidden:TRUE];
        
        // Initialize what the text field show.
        NSString* number = [PersonalDataController getKeyDepositPhoneNumber:_our_data.key_deposit];
        if ([number length])
            _label2_input.text = number;
    } else if ([PersonalDataController isKeyDepositTypeEMail:_our_data.key_deposit]) {
        _label1.text = @"Email Parameters";
        _label2.text = @"Address";
        _label3.text = @"";
        [_label3_input setHidden:TRUE];
        _label4.text = @"";
        [_label4_input setHidden:TRUE];
        _label5.text = @"";
        [_label5_input setHidden:TRUE];
        
        // Initialize what the text field show.
        NSString* address = [PersonalDataController getKeyDepositAddress:_our_data.key_deposit];
        if ([address length])
            _label2_input.text = address;
    } else {
        _label1.text = @"ERROR";
        _label2.text = @"";
        [_label2_input setHidden:TRUE];
        _label3.text = @"";
        [_label3_input setHidden:TRUE];
        _label4.text = @"";
        [_label4_input setHidden:TRUE];
        _label5.text = @"";
        [_label5_input setHidden:TRUE];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Key Deposit Configuration" message:@"You must go back and choose a key deposit!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:done: called.");
    
    // Build our file store dictionary with the data we collected.
    if ([PersonalDataController isKeyDepositTypeSMS:_our_data.key_deposit]) {
        [PersonalDataController setKeyDeposit:_our_data.key_deposit phoneNumber:_label2_input.text];
        
        // And write it out to disk.
        [_our_data saveKeyDepositState];
    } else {
        NSLog(@"KeyDepositDataViewController:done: WARN: Unknown file store service!");
    }
    
    // Call our delegate, passing them *just* our key deposit dictionary.
    [[self delegate] keyDepositDataViewControllerDidFinish:_our_data.key_deposit];
}

- (IBAction)cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"KeyDepositDataViewController:cancel: called.");
    
    [[self delegate] keyDepositDataViewControllerDidCancel:self];
}


// Delegate functions.

// UITextField delegate functions.
- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if ((text_field == _label2_input) || (text_field == _label3_input) ||
        (text_field == _label4_input)) {
        [text_field resignFirstResponder];
    }
    
    return YES;
}

@end
