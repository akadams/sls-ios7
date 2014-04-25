//
//  ViewController.h
//  TestDrive
//
//  Created by Andrew K. Adams on 3/7/14.
//  Copyright (c) 2014 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

@interface ViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, retain) GTLServiceDrive* driveService;
@property (nonatomic, copy) NSMutableArray* driveFiles;

@end
