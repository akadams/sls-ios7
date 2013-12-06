//
//  ConsumerCellController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 7/27/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "ConsumerCellController.h"


static const int kDebugLevel = 1;

@implementation ConsumerCellController

@synthesize delegate = _delegate;
@synthesize label = _label;
@synthesize slider = _slider;
@synthesize button = _button;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuse_identifier {
    self = [super initWithStyle:style reuseIdentifier:reuse_identifier];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction) sliderValueChanged:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerCellController:sliderValueChanged: called.");
    
    UISlider* slider = (UISlider*)sender;

    if (kDebugLevel > 0)
        NSLog(@"ConsumerCellController:sliderValueChanged: slider's tag = %ld, value = %f", (long)slider.tag, slider.value);
    
    [[self delegate] consumerCellSliderValueChanged:slider];
}

- (IBAction)buttonPressed:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerCellController:buttonPressed: called.");
    
    UIButton* button = (UIButton*)sender;
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerCellController:buttonPressed: button's tag = %ld.", (long)button.tag);
    
    [[self delegate] consumerCellButtonPressed:button];
}

@end
