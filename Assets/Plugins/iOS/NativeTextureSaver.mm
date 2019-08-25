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

//    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
//        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
//    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//        if (success)
//        {
//            NSLog(@"Image saved.");
//        }
//        else
//        {
//            NSLog(@"error in saving image : %@", error);
//        }
//    }];
    
    if (PHPhotoLibrary.authorizationStatus != PHAuthorizationStatusAuthorized)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            if (status == PHAuthorizationStatusAuthorized)
            {
                // フォトライブラリに写真を保存するなど、実施したいことをここに書く
            }
            else if (status == PHAuthorizationStatusDenied)
            {
//                NSString* title = @"Failed to save image";
//                NSString* message = @"Allow this app to access Photos.";
//
//                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//                let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (_) -> Void in
//                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString ) else {
//                        return
//                    }
//                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
//                })
//                let closeAction: UIAlertAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
//                alert.addAction(settingsAction)
//                alert.addAction(closeAction)
//                self.present(alert, animated: true, completion: nil)
            }
        }];
        return;
    }
    
    __block NSString* localId;
    
    // Add it to the photo library
    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        localId = assetChangeRequest.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError *err) {
        
        if (!success)
        {
            NSLog(@"Error saving image: %@", err.localizedDescription);
            [callback savingImageIsFinished:nil
                   didFinishSavingWithError:err];
        }
        else
        {
            PHFetchResult* assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localId] options:nil];
            PHAsset *asset = assetResult.firstObject;
            [PHImageManager.defaultManager requestImageDataForAsset:asset
                                                            options:nil
                                                      resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                          
                                                            NSURL *fileUrl = [info objectForKey:@"PHImageFileURLKey"];
                                                          
                                                            if (fileUrl)
                                                            {
                                                                NSLog(@"Image path: %@", fileUrl.relativePath);
                                                                [callback savingImageIsFinished:fileUrl
                                                                       didFinishSavingWithError:nil];
                                                            }
                                                            else
                                                            {
                                                                NSLog(@"Error retrieving image filePath, heres whats available: %@", info);
                                                                [callback savingImageIsFinished:nil
                                                                       didFinishSavingWithError:nil];
                                                            }
                                                        }];
        }
    }];
    
//    UIImageWriteToSavedPhotosAlbum(image, callback, @selector(savingImageIsFinished:didFinishSavingWithError:contextInfo:), nil);
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
