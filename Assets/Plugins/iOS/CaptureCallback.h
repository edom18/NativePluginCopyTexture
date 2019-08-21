#import <Foundation/Foundation.h>
 
@interface CaptureCallback : NSObject

@property (nonatomic, copy) NSString *objectName;
@property (nonatomic, copy) NSString *methodName;

- (id)initWithObjectName:(NSString *)_objectName methodName:(NSString *)_methodName;
 
- (void)savingImageIsFinished:(UIImage *)_image didFinishSavingWithError:(NSError *)_error contextInfo:(void *)_contextInfo;
- (void)savingImageIsFinished:(NSURL *)path didFinishSavingWithError:(NSError *)error;

@end
