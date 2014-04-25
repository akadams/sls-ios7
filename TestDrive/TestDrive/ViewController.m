//
//  ViewController.m
//  TestDrive
//
//  Created by Andrew K. Adams on 3/7/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import "ViewController.h"

static NSString *const kKeychainItemName = @"SLS Google Drive";
static NSString *const kClientID = @"882326644134-p1kk6ifg0h51t4u5r4fcm8sc53e7rpum.apps.googleusercontent.com";
static NSString *const kClientSecret = @"EERex5d6RKFncIJlBX6FlbsO";

@implementation ViewController

@synthesize driveService;

- (void)viewDidLoad
{
 NSLog(@"TestDrive:ViewDidLoad: called.");
    [super viewDidLoad];
    
    // Initialize the drive service & load existing credentials from the keychain if available
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:kClientSecret];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"TestDrive:ViewDidAppear: called.");
    
    // Always display the camera UI.
    //[self showCamera];
    
    [self loadDriveFiles];
}

- (void) makeRootFolder {
    NSLog(@"TestDrive:MakeRootFolder: called.");
    
    GTLDriveFile* folder = [GTLDriveFile object];
    folder.title = @"SLS";
    folder.mimeType = @"application/vnd.google-apps.folder";
    
    GTLQueryDrive* query = [GTLQueryDrive queryForFilesInsertWithObject:folder uploadParameters:nil];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket* ticket,
                                                              GTLDriveFile* updatedFile,
                                                              NSError* error) {
        if (error == nil) {
            NSLog(@"Created folder");
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    }];
    
}

- (void) loadDriveFiles {
    NSLog(@"TestDrive:loadDriveFiles: called.");
    
    GTLQueryDrive* query = [GTLQueryDrive queryForFilesList];
    query.q = @"mimeType = 'text/plain'";
    
    UIAlertView *alert =
    [self showLoadingMessageWithTitle:@"Loading files"
                                        delegate:self];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFileList *files,
                                                              NSError *error) {
        [alert dismissWithClickedButtonIndex:0 animated:YES];
        if (error == nil) {
            if (self.driveFiles == nil) {
                self.driveFiles = [[NSMutableArray alloc] init];
            }
            [self.driveFiles removeAllObjects];
            [self.driveFiles addObjectsFromArray:files.items];
            [self.tableView reloadData];
        } else {
            NSLog(@"An error occurred: %@", error);
            [self showErrorMessageWithTitle:@"Unable to load files"
                                               message:[error description]
                                              delegate:self];
        }
    }];
}

- (void) loadFileContent:(GTLDriveFile*)file {
    UIAlertView* alert = [self showLoadingMessageWithTitle:@"Loading file content" delegate:self];
    GTMHTTPFetcher* fetcher = [self.driveService.fetcherService fetcherWithURLString:file.downloadUrl];
    
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        [alert dismissWithClickedButtonIndex:0 animated:YES];
        if (error == nil) {
            NSString* fileContent = [[NSString alloc] initWithData:data
                                                          encoding:NSUTF8StringEncoding];
            //self.textView.text = fileContent;
            //self.originalContent = [fileContent copy];
        } else {
            NSLog(@"An error occurred: %@", error);
            [self showErrorMessageWithTitle:@"Unable to load file"
                                               message:[error description]
                                              delegate:self];
        }
    }];
}

- (void) insertPermissionWithService:(GTLServiceDrive*)service
                             fileId:(NSString*)fileId
                              value:(NSString*)value
                               type:(NSString*)type
                               role:(NSString*)role
                    completionBlock:(void (^)(GTLDrivePermission* , NSError *))completionBlock {
    GTLDrivePermission *newPermission = [GTLDrivePermission object];
    // User or group e-mail address, domain name or nil for @"default" type.
    newPermission.value = value;
    // The value @"user", @"group", @"domain" or @"default".
    newPermission.type = type;
    // The value @"owner", @"writer" or @"reader".
    newPermission.role = role;
    
    GTLQueryDrive *query = [GTLQueryDrive queryForPermissionsInsertWithObject:newPermission fileId:fileId];
    // queryTicket can be used to track the status of the request.
    GTLServiceTicket* queryTicket = [service executeQuery:query
        completionHandler:^(GTLServiceTicket* ticket, GTLDrivePermission* permission, NSError* error) {
            if (error == nil) {
                completionBlock(permission, nil);
            } else {
                NSLog(@"An error occurred: %@", error);
                completionBlock(nil, error);
            }
        }];
}

- (void)showCamera
{
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else
    {
        // In case we're running the iPhone simulator, fall back on the photo library instead.
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            [self showAlert:@"Error" message:@"Sorry, iPad Simulator not supported!"];
            return;
        }
    };
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = self;
    [self presentModalViewController:cameraUI animated:YES];
    
    if (![self isAuthorized])
    {
        // Not yet authorized, request authorization and push the login UI onto the navigation stack.
        [cameraUI pushViewController:[self createAuthController] animated:YES];
    }
}

// Handle selection of an image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self dismissModalViewControllerAnimated:YES];
    [self uploadPhoto:image];
}

// Handle cancel from image picker/camera.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

// Helper to check if user is authorized
- (BOOL) isAuthorized
{
    return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
}

// Creates the auth controller for authorizing access to Google Drive.
- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Handle completion of the authorization process, and updates the Drive service
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error
{
    if (error != nil)
    {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.driveService.authorizer = nil;
    }
    else
    {
        self.driveService.authorizer = authResult;
    }
}

// Uploads a photo to Google Drive
- (void)uploadPhoto:(UIImage*)image
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"'Quickstart Uploaded File ('EEEE MMMM d, YYYY h:mm a, zzz')"];
    
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = [dateFormat stringFromDate:[NSDate date]];
    file.descriptionProperty = @"Uploaded from the Google Drive iOS Quickstart";
    file.mimeType = @"image/png";
    
    NSData *data = UIImagePNGRepresentation((UIImage *)image);
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];
    
    UIAlertView *waitIndicator = [self showWaitIndicator:@"Uploading to Google Drive"];
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *insertedFile, NSError *error) {
                      [waitIndicator dismissWithClickedButtonIndex:0 animated:YES];
                      if (error == nil)
                      {
                          NSLog(@"File ID: %@", insertedFile.identifier);
                          [self showAlert:@"Google Drive" message:@"File saved!"];
                      }
                      else
                      {
                          NSLog(@"An error occurred: %@", error);
                          [self showAlert:@"Google Drive" message:@"Sorry, an error occurred!"];
                      }
                  }];
}

/*
- (void) viewController:(GTMOAuth2ViewControllerTouch*)viewController finishedWithAuth:(GTMOAuth2Authentication*)auth error:(NSError *)error {
    [self dismissModalViewControllerAnimated:YES];
    if (error == nil) {
        [self isAuthorizedWithAuthentication:auth];
    }
}
*/

// Helper for showing a wait indicator in a popup
- (UIAlertView*) showWaitIndicator:(NSString *)title
{
    UIAlertView *progressAlert;
    progressAlert = [[UIAlertView alloc] initWithTitle:title
                                               message:@"Please wait..."
                                              delegate:nil
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil];
    [progressAlert show];
    
    UIActivityIndicatorView *activityView;
    activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.center = CGPointMake(progressAlert.bounds.size.width / 2,
                                      progressAlert.bounds.size.height - 45);
    
    [progressAlert addSubview:activityView];
    [activityView startAnimating];
    return progressAlert;
}

- (UIAlertView*) showLoadingMessageWithTitle:(NSString*)title delegate:(id)delegate {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    UIActivityIndicatorView* progress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 50, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [alert addSubview:progress];
    [progress startAnimating];
    [alert show];
    return alert;
}

- (void) showErrorMessageWithTitle:(NSString*)title message:(NSString*)message delegate:(id)delegate {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Dismiss"
                                          otherButtonTitles:nil];
    [alert show];
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
}

@end