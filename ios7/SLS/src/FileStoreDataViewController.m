//
//  FileStoreDataViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/26/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "FileStoreDataViewController.h"

static const int kDebugLevel = 4;

@interface FileStoreDataViewController ()
@end

@implementation FileStoreDataViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize service = _service;

#pragma mark - Local variables
@synthesize file_store_changed = _file_store_changed;

static UITextField* active_field = nil;

#pragma mark - Outlets
@synthesize done_button = _done_button;
@synthesize scroll_view = _scroll_view;
@synthesize picker_view = _picker_view;
@synthesize label1 = _label1;
@synthesize label2 = _label2;
@synthesize label3 = _label3;
@synthesize label4 = _label4;
@synthesize label5 = _label5;
@synthesize label1_input = _label1_input;
@synthesize label2_input = _label2_input;
@synthesize label3_input = _label3_input;
@synthesize label4_input = _label4_input;
@synthesize label5_input = _label5_input;

#pragma mark - Initialization
- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _service = nil;
        _file_store_changed = false;
        _scroll_view = nil;
        _picker_view = nil;
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
        _service = nil;
        _file_store_changed = false;
        _scroll_view = nil;
        _picker_view = nil;
    }
    
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    
    // Register for keyboard events, so we can make sure our UITextFields stay visible.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    [self configureView];  // update the view with correct labels
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:configureView: called.");
    
    // Default interface labels.
    _label1.text = @"";
    [_label1_input setHidden:TRUE];
    _label2.text = @"";
    [_label2_input setHidden:TRUE];
    _label3.text = @"";
    [_label3_input setHidden:TRUE];
    _label4.text = @"";
    [_label4_input setHidden:TRUE];
    _label5.text = @"";
    [_label5_input setHidden:TRUE];

    // Update the user interface based on chosen service.
    if (_our_data.file_store != nil) {
        // Initialize what the picker shows.
        NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
        if (service != nil && [service length] > 0) {
            if (kDebugLevel > 0)
                NSLog(@"FileStoreDataViewController:configureView: file-store service set to %@.", service);
            
            // Look for our current file store in the list.
            NSArray* file_stores = [PersonalDataController supportedFileStores];
            int i;
            for (i = 0; i < [file_stores count]; ++i) {
                if ([[file_stores objectAtIndex:i] caseInsensitiveCompare:service] == NSOrderedSame)
                    break;
            }
            
            // If we found it, set the picker's initial view to our current file store.
            if (i < [file_stores count]) {
                if (kDebugLevel > 0)
                    NSLog(@"FileStoreDataViewController:configureView: setting picker's initial view to item %d.", i);
                
                [_picker_view selectRow:(NSInteger)i inComponent:0 animated:YES];
            }
            NSLog(@"FileStoreDataViewController:configureView: setting file-store: %@.", [PersonalDataController absoluteStringFileStore:_our_data.file_store]);
            
            // Display any additional data, depending on the service ...
            if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
                if (kDebugLevel > 0)
                    NSLog(@"FileStoreDataViewController:configureView: file-store service set to AmazonS3.");
                
                _label1.text = @"Access Key";
                _label2.text = @"Secret Key";
                [_label1_input setHidden:FALSE];
                [_label2_input setHidden:FALSE];
                
                // Initialize what the text field show.
                NSString* access_key = [PersonalDataController getFileStoreAccessKey:_our_data.file_store];
                if ([access_key length])
                    _label1_input.text = access_key;
                
                NSString* secret_key = [PersonalDataController getFileStoreSecretKey:_our_data.file_store];
                if ([secret_key length])
                    _label2_input.text = secret_key;
            }
        }
    }
    
    if (kDebugLevel > 3)
        NSLog(@"FileStoreDataViewController:configureView: exiting.");
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source

// UIPickerView.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)picker_view {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:numberOfComponentsInPickerView: called.");
    
    return 1;
}

- (NSInteger) pickerView:(UIPickerView*)picker_view numberOfRowsInComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:pickerView:numberOfRowsInComponent: called.");
    
    
    NSLog(@"FileStoreDataViewController:pickerView:numberOfRowsInComponent: returning %lu rows.", (unsigned long)[[PersonalDataController supportedFileStores] count]);
    
    return [[PersonalDataController supportedFileStores] count];
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToProviderDataViewID"]) {
        if (kDebugLevel > 2)
            NSLog(@"FileStoreDataViewController:prepareForSeque: unwinding to ProviderDataViewController.");
        
        if (sender != self.done_button) {
            // User hit CANCEL ...
            if (kDebugLevel > 0)
                NSLog(@"FileStoreDataViewController:prepareForSeque: User hit CANCEL (file_store_chanaged: %d).", _file_store_changed);
            
            // Unset any state flags, if they were set.
            if (_file_store_changed)
                _file_store_changed = false;
        } else {
            if (kDebugLevel > 0)
                NSLog(@"FileStoreDataViewController:prepareForSeque: User hit DONE.");
            
            // User hit DONE; install UITextfield objects into our_data if we made any changes ...
            if (_file_store_changed) {
                NSLog(@"FileStoreDataViewController:prepareForSeque: XXX TODO(aka) We need to return information based on scheme!");
                
                if (kDebugLevel > 1)
                    NSLog(@"FileStoreDataViewController:prepareForSeque: Setting secret to %@, key to %@.", _label1_input.text, _label2_input.text);
                [PersonalDataController setFileStore:_our_data.file_store accessKey:_label1_input.text];
                [PersonalDataController setFileStore:_our_data.file_store secretKey:_label2_input.text];
            }
        }
    } else {
        NSLog(@"FileStoreDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Delegate callbacks

// UIPickerView delegate functions.
- (NSString*) pickerView:(UIPickerView*)picker_view titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:pickerView:titleForRow:forComponent: called with row: %ld.", (long)row);
    
    return [[PersonalDataController supportedFileStores] objectAtIndex:row];
}

- (void) pickerView:(UIPickerView*)picker_view didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:pickerView:didSelectRow:inComponent: called.");
    
    // Get the selected service.
    NSString* service = [[PersonalDataController supportedFileStores] objectAtIndex:row];
    [PersonalDataController setFileStore:_our_data.file_store service:service];
    _file_store_changed = true;
    
    [self configureView];
}

// UITextField delegate functions.
- (void) textFieldDidBeginEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldDidBeginEditing: called.");

    active_field = textField;
    
#if 0  // XXX Failed attempt (due to unknown constant) to make text field visible.
	// Move UITextField up to make sure we can still see it when the keyboard is visible.
	[UIView beginAnimations:@"Animate UITextField Up" context:nil];
	[UIView setAnimationDuration:.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
    
	textField.frame = CGRectMake(textField.frame.origin.x,
                                        TEXTFIELD_ACTIVE_Y_POSITION	,
                                        textField.frame.size.width,
                                        textField.frame.size.height);
	[UIView commitAnimations];
#endif
}

- (BOOL) textFieldShouldEndEditing:(UITextField*)textField {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldShouldEndEditing: called.");
    
    NSLog(@"FileStoreDataViewController:textFieldShouldEndEditing: XXX TODO(aka) Need to untaint input based on label & service!");

    if (textField == _label1_input) {
    /*
        NSString *regEx = @"[0-9]{3}-[0-9]{2}-[0-9]{4}";
        NSRange r = [textField.text rangeOfString:regEx options:NSRegularExpressionSearch];
        if (r.location == NSNotFound) {
            UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Entry Error"
                                                          message:@"Enter social security number in 'NNN-NN-NNNN' format"
                                                         delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            [av show];
            return NO;
        }
    */
    }
    
    active_field = nil;
    
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField*)text_field {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:textFieldShouldReturn: called.");
    
    if ((text_field == _label1_input) || (text_field == _label2_input) || (text_field == _label3_input) || (text_field == _label4_input) || (text_field == _label5_input)) {
        _file_store_changed = true;
        [text_field resignFirstResponder];
    }
    
    return YES;
}

// NSNotification (must register for these!)
- (void) keyboardWasShown:(NSNotification*)aNotification {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:keyboardWasShown: called.");
    
    // Code to move our UITextField view above the keyboard, if necessary.  Source taken from <https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html#//apple_ref/doc/uid/TP40009542-CH5-SW1>
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

#if 0 // TODO(aka) This snippet doesn't apprear to be working
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    _scroll_view.contentInset = contentInsets;
    _scroll_view.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, active_field.frame.origin) ) {
        [self.scroll_view scrollRectToVisible:active_field.frame animated:YES];
    }
#else  // TODO(aka) But this version does, hmm ...
    CGRect bkgndRect = active_field.superview.frame;
    bkgndRect.size.height += kbSize.height;
    [active_field.superview setFrame:bkgndRect];
    [_scroll_view setContentOffset:CGPointMake(0.0, active_field.frame.origin.y-kbSize.height) animated:YES];
#endif
}

- (void) keyboardWillBeHidden:(NSNotification*)aNotification {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:keyboardWillBeHidden: called.");
    
    // Called when the UIKeyboardWillHideNotification is sent
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scroll_view.contentInset = contentInsets;
    _scroll_view.scrollIndicatorInsets = contentInsets;
}

@end
