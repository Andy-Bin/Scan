//
//  BaseViewController.m
//  scan
//
//  Created by xu yongpan on 2021/6/1.
//

#import "BaseViewController.h"
#import "ScanViewController.h"
@interface BaseViewController ()
@property (nonatomic,strong)UILabel *tipsLab;
@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tipsLab = [[UILabel alloc]initWithFrame:CGRectMake(20, 100, 200, 30)];
    self.tipsLab.text = @"扫描结果";
    [self.view addSubview:self.tipsLab];
    
    UIButton *scanBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 90, 40)];
    [scanBtn setTitle:@"扫一扫" forState:UIControlStateNormal];
    [scanBtn addTarget:self action:@selector(scanBtn) forControlEvents:UIControlEventTouchUpInside];
    scanBtn.backgroundColor = [UIColor blackColor];
    [self.view addSubview:scanBtn];
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *historyArr = [NSMutableArray array];
    for (int i=1; i<15; i++) {
        [historyArr addObject:[NSString stringWithFormat:@"%d",i]];
    }
    dispatch_group_async(group, dispatch_get_global_queue(0,0), ^{
    // 并行执行的线程一
        //循环遍历去重
        for (NSString *iNT in historyArr) {
            sleep(1);
            NSLog(@"%@",iNT);
        }
    });
  
    dispatch_group_notify(group, dispatch_get_global_queue(0,0), ^{
    // 汇总结果
        NSLog(@"wang ");
    });

}
-(void)scanBtn{
    ScanViewController *vc = [[ScanViewController alloc]init];
    vc.scanResult = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tipsLab.text = result;
        });
    };
    [self.navigationController pushViewController:vc animated:YES];
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
