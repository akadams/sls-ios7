//
//  FileStoreDataViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/26/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

// TODO(aka) Note, I have no idea how to use the GTLServiceTicket to track the status of a query.

#import "GTMOAuth2ViewControllerTouch.h"

#import "FileStoreDataViewController.h"


static const int kDebugLevel = 1;

// File-store public SLS credentials.
static const char* kGDKeychainTag = "SLS Google Drive";
static const char* kGDSLSID = "882326644134-6a08mcaljnpld6q7kk7atnm2e91h99cd.apps.googleusercontent.com";
static const char* kGDSLSSecret = "Y6vdfLa4Ad7EqX2ZJNfXA9Kd";     // note, this is public, not a secret when referrring to an installed-app

static const char* kFSRootFolderName = PDC_ROOT_FOLDER_NAME;      // root folder to store SLS data in file-store

static const char* kGDriveIDsFilename = "drive-ids.dict";         // filename to store the drive_ids dictionary on local disk
static const char* kGDriveWVLsFilename = "drive-wvls.dict";       // filename to store the drive_wvls dictionary on local disk
static const int kInitialDictionarySize = 5;


@interface FileStoreDataViewController ()
@end

@implementation FileStoreDataViewController

#pragma mark - Inherited data
@synthesize our_data = _our_data;
@synthesize service = _service;

#pragma mark - Local variables
// XXX @synthesize current_state = _current_state;
// XXX @synthesize sls_folder = _sls_folder;
@synthesize file_store_changed = _file_store_changed;

static UITextField* active_field = nil;

#pragma mark - Outlets
@synthesize done_button = _done_button;
@synthesize scroll_view = _scroll_view;
@synthesize picker_view = _picker_view;
@synthesize verify_button = _verify_button;
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

// Possible states to be in.
enum {
    MODE_INITIAL = 0,
    MODE_DRIVE_AUTHORIZED = 1,
    MODE_DRIVE_FOLDER_QUERIED = 2,
    MODE_DRIVE_FOLDER_NOT_FOUND = 3,
    MODE_DRIVE_FOLDER_CREATED = 4,
    MODE_DRIVE_FOLDER_FOUND = 5,
    MODE_DRIVE_FOLDER_NOT_PUBLIC = 6,
    MODE_DRIVE_OPERATIONAL = 7,
};

#pragma mark - Initialization
- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _service = nil;
// XXX        _current_state = MODE_INITIAL;
// XXX        _sls_folder = nil;
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
// XXX        _current_state = MODE_INITIAL;
// XXX        _sls_folder = nil;
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
    
    [self configureView];  // update the view with correct labels (TODO(aka) shouldn't this be in viewDidAppear:?)
}

- (void) viewDidAppear:(BOOL)animated {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:viewDidAppear: called.");
    
    [super viewDidAppear:animated];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:configureView: called.");
    
    // Default interface labels.
    [_verify_button setTitle:@"" forState:UIControlStateNormal];
    [_verify_button setAlpha:0.5];
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
    if (_our_data.file_store == nil)
        _our_data.file_store = [[NSMutableDictionary alloc] initWithCapacity:kInitialDictionarySize];
    
    NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
    if (service == nil || [service length] == 0) {
        // No service chosen yet, so set the picker to its initial value and leave.
        [_picker_view selectRow:(NSInteger)0 inComponent:0 animated:YES];
        return;
    }
    
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:configureView: operating on service %@: %@.", service, [_our_data.file_store description]);
    
    // Initialize what the picker shows.
    
    // Look for our current file store in the list, then set the picker to that ...
    NSArray* file_stores = [PersonalDataController supportedFileStores];
    int i;
    for (i = 0; i < [file_stores count]; ++i) {
        if ([[file_stores objectAtIndex:i] caseInsensitiveCompare:service] == NSOrderedSame)
            break;
    }
    if (i < [file_stores count]) {
        if (kDebugLevel > 5)
            NSLog(@"FileStoreDataViewController:configureView: setting picker's initial view to item %d.", i);
        
        [_picker_view selectRow:(NSInteger)i inComponent:0 animated:YES];
    }
    
    // Display any additional data, depending on the service ...
    if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
        if (kDebugLevel > 2)
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
        
        NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
        
        if ([access_key length] > 0 && [secret_key length] > 0) {
            [_verify_button setTitle:[NSString stringWithFormat:@"Verify %s Credentials", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]] forState:UIControlStateNormal];
            [_verify_button setAlpha:1.0];
        }
    } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
        // Based on existing meta-data and the current state, configure our view.
        // XXX static bool drive_api_querying = false;
        // XXX static GTLDriveFile* sls_folder = nil;
        
        if (kDebugLevel > 1)
            NSLog(@"FileStoreDataViewController:configureView: on Drive enter, _drive: %@, auth: %d, root folder's id: %@, wvl: %@.", _our_data.drive, [_our_data googleDriveIsAuthorized], [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]], [_our_data.drive_wvls objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]]);
        
        /* XXX
         if (drive_api_querying) {
         // Do nothing, because we're waiting on the Google Drive API to return.
         return;
         }
         */
        if (_our_data.drive == nil || ![_our_data googleDriveIsAuthorized]) {
            // Initialize what the text field show.
            _label1.text = @"Client ID";
            _label2.text = @"Client Token";
            [_label1_input setHidden:FALSE];
            [_label2_input setHidden:FALSE];
            NSString* client_id = [PersonalDataController getFileStoreClientID:_our_data.file_store];
            if ([client_id length])
                _label1_input.text = client_id;
            NSString* client_secret = [PersonalDataController getFileStoreClientSecret:_our_data.file_store];
            if ([client_secret length])
                _label2_input.text = client_secret;
            
            NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
            [_verify_button setTitle:[NSString stringWithFormat:@"Verify %s Credentials", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]] forState:UIControlStateNormal];
            [_verify_button setAlpha:1.0];
        } else if ([_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]] == nil) {
            [self googleDriveQueryRootFolder];  // will call googleDriveInsertRootFolder: and googleDriveUpdateRootFolderPermission: if necessary
            _file_store_changed = true;  // drive_ids or drive_wvl can change
        } else if ([_our_data.drive_wvls objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]] == nil) {
            // Do nothing, as we encountered an error in either googleDriveInsertRootFolder: or googleDriveUpdateRootFolderPermission:.
            NSLog(@"FileStoreDataViewController:configureView: ERROR: TODO(aka) SLS folder does not have a WebViewLink!");
        } else if ([[NSString stringWithFormat:@"googleDriveUpdateRootFolderPermission"] isEqual:[_our_data.drive_wvls objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]]]) {
            // We need to query it one more time to get the WebViewLink.
            [self googleDriveQueryRootFolder];
            _file_store_changed = true;   // drive_ids or drive_wvl can change
        } else {
            [_verify_button setTitle:[NSString stringWithFormat:@"%s Operational", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]] forState:UIControlStateNormal];
            [_verify_button setAlpha:0.5];
        }
#if 0  // XXX Deprecated!
        static int _current_state = MODE_INITIAL;
        static GTLDriveFile* _sls_folder = nil;
        
        if (kDebugLevel > 1)
            NSLog(@"FileStoreDataViewController:configureView: on enter, Drive's current state: %d, root folder's id: %@, sls_folder: %@.", _current_state, [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]], _sls_folder);
        
        if (_current_state == MODE_DRIVE_FOLDER_QUERIED) {
            // Do nothing, because we're waiting on the Google Drive API to return.
        } else if (_our_data.drive != nil && [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]] != nil) {
            // Supposedly it exists, if we haven't queried it yet, let's (and check its permissions).
            if (_sls_folder == nil) {
                [self googleDriveQueryRootFolder:_sls_folder];  // calls configureView on closure exit (so we check current_status at that time)
            } else {
                // Depending on what state we are in, present the user with options (or just do stuff!).
                if (_current_state == MODE_DRIVE_OPERATIONAL) {
                    [_verify_button setTitle:[NSString stringWithFormat:@"%s Operational", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]] forState:UIControlStateNormal];
                    [_verify_button setAlpha:0.5];
                } else if (_current_state == MODE_DRIVE_FOLDER_NOT_PUBLIC) {
#if 0  // XXX Instead of prompting user again, let's just call it now!
                    [_verify_button setTitle:[NSString stringWithFormat:@"Operational: Check If Writable"] forState:UIControlStateNormal];
                    [_verify_button setAlpha:1.0];
#endif
                    [self googleDriveUpdateRootFolderPermission:_sls_folder];  // calls configureView on closure exit
                } else {
                    NSLog(@"FileStoreDataViewController:configureView: XXX TODO(aka) Unknown DRIVE_FOLDER_FOUND state reached: %d.", _current_state);
                }
            }
        } else if ([_our_data googleDriveIsAuthorized]) {
            // We've succeeded in authorizing ourselves, see where we are regarding the root folder ...
            if (_current_state == MODE_INITIAL)
                _current_state = MODE_DRIVE_AUTHORIZED;  // we haven't been initialized yet
            
            if (_current_state == MODE_DRIVE_AUTHORIZED) {
#if 0  // XXX Instead of prompting user again, let's just call it now!
                [_verify_button setTitle:[NSString stringWithFormat:@"User Authorized: Check If Operational"] forState:UIControlStateNormal];
                [_verify_button setAlpha:1.0];
#endif
                [self googleDriveQueryRootFolder:_sls_folder];
            } else if (_current_state == MODE_DRIVE_FOLDER_NOT_FOUND) {
#if 0  // XXX Instead of prompting user again, let's just call it now!
                [_verify_button setTitle:[NSString stringWithFormat:@"Operational: Check If Writable"] forState:UIControlStateNormal];
                [_verify_button setAlpha:1.0];
#endif
                [self googleDriveInsertRootFolder:_sls_folder];
            } else if (_current_state == MODE_DRIVE_FOLDER_CREATED) {
                NSLog(@"FileStoreDataViewController:configureView: XXX MODE_DRIVE_FOLDER_CREATED reached, which I don't think will ever happen.");
            } else if (_current_state == MODE_DRIVE_FOLDER_NOT_PUBLIC) {
#if 0  // XXX Instead of prompting user again, let's just call it now!
                [_verify_button setTitle:[NSString stringWithFormat:@"Operational: Check If Writable"] forState:UIControlStateNormal];
                [_verify_button setAlpha:1.0];
#endif
                [self googleDriveUpdateRootFolderPermission:_sls_folder];
            } else {
                NSLog(@"FileStoreDataViewController:configureView: XXX TODO(aka) Unknown DRIVE_AUTHORIZED state reached: %d.", _current_state);
            }
        } else {
            // Initialize what the text field show.
            _label1.text = @"Client ID";
            _label2.text = @"Client Token";
            [_label1_input setHidden:FALSE];
            [_label2_input setHidden:FALSE];
            NSString* client_id = [PersonalDataController getFileStoreClientID:_our_data.file_store];
            if ([client_id length])
                _label1_input.text = client_id;
            NSString* client_secret = [PersonalDataController getFileStoreClientSecret:_our_data.file_store];
            if ([client_secret length])
                _label2_input.text = client_secret;
            
            NSString* service = [PersonalDataController getFileStoreService:_our_data.file_store];
            [_verify_button setTitle:[NSString stringWithFormat:@"Verify %s Credentials", [service cStringUsingEncoding:[NSString defaultCStringEncoding]]] forState:UIControlStateNormal];
            [_verify_button setAlpha:1.0];
        }
        
        if (kDebugLevel > 1)
            NSLog(@"FileStoreDataViewController:configureView: on exit, Drive's current state: %d.", _current_state);
#endif
    }
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
            
            // Nothing to do (as our dictionary should already have been populated with any new user information.
         }
    } else {
        NSLog(@"FileStoreDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Google Drive management

// XXX TODO(aka) If we passed in the [self configureView] as the completion block, we probably could move these to PersonalDataController or wherever!  Actually, I think we can use the ones in PersonalDataController now ...

- (void) googleDriveQueryRootFolder {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:googleDriveQueryRootFolder: called.");
    
    // Query Drive for the root "SLS" folder.
    GTLQueryDrive* search_query = [GTLQueryDrive queryForFilesList];
    search_query.q = [NSString stringWithFormat:@"title = '%s'", kFSRootFolderName];
    
        // XXX _current_state = MODE_DRIVE_FOLDER_QUERIED;  // mark that we're querying in the background
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Querying Google Drive" message:@"Please wait..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"FileStoreDataViewController:googleDriveQueryRootFolder: Attempting folder search query for %s.", kFSRootFolderName);
    
    [_our_data.drive executeQuery:search_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFileList* files, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveQueryRootFolder:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            if ([files.items count] == 0) {
                // Didn't find the file.
                [_our_data.drive_ids removeObjectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];  // just in-case
                
                // Create it.
                [self googleDriveInsertRootFolder];
            } else if ([files.items count] == 1) {
                GTLDriveFile* sls_folder = [files.items objectAtIndex:0];
                [_our_data.drive_ids setObject:sls_folder.identifier forKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
                [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];
                
                if (kDebugLevel > 2) {
                    NSString* msg = [NSString stringWithFormat:@"DEBUG: Root folder exists, checking role (%@), type (%@) and WVL (%@) to see if public!", sls_folder.userPermission.role, sls_folder.userPermission.type, sls_folder.webViewLink];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveQueryRootFolder:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
                
                // See if it's public.
                if (sls_folder.webViewLink != nil) {
                    [_our_data.drive_wvls setObject:sls_folder.webViewLink forKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
                    [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
                    
                    [self configureView];  // all done
                } else {
                    [self googleDriveUpdateRootFolderPermission:sls_folder];  // TODO(aka) This could cause infinite recursion ...
                }
            } else {
                // Argh!  How can we have more than one file called "SLS"!?!
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveQueryRootFolder:" message:@"Query returned more than one folder!" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                [self configureView];
            }
        }
    }];
}

- (void) googleDriveInsertRootFolder {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:googleDriveInsertRootFolder: called.");
    
    // Create the root folder in Drive.
    GTLDriveFile* tmp_sls_folder = [GTLDriveFile object];
    tmp_sls_folder.title = [NSString stringWithFormat:@"%s", kFSRootFolderName];
    tmp_sls_folder.mimeType = @"application/vnd.google-apps.folder";
    
#if 0  // XXX This doesn't seem to work ... dratz!
    // Make sure the folder is a public folder.
    GTLDrivePermission* permissions = [GTLDrivePermission object];
    permissions.role = @"reader";
    permissions.type = @"anyone";
    permissions.value = @"";
    sls_folder.userPermission = permissions;
#endif
    
    GTLQueryDrive* insert_query = [GTLQueryDrive queryForFilesInsertWithObject:tmp_sls_folder uploadParameters:nil];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Creating Folder in Google Drive" message:@"Please wait..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"FileStoreDataViewController:googleDriveInsertRootFolder: Attempting folder insert query of %s.", kFSRootFolderName);
    
    [_our_data.drive executeQuery:insert_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFile* updated_file, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveInsertRootFolder:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            [_our_data.drive_ids setObject:updated_file.identifier forKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
            [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];
            
            // See if it's public.
            if (updated_file.webViewLink != nil) {
                [_our_data.drive_wvls setObject:updated_file.webViewLink forKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
                [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
                
                [self configureView];  // all done
            } else {
                [self googleDriveUpdateRootFolderPermission:updated_file];
            }
        }
    }];
}

- (void) googleDriveUpdateRootFolderPermission:(GTLDriveFile*)sls_folder {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:googleDriveUpdateRootFolderPermission: called.");

    // Test to prevent infinite recusion between googleDriveQueryRootFolder: and us.
    if ([[NSString stringWithFormat:@"googleDriveUpdateRootFolderPermission"] isEqual:[_our_data.drive_wvls objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]]]) {
        NSString* err_msg = [NSString stringWithFormat:@"ERROR: SLS folder update already attempted!"];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveUpdateRootFolderPermission:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    GTLDrivePermission* new_permission = [GTLDrivePermission object];
    new_permission.role = @"reader";
    new_permission.type = @"anyone";
    new_permission.value = nil;
    
    GTLQueryDrive* update_query = [GTLQueryDrive queryForPermissionsInsertWithObject:new_permission fileId:sls_folder.identifier];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Updating Folder in Google Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"FileStoreDataViewController:googleDriveUpdateRootFolderPermission: Attempting permission update query on %@ (%@), current drive_ids: %@.", sls_folder.title, sls_folder.identifier, [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]]);
    
    // TODO(aka) GTLServiceTicket theoretically can be used to track the status of the request, but I can't figure it out.
    [_our_data.drive executeQuery:update_query completionHandler:^(GTLServiceTicket* ticket, GTLDrivePermission* permission, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveUpdateRootFolderPermission:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            // Update worked.
            [_our_data.drive_wvls setObject:[NSString stringWithFormat:@"googleDriveUpdateRootFolderPermission"] forKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
            [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
            
            if (kDebugLevel > 3) {
                NSString* msg = [NSString stringWithFormat:@"DEBUG: Updated permissions on file: %@, id: %@, permission id: %@, drive_ids count: %ld.", sls_folder.title, sls_folder.identifier, sls_folder.userPermission.identifier, (unsigned long)[_our_data.drive_ids count]];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:googleDriveUpdateRootFolderPermission:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            [self configureView];
        }
    }];
}

#pragma mark - Actions

- (IBAction) verifyCredentials:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:verifyCredentials: called.");
    
    NSString* err_msg = nil;
    if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
        // Attempt to authorize with the credentials in our textfields ...
        err_msg = [_our_data amazonS3Auth:_label1_input.text secretKey:_label2_input.text];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:verifyCredentials:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            return;
        }
    } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
        // See if we have the user's credentials in our keychain.
        err_msg = [_our_data googleDriveKeychainAuth:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store]];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:verifyCredentials:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        // If we were unable to get the credentials from the keychain, prompt the user.
        if (![_our_data googleDriveIsAuthorized]) {
            if (kDebugLevel > 0)
                NSLog(@"FileStoreDataViewController:verifyCredentials: credentials not found in keychain, requesting ...");
            
            GTMOAuth2ViewControllerTouch* auth_controller = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:@"https://www.googleapis.com/auth/drive.file" clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store] keychainItemName:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
            [self presentViewController:auth_controller animated:YES completion:nil];
        } else {
            [self configureView];  // we're authorized
            return;
        }
        
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:verifyCredentials:" message:@"Unknown service." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
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
    unsigned int nonce = arc4random();
    
    if (kDebugLevel > 0)
        NSLog(@"FileStoreDataViewController:pickerView:didSelectRow:inComponent: setting files-store to %@, using nonce: %d.", service, nonce);
    
    [PersonalDataController setFileStore:_our_data.file_store nonce:[NSNumber numberWithInt:(int)nonce]];
    
    // Add some additional meta-data based on the service type ...
    if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
        [PersonalDataController setFileStore:_our_data.file_store keychainTag:[NSString stringWithFormat:@"%s", kGDKeychainTag]];
        [PersonalDataController setFileStore:_our_data.file_store clientID:[NSString stringWithFormat:@"%s", kGDSLSID]];
        [PersonalDataController setFileStore:_our_data.file_store clientSecret:[NSString stringWithFormat:@"%s", kGDSLSSecret]];
        
        // And blow away our credentials, if we had them.
        if (_our_data.drive != nil)
            _our_data.drive = nil;  // re-initialize Google Drive
        if (_our_data.drive_ids != nil)
            _our_data.drive_ids = nil;
        if (_our_data.drive_wvls != nil)
            _our_data.drive_wvls = nil;
     }
    
    // Note, I considered zero-ing out the other file-store keys, but it'd be nice if the old keys stuck around incase someone wanted to easily switch between file-stores.

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
        // Add the textfield to our dictionary with the appropriate key based on the service type ...
        if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
            if (kDebugLevel > 1)
                NSLog(@"FileStoreDataViewController:textFieldShouldReturn: Setting either secret or key: %@, %@.", _label1_input.text, _label2_input.text);
            
            if (text_field == _label1_input)
                [PersonalDataController setFileStore:_our_data.file_store accessKey:_label1_input.text];
            else if (text_field == _label2_input)
                [PersonalDataController setFileStore:_our_data.file_store secretKey:_label2_input.text];
        } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
            if (kDebugLevel > 1)
                NSLog(@"FileStoreDataViewController:textFieldShouldReturn: user changed id or secret: %@, %@, but ignoring.", _label1_input.text, _label2_input.text);
            /*
             if (text_field == _label1_input)
             [PersonalDataController setFileStore:_our_data.file_store clientID:_label1_input.text];
             else if (text_field == _label2_input)
             [PersonalDataController setFileStore:_our_data.file_store clientSecret:_label2_input.text];
             */
        }
        _file_store_changed = true;
        [text_field resignFirstResponder];
    }
    
    return YES;
}

// GTMOAuth2ViewControllerTouch delegate functions.
- (void)viewController:(GTMOAuth2ViewControllerTouch*)viewController finishedWithAuth:(GTMOAuth2Authentication*)auth_result error:(NSError*)error {
    if (kDebugLevel > 2)
        NSLog(@"FileStoreDataViewController:viewController:finishedWithAuth: called.");
    
    if (error != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:viewController:finishedWithResult:" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        // Auth successful
        _our_data.drive.authorizer = auth_result;

        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FileStoreDataViewController:viewController:finishedWithResult:" message:@"Authentication Successful, hit DONE" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }

    [self dismissViewControllerAnimated:YES completion:nil];  // remove GTMOAuth2ViewController
    [self configureView];
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
