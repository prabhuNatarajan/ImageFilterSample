//
//  IFSimageViewController.h
//  ImageFilterSample
//
//  Created by Apple on 17/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IFSimageViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageViewPicture;

- (void)setImage:(UIImage *)img;
- (void)save;

@end
