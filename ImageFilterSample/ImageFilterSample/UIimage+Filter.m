//
//  UIimage+Filter.m
//  ImageFilterSample
//
//  Created by Apple on 16/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import "UIimage+Filter.h"

@interface UIImage ()

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef)imageRef;
- (UIImage *) createImageFromContext:(CGContextRef) cgctx WithSize:(CGSize)size;
- (UIImage *) createImageFromPixels:(unsigned char*)outData Length:(NSUInteger)length;
- (unsigned char *)convolveRaw:(NSArray *)kernal InData:(unsigned char *)inData OuData:(unsigned char *)outData Height:(uint)_height Width:(uint)_width;

@end

@implementation UIImage (Filter)

#pragma mark Helper
- (UIImage *)duplicate
{
    //Get the Core Graphics Reference to the image
    CGImageRef cgImage = [self CGImage];
    //Make a new image from the CGReference
    return [[UIImage alloc]initWithCGImage:cgImage];
}

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef)imageRef
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void *bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    //Get image width, height, We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(imageRef);
    size_t pixelHigh = CGImageGetHeight(imageRef);
    //Declare the number of bytes per row. Each pixel in the bitmap in this example is represented by 4 bytes; 8 bits each of red, green, blue and alpha.
    bitmapBytesPerRow = (pixelsWide *4);
    bitmapByteCount = (bitmapBytesPerRow * pixelHigh);
    //Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space \n");
        return NULL;
    }
    //Allocate the memory for image data, this is the destination in memory
    //Where any drawing to the bitmap context will be rendered
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL)
    {
        fprintf(stderr, "Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    //Create the bitmap context, we want pre-multiplied ARGB, 8-bits per component. regardless of what the source image format is (CMYK, GrayScale and so on) it will be converted over to the format specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free(bitmapData);
        fprintf(stderr, "contex not created!");
    }
    CGRect rect = {{0,0},{pixelsWide, pixelHigh}};
    //Draw the image to bitmap context, once we draw, the memory allocated for the context for rendering will then contain the raw image data in the specified color space.
    CGContextDrawImage(context, rect, self.CGImage);
    //release the colorSpace before returning
    CGColorSpaceRelease(colorSpace);
    return context;
}

- (UIImage *)createImageFromContext:(CGContextRef)cgctx WithSize:(CGSize)size
{
    if (cgctx == NULL)
        //error creating context
        return nil;
    CGContextScaleCTM(cgctx, 1, -1);
    CGContextTranslateCTM(cgctx, 0, -size.height);
    CGImageRef img = CGBitmapContextCreateImage(cgctx);
    UIImage *ui_img = [UIImage imageWithCGImage:img];
    CGImageRelease(img);
    CGContextRelease(cgctx);
    return ui_img;
}

- (UIImage *) createImageFromPixels:(unsigned char *)outData Length:(NSUInteger)length
{
    //Create a new image from the modified pixel data
    size_t width = CGImageGetWidth(self.CGImage);
    size_t height = CGImageGetHeight(self.CGImage);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(self.CGImage);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(self.CGImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(self.CGImage);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.CGImage);
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, outData, length, NULL);
    CGImageRef newImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
    //modified image
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    //cleanup
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    CGImageRelease(newImageRef);
    
    return newImage;
}

- (float)safe:(int)i
{
    return MIN(255, MAX(0, i));
}

- (id)applyFilter:(RGBA (^)(int, int, int, int))fn
{
    return [self applyFilterByStep:4 ShiftIn:DataFieldMake(1, 2, 3, 0) ShiftOut:DataFieldMake(0, 1, 2, 3) Callback:fn];
}

- (id)applyFilterByStep:(int)step ShiftIn:(DataField)shiftIn ShiftOut:(DataField)shiftOut Callback:(RGBA (^)(int, int, int, int))fn
{
    int i = 0;
    step = (step == 0) ? 4 : step;
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:self.CGImage];
    size_t _width = CGImageGetWidth(self.CGImage);
    size_t _height = CGImageGetHeight(self.CGImage);
    unsigned char *data = CGBitmapContextGetData(cgctx);
    if (data != NULL)
    {
        int max = _width * _height * 4;
        for (i = 0; i <max; i += step)
        {
            RGBA newColors;
            newColors = fn(data[i + shiftIn.one], data[i + shiftIn.two], data[i + shiftIn.three], data[i + shiftIn.four]);
            data[i + shiftOut.one] = newColors.alpha;
            data[i + shiftOut.two] = newColors.red;
            data[i + shiftOut.three] = newColors.green;
            data[i + shiftOut.four] = newColors.blue;
        }
    }
    UIImage *img = [self createImageFromContext:cgctx WithSize:CGSizeMake(_width, _height)];
    if (data)
    {
        free(data);
    }
    return img;
}

- (unsigned char *)convolveRaw:(NSArray *)kernal InData:(unsigned char *)inData OuData:(unsigned char *)outData Height:(uint)_height Width:(uint)_width
{
    int kh = kernal.count/2;
    int kw = [(NSArray *)[kernal objectAtIndex:0]count]/2;
    int i = 0;
    int j = 0;
    int n = 0;
    int m = 0;
    for (i = 0; i < _height; i++)
    {
        for (j = 0; j < _width; j++)
        {
            int outIndex = (i * _width * 4) + (j * 4);
            int r = 0;
            int g = 0;
            int b = 0;
            for (n = -kh; n <= kh; n++)
            {
                for (m = -kw; m <= kw; m++)
                {
                    if (i + n >= 0 && i + n <_height)
                    {
                        if (j + m >= 0 && j + m <_width)
                        {
                            float f = [[[kernal objectAtIndex:n+kh]objectAtIndex:m+kw]floatValue];
                            if (f == 0)
                            {
                                continue;
                            }
                            int inIndex = ((i+n) * _width * 4) + ((j+m) * 4);
                            r += inData[inIndex] * f;
                            g += inData[inIndex + 1] * f;
                            b += inData[inIndex + 2] * f;
                        }
                    }
                }
            }
            outData[outIndex] = [self safe:r];
            outData[outIndex + 1] = [self safe:g];
            outData[outIndex + 2] = [self safe:b];
            outData[outIndex + 3] = 255;
        }
    }
    return outData;
}

- (id)convolve:(NSArray *)kernal
{
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:self.CGImage];
    size_t _width = CGImageGetWidth(self.CGImage);
    size_t _height = CGImageGetHeight(self.CGImage);
    unsigned char *inData = CGBitmapContextGetData(cgctx);
    NSData *pixelData = (__bridge NSData *)CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
    NSMutableData *mutablePixelData = [pixelData mutableCopy];
    unsigned char* outData = (unsigned char*)[mutablePixelData mutableBytes];
    outData = [self convolveRaw:kernal InData:inData OuData:outData Height:_height Width:_width];
    UIImage *newImage = [self createImageFromPixels:outData Length:pixelData.length];
    if (outData) free(inData);
    return newImage;
}

- (id)edgeDetection:(EdgeType)edgetype
{
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:self.CGImage];
    size_t _width = CGImageGetWidth(self.CGImage);
    size_t _height = CGImageGetHeight(self.CGImage);
    unsigned char *inData = CGBitmapContextGetData(cgctx);
    NSData *pixelData = (__bridge NSData *) CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
    unsigned char *outData = (unsigned char *)[pixelData bytes];
    int i = 0;
    int j = 0;
    int index = 0;
    switch (edgetype)
    {
        case simple:
        {
            for (i = 0; j < _height; i++)
            {
                for (j = 0; j < _width; j++)
                {
                    index = (i * _width * 4) + (j * 4);
                    int leftIndex = (i * _width * 4) + ((j - 1) * 4);
                    outData[index] = [self safe:abs(inData[index] - inData[leftIndex])];
                    outData[index + 1] = [self safe:abs(inData[index + 1] - inData[leftIndex + 1])];
                    outData[index + 2] = [self safe:abs(inData[index + 2] - inData[leftIndex + 2])];
                    outData[index + 3] = 255;
                }
            }
            inData = outData;
        }
            break;
        case sobel:
        {
            NSArray *kernal = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-1.0],[NSNumber numberWithFloat:-2.0], [NSNumber numberWithFloat:-1.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:1.0],nil], nil];
            unsigned char *gH = [self convolveRaw:kernal InData:inData OuData:outData Height:_height Width:_width];
            NSArray *kernel2 = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-1.0],[NSNumber numberWithFloat:-2.0],[NSNumber numberWithFloat:-1.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:2.0],[NSNumber numberWithFloat:1.0], nil], nil];
            unsigned char *gV = [self convolveRaw:kernel2 InData:inData OuData:outData Height:_height Width:_width];
            for (i = 0; i < _height; i++)
            {
                for (j = 0; j < _width; j++)
                {
                    index = (i * _width * 4) + (j * 4);
                    float rH = gH[index];
                    float rV = gH[index];
                    float grH = gH[index + 1];
                    float grV = gV[index + 1];
                    float bH = gH[index + 2];
                    float bV = gV[index + 2];
                    inData[index] = sqrt(rH * rH + rV * rV);
                    inData[index + 1] = sqrt(grH * grH + grV * grV);
                    inData[index + 2] = sqrt(bH * bH + bV *bV);
                }
            }
        }
            break;
        case canny:
            NSLog(@"edgeDetectction(canny) not implemented yet! ");
            break;
        default:
            break;
    }
    UIImage *newImage = [self createImageFromPixels:outData Length:pixelData.length];
    if(outData) free(outData);
    if (inData) free(inData);
    return newImage;
}

- (id)adjustRedChannel:(float)rS GreenChannel:(float)gS BlueChannel:(float)bS
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:r * (1 + rS)];
        retVal.green = [self safe:g * (1 + gS)];
        retVal.blue = [self safe:b * (1 + bS)];
        retVal.alpha = a;
        return retVal;
    }];
}

- (id)brightnessByFactor:(float)t
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:r + t];
        retVal.green = [self safe:g + t];
        retVal.blue = [self safe:b + t];
        retVal.alpha = a;
        return retVal;
    }];
}

- (id)fillRedChannel:(float)rF GreenChannel:(float)gF BlueChannel:(float)bF
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:rF];
        retVal.green = [self safe:gF];
        retVal.blue = [self safe:bF];
        retVal.alpha = a;
        return retVal;
    }];
}

//Multiply the opacity by givrn Factor @param o the factor to multiply the opacity by.
- (id)opacityByFactor:(float)o
{
    return [self applyFilter:^RGBA(int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = r;
        retVal.green = g;
        retVal.blue = b;
        retVal.alpha = [self safe:o * a];
        return retVal;
    }];
}

//Adjust the saturation by a given factor @param the factor to adjust the saturation
- (id)saturatioByFactor:(float)t
{
    return [self applyFilter:^RGBA(int r, int g, int b, int a){
        RGBA retVal;
        float avg = (r + g + b) / 3.0;
        retVal.red = [self safe:avg + t * (r - avg)];
        retVal.green = [self safe:avg + t * (g - avg)];
        retVal.blue = [self safe:avg + t * (b - avg)];
        retVal.alpha = a;
        return retVal;
    }];
}

//Uses a threshold number on each channel - intensities below the threshold are turned black and intensities above are turned white, @param t the threshold.
- (id)thresholdByFactor:(float)t
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        int c = 255;
        if (r < t || g < t || b < t)
        {
            c = 0;
        }
        retVal.red = c;
        retVal.green = c;
        retVal.blue = c;
        retVal.alpha = a;
        return retVal;
    }];
}

//Quantizes the colors in the image like a posteriation effect, @param levels the levels of quantization.
- (id)posterizeByLevel:(float)level
{
    float step = floorf(255.0 / level);
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:floorf(r / step) * step];
        retVal.green = [self safe:floorf(g / step) * step];
        retVal.blue = [self safe:floorf(b / step) *step];
        retVal.alpha = a;
        return retVal;
    }];
}

//changes the gamma of the image, @param value the gamma value.
- (id)gammaByValue:(float)value
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:powf(r, value)];
        retVal.green = [self safe:powf(g, value)];
        retVal.blue = [self safe:powf(b, value)];
        retVal.alpha = a;
        return retVal;
    }];
}

//Invert the color's on the image
- (id) negative
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:255.0 - r];
        retVal.green = [self safe:255.0 - g];
        retVal.blue = [self safe:255.0 - b];
        retVal.alpha = a;
        return retVal;
    }];
}

//Creates a greyScale version of the image.
- (id)greyScale
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        float avg = (r + g + b) / 3.0;
        retVal.red = [self safe:avg];
        retVal.green = [self safe:avg];
        retVal.blue = [self safe:avg];
        retVal.alpha = a;
        return retVal;
    }];
}

//Embosses the edge of the image
- (id)bump
{
    NSArray *kernal = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:-1.0],[NSNumber numberWithFloat:-1.0], [NSNumber numberWithFloat:0.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:-1.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:-1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0], nil],nil];
    return [self convolve:kernal];
}

//Interpolates between the given RGB values, changes the tint of the image, @param maxRGB the maximum RGB values, @param minRGB the minimum RGB values.
- (id)tintWithMinRGB:(RGBA)minRGB MaxRGB:(RGBA)maxRGB
{
    return [self applyFilter:^RGBA(int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:(r - minRGB.red) * (255.0 / (maxRGB.red - minRGB.red))];
        retVal.green = [self safe:(g- minRGB.green) * (255.0 / (maxRGB.green - minRGB.green))];
        retVal.blue = [self safe:(b - minRGB.blue) * (255.0 / (maxRGB.blue - minRGB.blue))];
        return retVal;
    }];
}

//Applies an mask on each channel, @param mR Red channel mask, @param mG Green channel mask, @param mB Blue channel mask.
- (id)maskRedChannel:(int)mR GreenChannel:(int)mG BlueChannel:(int)mB
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:(r & mR)];
        retVal.green = [self safe:(g & mG)];
        retVal.blue = [self safe:(b & mB)];
        retVal.alpha = a;
        return retVal;
    }];
}

//Applies a sepia filter
- (id)sepia
{
    return [self applyFilter:^RGBA (int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:(r * 0.393) + (g * 0.769) + (b * 0.189)];
        retVal.green = [self safe:(r * 0.349) + (g * 0.686) + (b * 0.168)];
        retVal.blue = [self safe:(r * 0.272) + (g * 0.534) + (b * 0.131)];
        retVal.alpha = a;
        return retVal;
    }];
}

//Make the colorm lighter or darker by a given factor, @param t the factor to adjust the bias by.
- (float)calc_bias:(float)f Bias:(float)bi
{
    return f / ((1.0 / bi - 1.9) * (0.9 - f) + 1.0);
}
- (id)biasByFactor:(float)val
{
    return [self applyFilter:^RGBA(int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:(r * [self calc_bias:r / 255.0 Bias:val])];
        retVal.green = [self safe:(g * [self calc_bias:g / 255.0 Bias:val])];
        retVal.blue = [self safe:(b * [self calc_bias:b / 255.0 Bias:val])];
        retVal.alpha = a;
        return retVal;
    }];
}

//Adjust the contrast by a given factor, @param t hte factor to adjust the contrast by.
- (float)calc_contrast:(float)f contrast:(float)c
{
    return (f - 0.5) * c + 0.5;
}

- (id)contrastByFactor:(float)val
{
    return [self applyFilter:^RGBA(int r, int g, int b, int a){
        RGBA retVal;
        retVal.red = [self safe:(255.0 * [self calc_contrast:(r / 255.0) contrast:val])];
        retVal.green = [self safe:(255.0 * [self calc_contrast:(g / 255.0) contrast:val])];
        retVal.blue = [self safe:(255.0 * [self calc_contrast:(b / 255.0) contrast:val])];
        retVal.alpha = a;
        return retVal;
    }];
}

//A simple convolution blur
- (id)blur
{
    NSArray *kernal = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:1.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:2.0], nil], [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:2.0], [NSNumber numberWithFloat:1.0], nil], nil];
    return [self convolve:kernal];
}

//Convolution Sharpening

- (id)sharpen
{
    NSArray *kernal = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:-0.2], [NSNumber numberWithFloat:1.0], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:-0.2], [NSNumber numberWithFloat:1.8], [NSNumber numberWithFloat:-0.2], nil], [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:-0.2], [NSNumber numberWithFloat:0], nil], nil];
    return [self convolve:kernal];
}

//Guasian blur with a 5*5 convolution kernal.
- (id)guassianBlur
{
    NSArray *kernal = [NSArray arrayWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:1/273], [NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:7/273], [NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:1/273], nil],[NSArray arrayWithObjects:[NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:16/273], [NSNumber numberWithFloat:26/273], [NSNumber numberWithFloat:16/273], [NSNumber numberWithFloat:4/273], nil], [NSArray arrayWithObjects:[NSNumber numberWithFloat:7/273], [NSNumber numberWithFloat:26/273], [NSNumber numberWithFloat:41/273], [NSNumber numberWithFloat:26/273], [NSNumber numberWithFloat:7/273], nil], [NSArray arrayWithObjects:[NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:16/273], [NSNumber numberWithFloat:26/273], [NSNumber numberWithFloat:16/273], [NSNumber numberWithFloat:4/273], nil], [NSArray arrayWithObjects:[NSNumber numberWithFloat:1/273], [NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:7/273], [NSNumber numberWithFloat:4/273], [NSNumber numberWithFloat:1/273], nil], nil];
    return [self convolve:kernal];
}

#pragma mark ~ Bled
- (id)applyBlend:(UIImage *)topImage CallBack:(RGBA (^)(RGBA, RGBA))fn
{
    CGContextRef topCGctx = [topImage createARGBBitmapContextFromImage:topImage.CGImage];
    unsigned char *blendData = CGBitmapContextGetData(topCGctx);
    CGContextRef bottomCGctx = [self createARGBBitmapContextFromImage:self.CGImage];
    unsigned char *imageData = CGBitmapContextGetData(bottomCGctx);
    size_t _width = CGImageGetWidth(self.CGImage);
    size_t _height = CGImageGetHeight(self.CGImage);
    int i = 0;
    int j = 0;
    for (i = 0; i < _height; i++)
    {
        for (j = 0; j < _width; j++)
        {
            int index = (i * _width * 4) + (j * 4);
            RGBA top;
            top.red = blendData[index];
            top.green = blendData[index + 1];
            top.blue = blendData[index + 2];
            top.alpha = blendData[index + 3];
            
            RGBA bottom;
            bottom.red = imageData[index];
            bottom.green = imageData[index + 1];
            bottom.blue = imageData[index + 2];
            bottom.alpha = imageData[index + 3];
            
            RGBA retVal = fn(top, bottom);
            imageData[index] = retVal.red;
            imageData[index + 1] = retVal.green;
            imageData[index + 2] = retVal.blue;
            imageData[index + 3] = retVal.alpha;
        }
    }
    UIImage *newImage = [self createImageFromContext:bottomCGctx WithSize:CGSizeMake(_width, _height)];
    if (blendData) free(blendData);
    return newImage;
}

//Multiply blend mode.
- (id)multiply:(UIImage *)topImage
{
    return [self applyBlend:topImage CallBack:^RGBA(RGBA top, RGBA bottom){
        RGBA retVal;
        retVal.red = [self safe:(top.red * bottom.red) / 255.0];
        retVal.green = [self safe:(top.green * bottom.green) / 255.0];
        retVal.blue = [self safe:(top.blue * bottom.blue) / 255.0];
        retVal.alpha = bottom.alpha;
        return retVal;
    }];
}

- (id)screeen:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2){
        RGBA retVal;
        retVal.red = [self safe:255.0 - ((((255.0 - param1.red) * (255.0 - param2.red)) / 255.0))];
        retVal.green = [self safe:255.0 - ((((255.0 - param1.green) * (255.0 - param2.green)) / 255.0))];
        retVal.blue = [self safe:255.0 - ((((255.0 - param1.blue) * (255.0 - param2.blue)) / 255.0))];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

- (float)calc_overlay:(float)b other:(float) t
{
    return (b > 128.0) ? 255.0 - 2.0 * (255.0 - t) * (255.0 - b) / 255.0: (b * t * 2.0) / 255.0;
}

- (id)overlay:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2) {
        RGBA retVal;
        retVal.red = [self safe:[self calc_overlay: param2.red other:param1.red]];
        retVal.green = [self safe:[self calc_overlay: param2.green other:param1.green]];
        retVal.blue = [self safe:[self calc_overlay: param2.blue other:param1.blue]];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

- (id)difference:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2) {
        RGBA retVal;
        retVal.red = [self safe:abs(param1.red - param2.red)];
        retVal.green = [self safe:abs(param1.green - param2.green)];
        retVal.blue = [self safe:abs(param1.blue - param2.blue)];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

- (id)addition:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2) {
        RGBA retVal;
        retVal.red = [self safe:abs(param1.red + param2.red)];
        retVal.green = [self safe:abs(param1.green + param2.green)];
        retVal.blue = [self safe:abs(param1.blue + param2.blue)];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

- (id) exclusion:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2) {
        RGBA retVal;
        retVal.red = [self safe:128.0 - 2.0 * (param2.red - 128.0) * (param1.red - 128.0) / 255.0];
        retVal.green = [self safe:128.0 - 2.0 * (param2.green - 128.0) * (param1.green - 128.0) / 255.0];
        retVal.blue = [self safe:128.0 - 2.0 * (param2.blue - 128.0) * (param1.blue - 128.0) / 255.0];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

- (float) calc_softlight:(float)b other:(float) t
{
    return (b > 128.0) ? 255.0 - ((255.0 - b) * (255.0 - (t - 128.0))) / 255.0 : (b * (t + 128.0)) / 255.0;
}

- (id) softLight:(UIImage *)topFltr
{
    return [self applyBlend:topFltr CallBack:^RGBA(RGBA param1, RGBA param2) {
        RGBA retVal;
        retVal.red = [self safe:[self calc_softlight: param2.red other:param1.red]];
        retVal.green = [self safe:[self calc_softlight: param2.green other:param1.green]];
        retVal.blue = [self safe:[self calc_softlight: param2.blue other:param1.blue]];
        retVal.alpha = param2.alpha;
        return retVal;
    }];
}

@end