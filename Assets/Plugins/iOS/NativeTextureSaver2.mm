//
//  testTexturePlugin.m
//  Unity-iPhone
//
//  Created by user on 18/01/16.
//
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <UIKit/UIKit.h>

#include "UnityMetalSupport.h"

#include <stdlib.h>
#include <stdint.h>

static UIImage* LoadImage()
{
    NSString* imageName = @"logo"; //[NSString stringWithUTF8String: filename];
    NSString* imagePath = [[NSBundle mainBundle] pathForResource: imageName ofType: @"png"];

    return [UIImage imageWithContentsOfFile: imagePath];
}

// you need to free this pointer
static void* LoadDataFromImage(UIImage* image)
{
    CGImageRef imageData    = image.CGImage;
    unsigned   imageW       = CGImageGetWidth(imageData);
    unsigned   imageH       = CGImageGetHeight(imageData);

    // for the sake of the sample we enforce 128x128 textures
    //assert(imageW == 128 && imageH == 128);

    void* textureData = ::malloc(imageW * imageH * 4);
    ::memset(textureData, 0x00, imageW * imageH * 4);

    CGContextRef textureContext = CGBitmapContextCreate(textureData, imageW, imageH, 8, imageW * 4, CGImageGetColorSpace(imageData), kCGImageAlphaPremultipliedLast);
    CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
    CGContextDrawImage(textureContext, CGRectMake(0, 0, imageW, imageH), imageData);
    CGContextRelease(textureContext);

    return textureData;
}

static void CreateMetalTexture(uintptr_t texRef, void* data, unsigned w, unsigned h)
{
#if defined(__IPHONE_8_0) && !TARGET_IPHONE_SIMULATOR

    NSLog(@"texRef iOS = %lu", texRef);

    id<MTLTexture> tex = (__bridge id<MTLTexture>)(void*)texRef;

    MTLRegion r = MTLRegionMake3D(0, 0, 0, w, h, 1);
    [tex replaceRegion: r mipmapLevel: 0 withBytes: data bytesPerRow: w * 4];

#else

#endif
}

extern "C" void FillUnityTexture(uintptr_t texRef)
{
    UIImage*    image       = LoadImage();
    void*       textureData = LoadDataFromImage(image);

    if (UnitySelectedRenderingAPI() == apiMetal)
        CreateMetalTexture(texRef, textureData, image.size.width, image.size.height);

    ::free(textureData);
}