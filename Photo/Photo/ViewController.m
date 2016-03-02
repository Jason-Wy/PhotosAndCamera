//
//  ViewController.m
//  LGPhotoBrowser
//
//  Created by Jason on 15/10/27.
//  Copyright (c) 2015年 L&G. All rights reserved.
//

#import "ViewController.h"
#import "LGPhoto.h"
#define HEADER_HEIGHT 100

@interface ViewController ()<LGPhotoPickerViewControllerDelegate,LGPhotoPickerBrowserViewControllerDataSource,LGPhotoPickerBrowserViewControllerDelegate>

@property (nonatomic, strong)NSMutableArray *LGPhotoPickerBrowserPhotoArray;
@property (nonatomic, strong)NSMutableArray *LGPhotoPickerBrowserURLArray;
@property (nonatomic, assign) LGShowImageType showType;


- (void)presentCameraSingle ;
- (void)presentCameraContinuous ;


@end

@implementation ViewController

- (void)viewDidLoad {
    
    UIButton *confirmButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 100, 200, 44)];
    confirmButton.backgroundColor = [UIColor redColor];
    [confirmButton setBackgroundImage:[UIImage imageNamed:@"person-button-noround"] forState:UIControlStateNormal];
    [confirmButton setTitle:@"确认保存" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirmButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmButton];
    
    
    //设置照相通知
    [self addObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (UIView *obj in self.view.subviews) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            [obj removeFromSuperview];
        }
    }
}

- (void)addObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveCameraSingleResult)
                                                 name:LGCameraSingleNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveCameraContinuous)
                                                 name:LGCameraContinuousNotification
                                               object:nil];
    
}

- (void)receiveCameraSingleResult
{
    NSLog(@"dddddd");
}

- (void)receiveCameraContinuous
{
    NSLog(@"3333333");
}

- (void)confirmButtonAction:(UIButton *)sender
{
    //相册，但是相册有几种不同的类型
    [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImageURL];
    //照相，单张
//    [self presentCameraSingle];
    //照相，多张
//    [self presentCameraContinuous];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentPhotoPickerViewControllerWithStyle:(LGShowImageType)style {
    // 创建控制器
    LGPhotoPickerViewController *pickerVc = [[LGPhotoPickerViewController alloc] initWithShowType:style];
    // 默认显示相册里面的内容SavePhotos
    pickerVc.status = PickerViewShowStatusCameraRoll;
    
    // 最多能选9张图片
    pickerVc.maxCount = 9;
    pickerVc.delegate = self;
    self.showType = style;
    [pickerVc showPickerVc:self];
}

- (void)pushPhotoBroswerWithStyle:(LGShowImageType)style{
    LGPhotoPickerBrowserViewController *BroswerVC = [[LGPhotoPickerBrowserViewController alloc] init];
    BroswerVC.delegate = self;
    BroswerVC.dataSource = self;
    BroswerVC.showType = style;
    self.showType = style;
    [self presentViewController:BroswerVC animated:YES completion:nil];
}

- (void)presentCameraSingle {
    ZLCameraViewController *cameraVC = [[ZLCameraViewController alloc] init];
    // 拍照最多个数
    cameraVC.maxCount = 1;
    // 单拍
    cameraVC.cameraType = ZLCameraSingle;
    cameraVC.callback = ^(NSArray *cameras){
        //在这里得到拍照结果
        NSLog(@"拍照结果，单张");
    };
    [cameraVC showPickerVc:self];
}

- (void)presentCameraContinuous {
    ZLCameraViewController *cameraVC = [[ZLCameraViewController alloc] init];
    // 拍照最多个数
    cameraVC.maxCount = 4;
    // 连拍
    cameraVC.cameraType = ZLCameraContinuous;
    cameraVC.callback = ^(NSArray *cameras){
        //在这里得到拍照结果
        NSLog(@"拍照结果,多张");
    };
    [cameraVC showPickerVc:self];
}


#pragma mark - LGPhotoPickerViewControllerDelegate
- (void)pickerViewControllerDoneAsstes:(NSArray *)assets isOriginal:(BOOL)original{
    
    int i = 0;
    for (LGPhotoAssets *lgAsset in assets) {
        
        [self creatImageView:i WithImage:lgAsset.thumbImage];
        i = i+1;
    }
    
    i = 0;
    
    NSInteger num = (long)assets.count;
    NSString *isOriginal = original? @"YES":@"NO";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"发送图片" message:[NSString stringWithFormat:@"您选择了%ld张图片\n是否原图：%@",(long)num,isOriginal] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

- (void)creatImageView:(NSInteger )number WithImage:(UIImage *)image
{
    float width = [UIScreen mainScreen].bounds.size.width;
    width -= 40;
    float row = number%4;
    float select = number/4;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(10+(width/4)*row+(10*row?YES:0), 144+10+(width/4)*select+(10*select?YES:0), width/4, width/4)];
    NSLog(@"%d",10*row?0:YES);
    imageView.image = image;
    [self.view addSubview:imageView];
}

#pragma mark - LGPhotoPickerBrowserViewControllerDataSource
- (NSInteger)photoBrowser:(LGPhotoPickerBrowserViewController *)photoBrowser numberOfItemsInSection:(NSUInteger)section{
    if (self.showType == LGShowImageTypeImageBroswer) {
    return self.LGPhotoPickerBrowserPhotoArray.count;
    } else if (self.showType == LGShowImageTypeImageURL) {
    return self.LGPhotoPickerBrowserURLArray.count;
    } else {
    NSLog(@"非法数据源");
    return 0;
    }
}

- (id<LGPhotoPickerBrowserPhoto>)photoBrowser:(LGPhotoPickerBrowserViewController *)pickerBrowser photoAtIndexPath:(NSIndexPath *)indexPath{
    if (self.showType == LGShowImageTypeImageBroswer) {
        return [self.LGPhotoPickerBrowserPhotoArray objectAtIndex:indexPath.item];
    } else if (self.showType == LGShowImageTypeImageURL) {
        return [self.LGPhotoPickerBrowserURLArray objectAtIndex:indexPath.item];
    } else {
        NSLog(@"非法数据源");
        return nil;
    }
}


@end
