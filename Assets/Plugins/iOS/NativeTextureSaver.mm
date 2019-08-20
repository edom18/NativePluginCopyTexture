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
            // TODO: User Direct3D 9 code
            break;
        }
        case kUnityGfxDeviceEventAfterReset:
        {
            // TODO: User Direct3D 9 code
            break;
        }
    };
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

///
/// Attach the functions to the callback of plugin loaded event.
///
extern "C" void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _AttachPlugin()
{
    NSLog(@"Attaching plugin load.");
    UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
}

///
/// Save the texture that made from Metal to the file.
///
extern "C" void _SaveTextureImpl(unsigned char* mtlTexture, const char* objectName, const char* methodName)
{
    id<MTLTexture> tex = (__bridge id<MTLTexture>)(void*)mtlTexture;
    
    UIImage *image = [MTLTextureConverter convertWithTexture:tex];
    
    NSString* objName = [NSString stringWithCString:objectName encoding:NSUTF8StringEncoding];
    NSString* metName = [NSString stringWithCString:methodName encoding:NSUTF8StringEncoding];
    CaptureCallback *callback = [[CaptureCallback alloc] initWithObjectName:objName methodName:metName];

    UIImageWriteToSavedPhotosAlbum(image, callback, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
}

///
/// Copy MTLTexture to a new one.
/// This function won't be used for this demo.
/// But I don't remove this code. It will help you.
///
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
