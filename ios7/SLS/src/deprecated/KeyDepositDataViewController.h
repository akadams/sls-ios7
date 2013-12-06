//
//  KeyDepositDataViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/20/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"


@protocol KeyDepositDataViewControllerDelegate;

@interface KeyDepositDataViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) PersonalDataController* our_data;
@property (weak, nonatomic) id <KeyDepositDataViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel* label1;  // title
@property (weak, nonatomic) IBOutlet UILabel* label2;
@property (weak, nonatomic) IBOutlet UILabel* label3;
@property (weak, nonatomic) IBOutlet UILabel* label4;
@property (weak, nonatomic) IBOutlet UILabel* label5;

@property (weak, nonatomic) IBOutlet UITextField* label2_input;
@property (weak, nonatomic) IBOutlet UITextField* label3_input;
@property (weak, nonatomic) IBOutlet UITextField* label4_input;
@property (weak, nonatomic) IBOutlet UITextField* label5_input;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;

@end

@protocol KeyDepositDataViewControllerDelegate <NSObject>
- (void) keyDepositDataViewControllerDidFinish:(NSMutableDictionary*)file_store;
- (void) keyDepositDataViewControllerDidCancel:(KeyDepositDataViewController*)controller;
@end
