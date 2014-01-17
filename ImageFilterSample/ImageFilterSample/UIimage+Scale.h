//
//  UIimage+Scale.h
//  ImageFilterSample
//
//  Created by Apple on 17/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (scale)

- (UIImage *)scaleToSize:(CGSize)size;
- (UIImage *)crop:(CGRect)cropRect;

@end