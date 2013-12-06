//
//  FileStoreDataViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/20/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "FileStoreDataViewController.h"


static const int kDebugLevel = 0;

@interface FileStoreDataViewController ()

@end

@implementation FileStoreDataViewController

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
        NSLog(@"FileStoreDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
    }
    
    return self;    
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.

    [self configureView];  // update the view with correct labels
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:viewDidUnload: called.");
    
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
        NSLog(@"FileStoreDataViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:configureView: called.");
    
    // Update the user interface based on chosen service.
    if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
        _label1.text = @"Amazon S3 Parameters";
        _label2.text = @"Access Key";
        _label3.text = @"Secret Key";
        _label4.text = @"";
        [_label4_input setHidden:TRUE];
        _label5.text = @"";
        [_label5_input setHidden:TRUE];
        
        // Initialize what the text field show.
        NSString* access_key = [PersonalDataController getFileStoreAccessKey:_our_data.file_store];
        if ([access_key length])
            _label2_input.text = access_key;
        
        NSString* secret_key = [PersonalDataController getFileStoreSecretKey:_our_data.file_store];
        if ([secret_key length])
            _label3_input.text = secret_key;
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
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"File Store Configuration" message:@"You must go back and choose a file store!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:done: called.");
    
    // Build our file store dictionary with the data we collected.
    if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
        [PersonalDataController setFileStore:_our_data.file_store accessKey:_label2_input.text];
        [PersonalDataController setFileStore:_our_data.file_store secretKey:_label3_input.text];
        
        // And write it out to disk.
        [_our_data saveFileStoreState];
    } else {
        NSLog(@"FileStoreDataViewController:done: WARN: Unknown file store service!");
    }
    
    // Call our delegate, passing them *just* our file store dictionary.
    [[self delegate] fileStoreDataViewControllerDidFinish:_our_data.file_store];
}

- (IBAction)cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:cancel: called.");
    
    [[self delegate] fileStoreDataViewControllerDidCancel:self];
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
