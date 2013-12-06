//
//  ProviderListDataViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 8/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "Provider.h"


@protocol ProviderListDataViewControllerDelegate;

@interface ProviderListDataViewController : UIViewController

@property (copy, nonatomic) Provider* provider;
@property (weak, nonatomic) id <ProviderListDataViewControllerDelegate> delegate;
@property (nonatomic) BOOL state_change;  // TODO(aka) not used, since state does not get changed
@property (weak, nonatomic) IBOutlet UILabel* identity_label;
@property (weak, nonatomic) IBOutlet UILabel* file_store_label;
@property (weak, nonatomic) IBOutlet UILabel* pub_key_label;
@property (weak, nonatomic) IBOutlet UILabel* symmetric_key_label;
@property (weak, nonatomic) IBOutlet UIButton* focus_button;
@property (weak, nonatomic) IBOutlet UISlider* freq_slider;
@property (weak, nonatomic) IBOutlet UILabel* freq_label;

- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) makeProviderFocus:(id)sender;
- (IBAction) freqValueChanged:(id)sender;
- (IBAction) deleteProvider:(id)sender;

@end

@protocol ProviderListDataViewControllerDelegate <NSObject>
- (void) providerListDataViewControllerDidFinish:(Provider*)provider;
- (void) providerListDataViewControllerDidCancel:(ProviderListDataViewController*)controller;
- (void) providerListDataViewControllerDidDelete:(Provider*)provider;
@end
