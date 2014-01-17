//
//  UIimage+Scale.m
//  ImageFilterSample
//
//  Created by Apple on 17/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import "UIimage+Scale.h"

@implementation UIImage (scale)

- (UIImage *)scaleToSize:(CGSize)size
{
    //Create a bitmap graphics context, this will also set it as the current context
    UIGraphicsBeginImageContext(size);
    //Draw the scaled image in the currrent context
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    //Create a new image from current context
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    //Pop the current context from the stack
    UIGraphicsEndImageContext();
    //Return our new scaled image
    return scaledImage;
}

- (UIImage *)crop:(CGRect)cropRect
{
    if (self.scale > 1.0)
    {
        cropRect = CGRectMake(cropRect.origin.x * self.scale, cropRect.origin.y * self.scale, cropRect.size.width * self.scale, cropRect.size.height * self. scale);
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage *retImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return retImage;
}

@end