//
//  IFSimageViewController.m
//  ImageFilterSample
//
//  Created by Apple on 17/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import "IFSimageViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface IFSimageViewController ()

@end

@implementation IFSimageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    CALayer *l = [_imageViewPicture layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:10.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)save:(id)sender
{
    UIImageWriteToSavedPhotosAlbum(_imageViewPicture.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)setImage:(UIImage *)img
{
    _imageViewPicture.frame = CGRectMake((self.view.frame.size.width - img.size.width) / 2, (self.view.frame.size.height - img.size.height) / 2, img.size.width, img.size.height);
    _imageViewPicture.image = img;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error)
    {
        NSLog(@"Unable to save image to photo album %@",error);
    }
    [self.navigationController popViewControllerAnimated:YES];
}
@end
