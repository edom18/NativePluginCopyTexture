#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Metal/Metal.h>

#include "Unity/IUnityInterface.h"
#include "Unity/IUnityGraphics.h"
#include "Unity/IUnityGraphicsMetal.h"

#import "CaptureCallback.h"

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces);
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload();

static IUnityGraphicsMetal* s_MetalGraphics = 0;
static IUnityInterfaces*    s_UnityInterfaces  = 0;
static IUnityGraphics*      s_Graphics = 0;

extern "C" void _RequestCameraRollPermission()
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) { }];
}

extern "C" int _GetCameraRollPermission()
{
    PHAuthorizationStatus status = PHPhotoLibrary.authorizationStatus;
    return (int)status;
}

static void MBEReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@interface NativeTextureSaver : NSObject

+ (void)saveTexture:(id<MTLTexture>)texture;

@end

@implementation NativeTextureSaver

+ (void)saveTexture:(id<MTLTexture>)texture
{
    // NSAssert(texture.pixelFormat == MTLPixelFormatRGBA8Unorm, @"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create UIImage.");
    if (texture == NULL)
    {
        return;
    }

    CGSize imageSize = CGSizeMake(texture.width, texture.height);
    size_t imageByteCount = imageSize.width * imageSize.height * 4;

    void *imageBytes = malloc(imageByteCount);

    NSUInteger bytesPerRow = imageSize.width * 4;
    MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);

    [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, MBEReleaseDataCallback);

    int bitsPerComponent = 8;
    int bitsPerPixel = 32;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(imageSize.width,
                                        imageSize.height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        renderingIntent);

    UIImage *image = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationDownMirrored];

    CFRelease(provider);
    CFRelease(colorSpaceRef);
    CFRelease(imageRef);

    CaptureCallback *callback = [[CaptureCallback alloc] initWithObjectName:@"obj" methodName:@"method"];

    UIImageWriteToSavedPhotosAlbum(image, callback, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
}

@end 

static void UNITY_INTERFACE_API OnGraphicsDeviceEvent(UnityGfxDeviceEventType eventType)
{
    switch (eventType)
    {
        case kUnityGfxDeviceEventInitialize:
        {
            // s_RendererType = s_Graphics->GetRenderer();
            //TODO: ユーザー初期化コード
            break;
        }
        case kUnityGfxDeviceEventShutdown:
        {
            // s_RendererType = kUnityGfxRendererNull;
            //TODO: ユーザーシャットダウンコード
            break;
        }
        case kUnityGfxDeviceEventBeforeReset:
        {
            //TODO: ユーザー Direct3D 9 コード
            break;
        }
        case kUnityGfxDeviceEventAfterReset:
        {
            //TODO: ユーザー Direct3D 9 コード
            break;
        }
    };
}

extern "C" void _SaveTextureImpl(void *colorBuffer)
{
    id<MTLTexture> texture = s_MetalGraphics->TextureFromRenderBuffer((UnityRenderBuffer)colorBuffer);
    // id<MTLTexture> texture = (__bridge_transfer id<MTLTexture>)(void*)ptr;
    [NativeTextureSaver saveTexture:texture];
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
    NSLog(@"==================== Plugin has been loaded ====================");

    s_UnityInterfaces   = unityInterfaces;
    s_Graphics          = s_UnityInterfaces->Get<IUnityGraphics>();
    s_MetalGraphics     = s_UnityInterfaces->Get<IUnityGraphicsMetal>();

    s_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
    OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload()
{
    s_Graphics->UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _AttachPlugin()
{
    NSLog(@"Attaching plugin load.");
    UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
}