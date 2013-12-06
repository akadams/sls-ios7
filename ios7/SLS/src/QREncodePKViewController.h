//
//  QREncodePKViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/21/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"


@protocol QREncodePKViewControllerDelegate;

@interface QREncodePKViewController : UIViewController

#pragma mark - Inherited data (from MasterViewController)
@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;  // decoder's identity (currently not used)
@property (weak, nonatomic) id <QREncodePKViewControllerDelegate> delegate;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UILabel* image_label;
@property (weak, nonatomic) IBOutlet UIImageView* image_view;
// XXX @property (weak, nonatomic) IBOutlet UIButton* change_button;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;

@end

@protocol QREncodePKViewControllerDelegate <NSObject>
- (void) qrEncodePKViewControllerDidFinish;
- (void) qrEncodePKViewControllerDidCancel:(QREncodePKViewController*)controller;
@end
