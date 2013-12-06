//
//  ConsumerListDataViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/15/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "Consumer.h"


@protocol ConsumerListDataViewControllerDelegate;

@interface ConsumerListDataViewController : UIViewController

@property (copy, nonatomic) Consumer* consumer;
@property (weak, nonatomic) id <ConsumerListDataViewControllerDelegate> delegate;
@property (nonatomic) BOOL send_key;
@property (nonatomic) BOOL state_change;  // TODO(aka) not used, since state does not get changed
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* key_deposit_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_key_label;
@property (weak, nonatomic) IBOutlet UISlider* precision_slider;
@property (weak, nonatomic) IBOutlet UILabel* precision_label;
@property (weak, nonatomic) IBOutlet UIButton* send_key_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) precisionValueChanged:(id)sender;
- (IBAction) sendSymmetricKey:(id)sender;
- (IBAction) deleteConsumer:(id)sender;

@end

@protocol ConsumerListDataViewControllerDelegate <NSObject>
- (void) consumerListDataViewControllerDidFinish:(Consumer*)consumer sendKey:(BOOL)send_key;
- (void) consumerListDataViewControllerDidCancel:(ConsumerListDataViewController*)controller;
- (void) consumerListDataViewControllerDidDelete:(Consumer*)consumer;
@end
