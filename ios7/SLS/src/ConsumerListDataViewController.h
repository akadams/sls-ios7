//
//  ConsumerListDataViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 12/5/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "Principal.h"


@interface ConsumerListDataViewController : UITableViewController

#pragma mark - Inherited data (from ProviderMaster VC)
@property (copy, nonatomic) Principal* consumer;

#pragma mark - Local variables

#pragma mark - Variables returned via callback
@property (nonatomic) BOOL precision_changed;
@property (nonatomic) BOOL track_consumer;
@property (nonatomic) BOOL delete_principal;

#pragma mark - Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem* done_button;
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* token_label;
@property (weak, nonatomic) IBOutlet UILabel* deposit_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_key_label;
@property (weak, nonatomic) IBOutlet UISlider* precision_slider;
@property (weak, nonatomic) IBOutlet UILabel* precision_label;
@property (weak, nonatomic) IBOutlet UIButton* send_file_store_button;
@property (weak, nonatomic) IBOutlet UIButton* track_consumer_button;
@property (weak, nonatomic) IBOutlet UIButton* delete_button;

#pragma mark - Initialiation

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (id) initWithStyle:(UITableViewStyle)style;

#pragma mark - Actions

- (IBAction) precisionValueChanged:(id)sender;
- (IBAction) sendFileStore:(id)sender;
- (IBAction) makeConsumerAProvider:(id)sender;
- (IBAction) deletePrincipal:(id)sender;

@end
