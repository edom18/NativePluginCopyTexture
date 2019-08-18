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

static bool initialized = false;

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
            initialized = false;
            break;
        }
        case kUnityGfxDeviceEventShutdown:
        {
            // s_RendererType = kUnityGfxRendererNull;
            initialized = false;
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

extern "C" void _SaveTextureImpl(unsigned char* mtlTexture)
{
    id<MTLTexture> tex = (__bridge_transfer id<MTLTexture>)(void*)mtlTexture;

    NSLog(@"%@", tex);

    if (tex.pixelFormat != MTLPixelFormatRGBA8Unorm)
    {
        tex = [tex newTextureViewWithPixelFormat:MTLPixelFormatRGBA8Unorm];
    }

    // if (tex.pixelFormat != MTLPixelFormatBGRA8Unorm_sRGB) {
    // id<MTLTexture> texture = (id<MTLTexture>)(size_t)texRef;
    // id<MTLTexture> texture = (__bridge_transfer id<MTLTexture>)(void*)texRef;
    [NativeTextureSaver saveTexture:tex];
}

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
    NSLog(@"==================== Plugin has been loaded ====================");

    s_UnityInterfaces = unityInterfaces;
    s_Graphics        = s_UnityInterfaces->Get<IUnityGraphics>();
    s_MetalGraphics   = s_UnityInterfaces->Get<IUnityGraphicsMetal>();

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

extern "C" uintptr_t UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _GetNativeTexturePtr(int width, int height)
{
    MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
    descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.width = width;
    descriptor.height = height;
    
    id<MTLTexture> texture = [s_MetalGraphics->MetalDevice() newTextureWithDescriptor:descriptor];

    return (uintptr_t)texture;
}
