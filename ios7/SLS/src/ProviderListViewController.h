//
//  ProviderListViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 12/3/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "ProviderListController.h"


@interface ProviderListViewController : UIViewController

#pragma mark - Inherited data (from ConsumerDataViewController)
@property (copy, nonatomic) ProviderListController* provider_list;

#pragma mark - Local variables
@property (nonatomic) NSInteger current_provider;

#pragma mark - Variables returned via unwind callback
@property (nonatomic) BOOL provider_list_changed;

// Note, unlike ConsumerListData VC, we make all the changes to individual providers in this class, so we only need to inform the ConsumerMaster VC *if* we make any changes to the list!

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UIPickerView* picker_view;
@property (weak, nonatomic) IBOutlet UILabel* identity_hash_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_key_label;
@property (weak, nonatomic) IBOutlet UILabel* symmetric_key_label;
@property (weak, nonatomic) IBOutlet UILabel* file_store_label;
@property (weak, nonatomic) IBOutlet UIButton* focus_button;
@property (weak, nonatomic) IBOutlet UILabel* freq_label;
@property (weak, nonatomic) IBOutlet UISlider* freq_slider;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;

#pragma mark - Actions
- (IBAction) toggleMapFocus:(id)sender;
- (IBAction) freqValueChanged:(id)sender;
- (IBAction) deleteProvider:(id)sender;

@end
