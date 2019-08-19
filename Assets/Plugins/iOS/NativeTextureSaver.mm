#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Metal/Metal.h>

#include "Unity/IUnityInterface.h"
#include "Unity/IUnityGraphics.h"
#include "Unity/IUnityGraphicsMetal.h"

#import "CaptureCallback.h"

// Please rewrite if needed.
#import "nativetexturesaver-Swift.h"

extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces);
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload();

static IUnityGraphicsMetal* s_MetalGraphics = 0;
static IUnityInterfaces*    s_UnityInterfaces  = 0;
static IUnityGraphics*      s_Graphics = 0;

static bool initialized = false;

@interface NativeTextureSaver : NSObject

+ (void)saveTexture:(id<MTLTexture>)texture;

@end

@implementation NativeTextureSaver

+ (void)saveTexture:(id<MTLTexture>)texture
{
    UIImage *image = [MTLTextureConverter convertWithTexture:texture];
    
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

id<MTLTexture> CopyTexture(id<MTLTexture> source)
{
    MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
    descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    descriptor.width = source.width;
    descriptor.height = source.height;
    
    id<MTLTexture> texture = [s_MetalGraphics->MetalDevice() newTextureWithDescriptor:descriptor];

    id<MTLCommandQueue> queue = [s_MetalGraphics->MetalDevice() newCommandQueue];
    id<MTLCommandBuffer> buffer = [queue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [buffer blitCommandEncoder];
    [encoder copyFromTexture:source
                 sourceSlice:0
                 sourceLevel:0
                sourceOrigin:MTLOriginMake(0, 0, 0)
                  sourceSize:MTLSizeMake(source.width, source.height, source.depth)
                   toTexture:texture
            destinationSlice:0
            destinationLevel:0
           destinationOrigin:MTLOriginMake(0, 0, 0)];
    [encoder endEncoding];
    [buffer commit];
    [buffer waitUntilCompleted];

    return texture;
}

extern "C" void _SaveTextureImpl(unsigned char* mtlTexture)
{
    id<MTLTexture> tex = (__bridge id<MTLTexture>)(void*)mtlTexture;
    
    NSLog(@"%@", tex);
    
    NSLog(@"%d -------- %d", (int)tex.width, (int)tex.height);
    
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
