//
//  IFSViewController.h
//  ImageFilterSample
//
//  Created by Apple on 16/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IFSViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSMutableArray *arrEffects;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIImage *selectedImage;
@property (strong, nonatomic) UIImage *thumbImage;
@property (strong, nonatomic) UIImage *miniThumbImage;

@property (strong, nonatomic) IBOutlet UITableView *tableEffects;

@end