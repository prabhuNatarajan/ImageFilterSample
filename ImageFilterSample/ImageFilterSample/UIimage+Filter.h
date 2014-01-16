//
//  UIimage+Filter.h
//  ImageFilterSample
//
//  Created by Apple on 16/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

struct FieldPosition
{
    unsigned char one;
    unsigned char two;
    unsigned char three;
    unsigned char four;
};

typedef struct FieldPosition DataField;

struct anRGBA
{
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    unsigned char alpha;
};

typedef struct anRGBA RGBA;

enum EdgeTypes{
    simple = 0,
    sobel = 1,
    canny = 2
};

typedef enum EdgeTypes EdgeType;

static inline DataField DataFieldMake(int first, int second, int third, int fourth)
{
    DataField field;
    field.one = first;
    field.two = second;
    field.three = third;
    field.four = fourth;
    return field;
}

static inline RGBA RGBAMake(int r, int g, int b, int a)
{
    RGBA field;
    field.red = r;
    field.blue = b;
    field.green = g;
    field.alpha = a;
    return field;
}

@interface UIImage (Filter)

- (float) safe:(int) i;
- (UIImage *)duplicate;
- (id)applyFilter:(RGBA (^)(int r, int g, int b, int a))fn;
- (id)applyFilterByStep:(int) step ShiftIn:(DataField)shiftIn ShiftOut:(DataField)shiftOut Callback:(RGBA (^)(int r, int g, int b, int a))fn;
- (id)convolve:(NSArray *)kernal;
- (id)edgeDetection:(EdgeType)edgetype;
- (id)adjustRedChannel:(float)rS GreenChannel:(float)gS BlueChannel:(float) bS;
- (id)brightneddByFactor:(float) t;
- (id)fillRedChannel:(float)rF GreenChannel:(float) gF BlueChannel:(float) bF;
- (id)opacityByFactor:(float) o;
- (id)saturatioByFactor:(float) t;
- (id)thresholdByFactor:(float) t;
- (id)posterizeByLevel:(float) level;
- (id)gammaByValue:(float)value;
- (id)negative;
- (id)greyScale;
- (id)bump;
- (id)tintWithMinRGB:(RGBA)minRGB MaxRGB:(RGBA)maxRGB;
- (id)maskRedChannel:(int)mR GreenChannel:(int)mG BlueChannel:(int)mB;
- (id)sepia;
- (id)biasByFactor:(float)val;
- (id)contrastByFactor:(float)val;
- (id)blur;
- (id)sharpen;
- (id)guassianBlur;

- (id)applyBlend:(UIImage *)topImage CallBack:(RGBA (^)(RGBA top, RGBA bottom))fn;
- (id)multiply:(UIImage *)topImage;
- (id)screeen:(UIImage *)topFltr;
- (id)overlay:(UIImage *)topFltr;
- (id)difference:(UIImage *)topFltr;
- (id)addition:(UIImage *)topFltr;
- (id)exclusion:(UIImage *)topFltr;
- (id)softLight:(UIImage *)topFltr;

- (float) calc_bias:(float)f Bias:(float)bi;
- (float) calc_contrast:(float)f contrast:(float)c;
- (float) calc_overlay:(float)b other:(float)t;
- (float) calc_softlight:(float)b other:(float)t;

@end