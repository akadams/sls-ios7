//
//  ConsumerDataExtViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

// XXX Deprecated!

#import <UIKit/UIKit.h>

#import "ProviderListDataViewController.h"    // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"


@protocol ConsumerDataExtViewControllerDelegate;

@interface ConsumerDataExtViewController : UIViewController <ProviderListDataViewControllerDelegate>

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) ProviderListController* provider_list_controller;
@property (nonatomic) BOOL fetch_data_toggle;
@property (nonatomic) BOOL add_self_status;  // used to show if we are also a provider
@property (nonatomic) NSInteger picker_row;  // our current selection
@property (weak, nonatomic) id <ConsumerDataExtViewControllerDelegate> delegate;
@property (nonatomic) BOOL state_change;
@property (weak, nonatomic) IBOutlet UIPickerView* picker;
@property (weak, nonatomic) IBOutlet UIButton* toggle_fetch_data_button;
@property (weak, nonatomic) IBOutlet UIButton* gen_pub_keys_button;
@property (weak, nonatomic) IBOutlet UIButton* add_self_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) genPubKeys:(id)sender;
- (IBAction) toggleFetchData:(id)sender;
- (IBAction) addSelfToProviders:(id)sender;

@end

@protocol ConsumerDataExtViewControllerDelegate <NSObject>
- (void) consumerDataExtViewControllerDidFinish:(PersonalDataController*)our_data providerList:(ProviderListController*)provider_list fetchDataToggle:(BOOL)fetch_data_toggle addSelfStatus:(BOOL)add_self_status;
- (void) consumerDataExtViewControllerDidCancel:(ConsumerDataExtViewController*)controller;
@end
