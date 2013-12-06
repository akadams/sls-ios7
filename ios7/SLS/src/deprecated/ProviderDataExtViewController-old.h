//
//  ProviderDataExtViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"
#import "CoreLocationController.h"
#import "SymmetricKeysController.h"


@protocol ProviderDataExtViewControllerDelegate;

@interface ProviderDataExtViewController : UIViewController

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) CoreLocationController* location_controller;
@property (copy, nonatomic) SymmetricKeysController* symmetric_keys;
@property (weak, nonatomic) id <ProviderDataExtViewControllerDelegate> delegate;
@property (nonatomic) BOOL state_change;
@property (nonatomic) BOOL add_self_status;
@property (weak, nonatomic) IBOutlet UILabel* label;
@property (weak, nonatomic) IBOutlet UIButton* toggle_location_sharing_button;
@property (weak, nonatomic) IBOutlet UIButton* toggle_power_saving_button;
@property (weak, nonatomic) IBOutlet UISlider* distance_filter_slider;
@property (weak, nonatomic) IBOutlet UILabel* distance_filter_label;
@property (weak, nonatomic) IBOutlet UIButton* add_self_button;
@property (weak, nonatomic) IBOutlet UIButton* gen_sym_keys_button;
@property (weak, nonatomic) IBOutlet UIButton* gen_pub_keys_button;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) toggleLocationSharing:(id)sender;
- (IBAction) togglePowerSaving:(id)sender;
- (IBAction) distanceFilterChanged:(id)sender;
- (IBAction) addSelfToConsumers:(id)sender;
- (IBAction) genSymmetricKeys:(id)sender;
- (IBAction) genPublicKeys:(id)sender;

@end

@protocol ProviderDataExtViewControllerDelegate <NSObject>
- (void) providerDataExtViewControllerDidFinish:(PersonalDataController*)our_data coreLocationController:(CoreLocationController*)location_controller symmetricKeys:(SymmetricKeysController*)symmetric_keys addSelf:(BOOL)add_self;
- (void) providerDataExtViewControllerDidCancel:(ProviderDataExtViewController*)controller;
@end
