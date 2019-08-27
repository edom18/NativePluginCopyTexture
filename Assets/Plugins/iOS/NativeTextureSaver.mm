#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <Metal/Metal.h>

#include "Unity/IUnityInterface.h"
#include "Unity/IUnityGraphics.h"
#include "Unity/IUnityGraphicsMetal.h"

#import "CaptureCallback.h"

// Please rewrite if needed.
#import "nativetexturesaver-Swift.h"

extern "C"
{
    void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces);
    void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload();
    void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces);
    void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _AttachPlugin();
    void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _SaveTextureImpl(unsigned char* mtlTexture, const char* objectName, const char* methodName);
}

void SaveTexture(unsigned char* mtlTexture, const char* objectName, const char* methodName);

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

void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* unityInterfaces)
{
    NSLog(@"==================== Plugin has been loaded ====================");

    s_UnityInterfaces = unityInterfaces;
    s_Graphics        = s_UnityInterfaces->Get<IUnityGraphics>();
    s_MetalGraphics   = s_UnityInterfaces->Get<IUnityGraphicsMetal>();

    s_Graphics->RegisterDeviceEventCallback(OnGraphicsDeviceEvent);
    OnGraphicsDeviceEvent(kUnityGfxDeviceEventInitialize);
}

void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload()
{
    s_Graphics->UnregisterDeviceEventCallback(OnGraphicsDeviceEvent);
}

///
/// Attach the functions to the callback of plugin loaded event.
///
void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _AttachPlugin()
{
    NSLog(@"Attaching plugin load.");
    UnityRegisterRenderingPluginV5(&UnityPluginLoad, &UnityPluginUnload);
}

///
/// Save the texture that made from Metal to the file.
///
void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _SaveTextureImpl(unsigned char* mtlTexture, const char* objectName, const char* methodName)
{
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized)
    {
        SaveTexture(mtlTexture, objectName, methodName);
        return;
    }

    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        if (status == PHAuthorizationStatusAuthorized)
        {
            SaveTexture(mtlTexture, objectName, methodName);
            return;
        }

        if (status == PHAuthorizationStatusDenied)
        {
            NSString* title = @"Failed to save image";
            NSString* message = @"Allow this app to access Photos.";

            UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* settingsAction = [UIAlertAction actionWithTitle:@"Settings"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction* action)
                                                                   {
                                                                        NSURL* settingsURL = [NSURL  URLWithString:UIApplicationOpenSettingsURLString];

                                                                        if (!settingsURL)
                                                                        {
                                                                            return;
                                                                        }

                                                                        [UIApplication.sharedApplication openURL:settingsURL
                                                                                                         options:@{}
                                                                                               completionHandler:nil];
                                                                   }];

            UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"Close"
                                                                  style:UIAlertActionStyleCancel
                                                                handler:nil];
            [alert addAction:settingsAction];
            [alert addAction:closeAction];
            [UnityGetGLViewController() presentViewController:alert
                                                     animated:YES
                                                   completion:nil];
        }
    }];
}

void SaveTexture(unsigned char* mtlTexture, const char* objectName, const char* methodName)
{
    id<MTLTexture> tex = (__bridge id<MTLTexture>)(void*)mtlTexture;
    
    UIImage *image = [MTLTextureConverter convertWithTexture:tex];
    
    NSString* objName = [NSString stringWithCString:objectName encoding:NSUTF8StringEncoding];
    NSString* metName = [NSString stringWithCString:methodName encoding:NSUTF8StringEncoding];
    CaptureCallback *callback = [[CaptureCallback alloc] initWithObjectName:objName methodName:metName];
    
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
}
