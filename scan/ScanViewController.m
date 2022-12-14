//
//  ScanViewController.m
//  scan
//
//  Created by xu yongpan on 2021/6/1.
//

#import "ScanViewController.h"
#import <AVFoundation/AVFoundation.h>
//#import "ZXingObjC.h"
#import "FFZRecorder.h"
#import "FFZRecordToolsView.h"
#import "QRCodeLocation.h"
#define kScreenHeight ([[UIScreen mainScreen] bounds].size.height)
#define kScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define TOP (kScreenHeight-220)/2
#define LEFT (kScreenWidth-220)/2
#define kScanRect CGRectMake(LEFT, TOP, 220, 220)
@interface ScanViewController ()<FFZRecorderDelegate>
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
    CAShapeLayer *cropLayer;
}

@property (nonatomic, strong) UIImageView * line;

@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) UIImage *myImage;
@property (strong, nonatomic) FFZRecorder *recorder;
@property (strong, nonatomic) FFZRecordToolsView *focusView;
@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    // Do any additional setup after loading the view.
    _recorder = [FFZRecorder recorder];
    _recorder.captureSessionPreset = [FFZRecoderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.delegate = self;
    _recorder.previewView = self.previewView;
    self.focusView = [[FFZRecordToolsView alloc] initWithFrame:_previewView.bounds];
    self.focusView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.focusView.recorder = _recorder;
    [_previewView addSubview:self.focusView];
}
- (void)dealloc {
    [self.focusView removeFromSuperview];
    [self.recorder distroy];
}
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self startRun];
    [self.view addSubview:self.line];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self stopRun];
    
}
- (id)initWithFFZQRCodeScanResultBlock:(FFZQRCodeScanResultBlock)scanResult {
    
    self = [super init];
    if (self) {
        self.scanResult = scanResult;
        [self setCropRect:kScanRect];
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
    
}
- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    [_recorder previewViewFrameChanged];
    
}

- (void)setCropRect:(CGRect)cropRect{
    
    cropLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, cropRect);
    CGPathAddRect(path, nil, self.view.bounds);
    
    [cropLayer setFillRule:kCAFillRuleEvenOdd];
    [cropLayer setPath:path];
    [cropLayer setFillColor:[UIColor blackColor].CGColor];
    [cropLayer setOpacity:0.6];
    
    CGPathRelease(path);
    [cropLayer setNeedsDisplay];
    
    [self.view.layer addSublayer:cropLayer];
    
}

- (void)stopRun {
    
    [_recorder stopRunning];
    [timer invalidate];
    timer = nil;
    
}

- (void)startRun {
    
    
    NSString *mediaType = AVMediaTypeVideo;//??????????????????
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//????????????????????????
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"????????????" message:@"????????????????????????,?????????????????????" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"??????" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            if (self.presentingViewController) {
                if (self.navigationController) {
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }else {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }else {
                
                [self.navigationController popViewControllerAnimated:YES];
                
            }
            
        }];
        [alertVC addAction:okAction];
        [self presentViewController:alertVC animated:YES completion:^{
            
        }];
        
        
    }else {
        [self stopRun];
        [_recorder startRunning];
        timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation) userInfo:nil repeats:YES];
    }
}

-(void)animation {
    
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(LEFT, TOP+10+2*num, 220, 2);
        if (2*num == 200) {
            upOrdown = YES;
        }
    } else {
        num --;
        _line.frame = CGRectMake(LEFT, TOP+10+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}


- (void)recorderDidEndFocus:(FFZRecorder *__nonnull)recorder {
    
    @autoreleasepool {
        
        
        if ([self paseImageWithNative:recorder.myImage] || [self paseImageWithZxing:recorder.myImage]) {
            
            return;
            
        }else {
            
            UIImage *image = [ScanViewController saturation:[ScanViewController cropSquareImage:recorder.myImage]];
            
            if (image) {
                
                if ([self paseImageWithNative:image] || [self paseImageWithZxing:image]) {
                    
                    return;
                    
                }
                UIImage *contrastImage = [ScanViewController contrast:image];
                if ([self paseImageWithNative:contrastImage] || [self paseImageWithZxing:contrastImage]) {
                    
                    return;
                }else {
                    
                    QRCodeModel *result = [QRCodeLocation  imageOpencvQRCode:image];
                    if (result) {
                        
                        [self paseCodeWithResult:result];
                        
                    }
                    return;
                }
            }
            
        }
        
    }
    
    
    
}

- (void)recorder:(FFZRecorder *__nonnull)recorder didFinishQRScanWithResoult:(NSString *_Nonnull)resoult {
    [self stopRun];
    
    if (self.scanResult) {
        self.scanResult(resoult);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}


- (BOOL)paseImageWithNative:(UIImage *)image {
    if (!self.recorder.captureSession.isRunning) {
        return YES;
    }
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:context options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [detector featuresInImage:ciImage];
    
    if(features.count>0) {
        CIQRCodeFeature *feature = [features objectAtIndex:0];
        NSString *scannedResult = feature.messageString;
        
        // dispatch_async(dispatch_get_main_queue(), ^{
        [self stopRun];
        if (self.scanResult) {
            self.scanResult(scannedResult);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
           
        }
        // });
        
        return YES;
    }else {
        
        return NO;
    }
    
    
}
- (BOOL)paseImageWithZxing:(UIImage *)image {
    
    if (!self.recorder.captureSession.isRunning) {
        return YES;
    }

//    ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
//    ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource: source];
//    ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];
//
//    NSError *error;
//
//    id<ZXReader> reader;
//    if (NSClassFromString(@"ZXMultiFormatReader")) {
//        reader = [NSClassFromString(@"ZXMultiFormatReader") performSelector:@selector(reader)];
//    }
//    ZXDecodeHints *_hints = [ZXDecodeHints hints];
//    ZXResult *result = [reader decode:bitmap hints:_hints error:&error];
//    if (result) {
//
//        [self stopRun];
//        if (result.text) {
//            self.scanResult(result.text);
//        }
//
//        return YES;
//
//    }else {
//
       return NO;
//
 //   }
    
}
- (void)paseCodeWithResult:(QRCodeModel *)model {
    
    
    
    CGFloat w = [model.w floatValue];
    CGFloat h = [model.h floatValue];
    CGFloat x = [model.x floatValue];
    CGFloat y = [model.x floatValue];
    // if (![self paseImage:self.myImage]) {
    dispatch_async(dispatch_get_main_queue(), ^{
        //CGPoint focusPoint = CGPointMake(x/self.myImage.size.width, y / self.myImage.size.height);
        CGPoint focusPoint = CGPointMake(0.5, 0.5);
        [self.recorder continuousFocusAtPoint:focusPoint];
        if (w < 200 && h < 200) {
            
            CGFloat scale = 200 / w;
            [self.focusView autoZoomWithVideoZoom:self.focusView.zoomFactor * scale];
            
        }
    });
    
    //  }
    
}

+ (UIImage *)cropSquareImage:(UIImage *)image{
    
    CGImageRef sourceImageRef = [image CGImage];//???UIImage?????????CGImageRef
    CGFloat scale = [UIScreen mainScreen].scale;
    
    CGFloat _imageWidth = image.size.width * image.scale;
    CGFloat _imageHeight = image.size.height * image.scale;
    CGFloat _width = (_imageWidth > _imageHeight ? _imageHeight : _imageWidth) > scale * scale * 200 ? scale * scale * 200 : (_imageWidth > _imageHeight ? _imageHeight : _imageWidth);
    
    CGFloat _offsetX = (_imageWidth - _width) / 2;
    CGFloat _offsetY = (_imageHeight - _width) / 2;
    
    CGRect rect = CGRectMake(_offsetX, _offsetY, _width, _width);
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);//???????????????????????????????????????
    
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    return newImage;
}

+ (UIImage *)saturation:(UIImage *)image {
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *superImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setValue:superImage forKey:kCIInputImageKey];
    
    // ????????????   -1---1   ???????????????
    //[lighten setValue:@(0.2) forKey:@"inputBrightness"];
    
    // ???????????????  0---2
    [lighten setValue:@(2) forKey:@"inputSaturation"];
    
    // ???????????????  0---4
    //[lighten setValue:@(4) forKey:@"inputContrast"];
    CIImage *result = [lighten valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[superImage extent]];
    
    // ????????????????????????
    image = [UIImage imageWithCGImage:cgImage];
    
    // ????????????
    CGImageRelease(cgImage);
    return image;
    
}

+ (UIImage *)contrast:(UIImage *)image {
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *superImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setValue:superImage forKey:kCIInputImageKey];
    
    // ????????????   -1---1   ???????????????
    //[lighten setValue:@(0.2) forKey:@"inputBrightness"];
    
    // ???????????????  0---2
    //[lighten setValue:@(2) forKey:@"inputSaturation"];
    
    // ???????????????  0---4
    [lighten setValue:@(4) forKey:@"inputContrast"];
    CIImage *result = [lighten valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[superImage extent]];
    
    // ????????????????????????
    image = [UIImage imageWithCGImage:cgImage];
    
    // ????????????
    CGImageRelease(cgImage);
    return image;
    
}

- (UIView *)previewView {
    if (!_previewView) {
        
        _previewView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_previewView];
    }
    return _previewView;
}

- (UIImageView *)line {
    if (!_line) {
        upOrdown = NO;
        num = 0;
        _line = [[UIImageView alloc] initWithFrame:CGRectMake(LEFT, TOP+10, 220, 2)];
        _line.image = [UIImage imageNamed:@"line"];
        
        [self.view addSubview:_line];
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:kScanRect];
        imageView.image = [UIImage imageNamed:@"pick_bg"];
        
        [self.view addSubview:imageView];
    }
    return _line;
}


- (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName {
    
    NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"FFZQRCodeResourse.bundle"];
    NSString *img_path = [bundlePath stringByAppendingPathComponent:imgName];
    
    return [UIImage imageWithContentsOfFile:img_path];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
