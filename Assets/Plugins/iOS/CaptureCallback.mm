#import "CaptureCallback.h"
 
@implementation CaptureCallback

- (id)initWithObjectName:(NSString *)_objectName
              methodName:(NSString *)_methodName;
{
    if (self = [super init])
    {
        self.objectName = _objectName;
        self.methodName = _methodName;
    }
    return self;
}
 
- (void)savingImageIsFinished:(UIImage *)_image didFinishSavingWithError:(NSError *)_error contextInfo:(void *)_contextInfo
{
    NSLog(@"done");
    // const char *objectName = [self.objectName UTF8String];
    // const char *methodName = [self.methodName UTF8String];
    // UnitySendMessage(objectName, methodName, "");
}
 
@end