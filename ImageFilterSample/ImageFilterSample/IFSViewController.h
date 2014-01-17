//
//  IFSViewController.h
//  ImageFilterSample
//
//  Created by Apple on 16/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IFSViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    NSString *fileName;
    NSMutableArray *arrEffects;
    UIImagePickerController *imagePicker;
    UIImage *selectedImage;
    UIImage *thumbImage;
    UIImage *miniThumbImage;
}

@property (strong, nonatomic) IBOutlet UITableView *tableEffects;

@end