//
//  ConsumerCellController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ConsumerCellControllerDelegate;

@interface ConsumerCellController : UITableViewCell

@property (weak, nonatomic) id <ConsumerCellControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel* label;
@property (weak, nonatomic) IBOutlet UISlider* slider;
@property (weak, nonatomic) IBOutlet UIButton* button;

- (IBAction) sliderValueChanged:(id)sender;
- (IBAction)buttonPressed:(id)sender;

@end

@protocol ConsumerCellControllerDelegate <NSObject>
- (void) consumerCellSliderValueChanged:(UISlider*)slider;
- (void) consumerCellButtonPressed:(UIButton*)button;
@end