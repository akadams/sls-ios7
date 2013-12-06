//
//  QREncodeKeyDepositViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"


@protocol QREncodeKeyDepositViewControllerDelegate;

@interface QREncodeKeyDepositViewController : UIViewController

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) NSString* identity;
@property (weak, nonatomic) id <QREncodeKeyDepositViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel* image_label;
@property (weak, nonatomic) IBOutlet UIImageView* image_view;
// XXX @property (weak, nonatomic) IBOutlet UIButton* change_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
// XXX - (IBAction) buttonPressed:(id)sender;

@end

@protocol QREncodeKeyDepositViewControllerDelegate <NSObject>
- (void) qrEncodeKeyDepositViewControllerDidFinish;
- (void) qrEncodeKeyDepositViewControllerDidCancel:(QREncodeKeyDepositViewController*)controller;
@end
