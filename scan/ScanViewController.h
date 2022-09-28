//
//  ScanViewController.h
//  scan
//
//  Created by xu yongpan on 2021/6/1.
//

#import <UIKit/UIKit.h>
typedef void(^FFZQRCodeScanResultBlock)(NSString * _Nullable result);
NS_ASSUME_NONNULL_BEGIN

@interface ScanViewController : UIViewController
@property (copy, nonatomic) FFZQRCodeScanResultBlock scanResult;

- (id)initWithFFZQRCodeScanResultBlock:(FFZQRCodeScanResultBlock) scanResult;
- (void)stopRun;
- (void)startRun;
@end

NS_ASSUME_NONNULL_END
