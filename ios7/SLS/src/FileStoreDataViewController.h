//
//  FileStoreDataViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/26/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"
#import "GTLDrive.h"


@interface FileStoreDataViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

#pragma mark - Inherited data (from MasterViewController)
@property (weak, nonatomic) PersonalDataController* our_data;
@property (weak, nonatomic) NSString* service;  // XXX TODO(aka) I think this is deprecated

#pragma mark - Local variables
// XXX @property (nonatomic) int current_state;               // used to handle asynchronus behavior of Google Drive SDK
// XXX @property (weak, nonatomic) GTLDriveFile* sls_folder;  // used to check/set permissions on the folder

#pragma mark - Variables returned via unwind callback
@property (nonatomic) BOOL file_store_changed;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UIScrollView* scroll_view;
@property (weak, nonatomic) IBOutlet UIPickerView* picker_view;
@property (weak, nonatomic) IBOutlet UIButton* verify_button;
@property (weak, nonatomic) IBOutlet UILabel* label1;
@property (weak, nonatomic) IBOutlet UILabel* label2;
@property (weak, nonatomic) IBOutlet UILabel* label3;
@property (weak, nonatomic) IBOutlet UILabel* label4;
@property (weak, nonatomic) IBOutlet UILabel* label5;

@property (weak, nonatomic) IBOutlet UITextField* label1_input;
@property (weak, nonatomic) IBOutlet UITextField* label2_input;
@property (weak, nonatomic) IBOutlet UITextField* label3_input;
@property (weak, nonatomic) IBOutlet UITextField* label4_input;
@property (weak, nonatomic) IBOutlet UITextField* label5_input;


#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Google Drive management
- (void) googleDriveQueryRootFolder;
- (void) googleDriveInsertRootFolder;
- (void) googleDriveUpdateRootFolderPermission:(GTLDriveFile*)sls_folder;

#pragma mark - Actions
- (IBAction) verifyCredentials:(id)sender;

@end
