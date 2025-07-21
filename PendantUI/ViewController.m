//
//  ViewController.m
//  PendantUI
//
//  Created by tim on 2025/7/17.
//

#import "ViewController.h"

// MARK: - 数据模型
// 定义数据模型来存储从服务器获取的文本信息
@interface PendantDataModel : NSObject
@property (nonatomic, strong) NSString *mainTitle;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userTitle;
@property (nonatomic, strong) NSString *challengeTitle;
@property (nonatomic, strong) NSString *progressText;
@property (nonatomic, strong) NSString *rewardText;
@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, assign) CGFloat progressValue;
@end

@implementation PendantDataModel
@end

// MARK: - 网络配置常量
static NSString * const kServerBaseURL = @"http://172.23.17.226:8080"; // 您的实际服务器地址
static NSString * const kPendantDataEndpoint = @"/pendant-data";
static NSString * const kStatusEndpoint = @"/status";
// 遵从UIScrollViewDelegate协议，用于监听滚动视图事件
@interface ViewController () <UIScrollViewDelegate>

// UI控件属性
@property (nonatomic, strong) UIPageControl *pageControl;

// 网络数据相关属性
@property (nonatomic, strong) PendantDataModel *pendantData;
@property (nonatomic, strong) NSURLSession *networkSession;

// UI元素引用，用于动态更新
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *userTitleLabel;
@property (nonatomic, strong) UILabel *challengeTitleLabel;
@property (nonatomic, strong) UILabel *progressTextLabel;
@property (nonatomic, strong) UILabel *rewardTextLabel;
@property (nonatomic, strong) UILabel *eventTitleLabel;

@end
@implementation ViewController

// MARK: - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化网络功能
    [self setupNetworking];
    
    // 初始化UI界面
    [self setupUI];
    
    // 获取服务器数据
    [self fetchPendantData];
}

// MARK: - 网络配置与数据获取

/**
 * @brief 设置网络配置
 */
- (void)setupNetworking {
    // 配置NSURLSession
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 10.0; // 请求超时10秒
    config.timeoutIntervalForResource = 30.0; // 资源超时30秒
    self.networkSession = [NSURLSession sessionWithConfiguration:config];
    
    // 初始化默认数据模型（作为网络请求失败时的备用数据）
    self.pendantData = [[PendantDataModel alloc] init];
    self.pendantData.mainTitle = @"唱歌十强争夺";
    self.pendantData.userName = @"沾沾";
    self.pendantData.userTitle = @"巅峰冠军";
    self.pendantData.challengeTitle = @"心愿挑战";
    self.pendantData.progressText = @"心愿值还差 50000";
    self.pendantData.rewardText = @"玩法奖励抢先看 >";
    self.pendantData.eventTitle = @"2024秋季盛典";
    self.pendantData.progressValue = 0.7;
    
    NSLog(@"🔧 网络配置完成，服务器地址: %@", kServerBaseURL);
}

/**
 * @brief 从服务器获取挂件数据
 */
- (void)fetchPendantData {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerBaseURL, kPendantDataEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url) {
        NSLog(@"❌ 无效的服务器URL: %@", urlString);
        return;
    }
    
    NSLog(@"🌐 正在从服务器获取数据: %@", urlString);
    // 创建数据任务
    NSURLSessionDataTask *dataTask = [self.networkSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            NSLog(@"❌ 网络请求失败: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNetworkError:error];
            });
            return;
        }
        
        // 检查HTTP响应状态
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSLog(@"❌ 服务器响应错误，状态码: %ld", (long)httpResponse.statusCode);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showServerError:httpResponse.statusCode];
            });
            return;
        }
        // 解析JSON数据
        NSError *parseError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError) {
            NSLog(@"❌ JSON解析失败: %@", parseError.localizedDescription);
            return;
        }
        
        NSLog(@"✅ 成功获取服务器数据");
        NSLog(@"📄 数据内容: %@", jsonData);
        
        // 在主线程更新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateDataModel:jsonData];
            [self updateUIWithNewData];
        });
    }];
    
    [dataTask resume];
}

/**
 * @brief 更新数据模型
 */
- (void)updateDataModel:(NSDictionary *)jsonData {
    if (!jsonData) return;
    
    NSDictionary *firstPage = jsonData[@"firstPage"];
    NSDictionary *secondPage = jsonData[@"secondPage"];
    NSDictionary *bottomBar = jsonData[@"bottomBar"];
    
    // 更新第一页数据
    if (firstPage) {
        self.pendantData.mainTitle = firstPage[@"mainTitle"] ?: self.pendantData.mainTitle;
        self.pendantData.userName = firstPage[@"userName"] ?: self.pendantData.userName;
        self.pendantData.userTitle = firstPage[@"userTitle"] ?: self.pendantData.userTitle;
    }
    
    // 更新第二页数据
    if (secondPage) {
        self.pendantData.challengeTitle = secondPage[@"challengeTitle"] ?: self.pendantData.challengeTitle;
        self.pendantData.progressText = secondPage[@"progressText"] ?: self.pendantData.progressText;
        self.pendantData.rewardText = secondPage[@"rewardText"] ?: self.pendantData.rewardText;
        
        NSNumber *progressValue = secondPage[@"progressValue"];
        if (progressValue) {
            self.pendantData.progressValue = [progressValue floatValue];
        }
    }
    
    // 更新底部栏数据
    if (bottomBar) {
        self.pendantData.eventTitle = bottomBar[@"eventTitle"] ?: self.pendantData.eventTitle;
    }
    
    NSLog(@"📱 数据模型更新完成");
}

/**
 * @brief 用新数据更新UI
 */
- (void)updateUIWithNewData {
    // 更新第一页标签
    if (self.mainTitleLabel) {
        self.mainTitleLabel.text = self.pendantData.mainTitle;
        NSLog(@"🔄 更新主标题: %@", self.pendantData.mainTitle);
    }
    
    if (self.userNameLabel) {
        self.userNameLabel.text = self.pendantData.userName;
        NSLog(@"🔄 更新用户名: %@", self.pendantData.userName);
    }
    
    if (self.userTitleLabel) {
        self.userTitleLabel.text = self.pendantData.userTitle;
        NSLog(@"🔄 更新用户头衔: %@", self.pendantData.userTitle);
    }
    
    // 更新第二页标签
    if (self.challengeTitleLabel) {
        self.challengeTitleLabel.text = self.pendantData.challengeTitle;
        NSLog(@"🔄 更新挑战标题: %@", self.pendantData.challengeTitle);
    }
    
    if (self.progressTextLabel) {
        self.progressTextLabel.text = self.pendantData.progressText;
        NSLog(@"🔄 更新进度文本: %@", self.pendantData.progressText);
    }
    
    if (self.rewardTextLabel) {
        self.rewardTextLabel.text = self.pendantData.rewardText;
        NSLog(@"🔄 更新奖励文本: %@", self.pendantData.rewardText);
    }
    
    // 更新底部栏
    if (self.eventTitleLabel) {
        self.eventTitleLabel.text = self.pendantData.eventTitle;
        NSLog(@"🔄 更新活动标题: %@", self.pendantData.eventTitle);
    }
    
    NSLog(@"✅ UI更新完成");
}

/**
 * @brief 显示网络错误提示
 */
- (void)showNetworkError:(NSError *)error {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"网络连接失败"
                         message:[NSString stringWithFormat:@"无法连接到服务器\n错误: %@\n\n请确保:\n• Mac和iPhone在同一WiFi网络\n• 服务器正在运行\n• IP地址配置正确", error.localizedDescription]
                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self fetchPendantData];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:retryAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 * @brief 显示服务器错误提示
 */
- (void)showServerError:(NSInteger)statusCode {
    NSString *message = [NSString stringWithFormat:@"服务器响应错误\n状态码: %ld\n\n请检查服务器是否正常运行", (long)statusCode];
    
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"服务器错误" 
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

/**
 * @brief 添加刷新按钮用于测试网络功能
 */
- (void)addRefreshButton {
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [refreshButton setTitle:@"🔄 刷新数据" forState:UIControlStateNormal];
    refreshButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.8];
    [refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    refreshButton.layer.cornerRadius = 8;
    refreshButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [refreshButton addTarget:self action:@selector(refreshButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:refreshButton];
    refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [refreshButton.widthAnchor constraintEqualToConstant:100],
        [refreshButton.heightAnchor constraintEqualToConstant:40],
        [refreshButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [refreshButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20]
    ]];
}

/**
 * @brief 刷新按钮点击事件
 */
- (void)refreshButtonTapped:(UIButton *)sender {
    NSLog(@"🔄 手动刷新数据");
    [self fetchPendantData];
    
    // 添加简单的视觉反馈
    sender.alpha = 0.5;
    [UIView animateWithDuration:0.3 animations:^{
        sender.alpha = 1.0;
    }];
}

/**
 * @brief 统一的UI设置入口
 */
- (void)setupUI {
    self.view.backgroundColor = [UIColor grayColor];
    // 添加刷新按钮（用于测试网络功能）
    [self addRefreshButton];
    
    // 创建主要UI界面
    [self createMainInterface];
}

/**
 * @brief 创建主界面
 */
- (void)createMainInterface {
    // 在此处实现挂件UI demo
    // 1. 创建 containerView 作为逻辑容器（不可见，仅用于布局）
    // 这个视图本身不显示任何内容，它的作用是作为一个“画布”或“参考系”，所有其他UI元素都相对于它来定位。
    // 这样做的好处是，当需要整体移动或缩放整个挂件时，只需调整containerView即可。
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor clearColor]; // 设置为透明，使其不可见
    [self.view addSubview:containerView]; // 将容器视图添加到主视图中
    containerView.translatesAutoresizingMaskIntoConstraints = NO; // 禁用自动布局转换
    // 设置 containerView 尺寸 112x172，并使其在屏幕中央
    [NSLayoutConstraint activateConstraints:@[
        [containerView.widthAnchor constraintEqualToConstant:112],
        [containerView.heightAnchor constraintEqualToConstant:172],
        [containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];

    // 2. 创建 gradientBackgroundView 视觉背景
    // 这是挂件的主要背景，带有一个复杂的渐变效果。
    UIView *gradientBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 111, 151)];
    gradientBackgroundView.alpha = 0.88; // 设置透明度
    gradientBackgroundView.layer.cornerRadius = 12; // 设置圆角
    gradientBackgroundView.layer.masksToBounds = YES; // 裁剪超出圆角的部分
    // 添加渐变层 (CAGradientLayer)
    CAGradientLayer *layer0 = [CAGradientLayer layer];
    // 设置渐变颜色数组
    layer0.colors = @[(__bridge id)[UIColor colorWithRed:0.354 green:0.229 blue:0.132 alpha:1].CGColor,
                      (__bridge id)[UIColor colorWithRed:0.326 green:0.167 blue:0.056 alpha:1].CGColor,
                      (__bridge id)[UIColor colorWithRed:0.191 green:0.07 blue:0 alpha:1].CGColor];
    // 设置颜色分布的位置
    layer0.locations = @[@0, @0.42, @0.83];
    // 设置渐变的起点和终点，定义渐变方向
    layer0.startPoint = CGPointMake(0.25, 0.5);
    layer0.endPoint = CGPointMake(0.75, 0.5);
    // 应用仿射变换（旋转、缩放、平移），使渐变呈现一个倾斜的效果
    layer0.affineTransform = CGAffineTransformMake(-0.59, 1.02, -0.65, -0.29, 1.1, 0.15);
    // 设置渐变层的大小和位置，使其完全覆盖背景视图
    layer0.bounds = CGRectInset(gradientBackgroundView.bounds, -0.5 * gradientBackgroundView.bounds.size.width, -0.5 * gradientBackgroundView.bounds.size.height);
    layer0.position = CGPointMake(CGRectGetMidX(gradientBackgroundView.bounds), CGRectGetMidY(gradientBackgroundView.bounds));
    [gradientBackgroundView.layer addSublayer:layer0]; // 将渐变层添加到背景视图的layer上
    [containerView addSubview:gradientBackgroundView]; // 将背景视图添加到逻辑容器中
    gradientBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 gradientBackgroundView 的布局约束
    [NSLayoutConstraint activateConstraints:@[
        [gradientBackgroundView.widthAnchor constraintEqualToConstant:111],
        [gradientBackgroundView.heightAnchor constraintEqualToConstant:151],
        [gradientBackgroundView.topAnchor constraintEqualToAnchor:containerView.topAnchor], // 与容器顶部对齐
        [gradientBackgroundView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor] // 水平居中
    ]];

    // 2.1 在 gradientBackgroundView 上方添加 Component2 图片
    // 这是一个装饰性图片，位于背景之上，增加了视觉层次感。
    UIImageView *component2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Component2"]];
    component2ImageView.contentMode = UIViewContentModeScaleAspectFit; // 保持图片比例缩放
    [containerView addSubview:component2ImageView]; // 注意：添加到containerView，而不是gradientBackgroundView
    component2ImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：顶部对齐 containerView 顶部，水平居中，宽度为112，不限制高度
    [NSLayoutConstraint activateConstraints:@[
        [component2ImageView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
        [component2ImageView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [component2ImageView.widthAnchor constraintEqualToConstant:112]
    ]];
    // 详细注释：
    // component2ImageView 显示 Component2.png，宽度为112，高度自适应，位于 gradientBackgroundView 顶部正中
    // 2.2 在 gradientBackgroundView 区域添加轮播控件（UIScrollView + 分页）
    // 通过UIScrollView实现一个可以左右滑动的轮播视图。
    UIScrollView *carouselScrollView = [[UIScrollView alloc] init];
    carouselScrollView.pagingEnabled = YES; // 开启分页效果，每次滑动都停在整页位置
    carouselScrollView.showsHorizontalScrollIndicator = NO; // 隐藏水平滚动条
    carouselScrollView.showsVerticalScrollIndicator = NO; // 隐藏垂直滚动条
    carouselScrollView.bounces = YES; // 开启边缘回弹效果
    carouselScrollView.layer.cornerRadius = 12; // 设置圆角以匹配父视图
    carouselScrollView.layer.masksToBounds = YES; // 裁剪内容
    [containerView addSubview:carouselScrollView]; // 添加到容器视图
    carouselScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：使其完全填满 gradientBackgroundView
    [NSLayoutConstraint activateConstraints:@[
        [carouselScrollView.leadingAnchor constraintEqualToAnchor:gradientBackgroundView.leadingAnchor],
        [carouselScrollView.trailingAnchor constraintEqualToAnchor:gradientBackgroundView.trailingAnchor],
        [carouselScrollView.topAnchor constraintEqualToAnchor:gradientBackgroundView.topAnchor],
        [carouselScrollView.bottomAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor]
    ]];
    // 添加两个页面：第一页为原有内容，第二页为箭头图标页面
    CGFloat pageWidth = 111; // 页面宽度
    CGFloat pageHeight = 151; // 页面高度
    carouselScrollView.contentSize = CGSizeMake(pageWidth * 2, pageHeight); // 设置可滚动区域的总大小
    // 首页内容（可放置原有内容或留空）
    UIView *firstPageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
    firstPageView.backgroundColor = [UIColor clearColor]; // 保持透明，这样能看到下层的gradientBackgroundView
    [carouselScrollView addSubview:firstPageView];
    // === 在 firstPageView 中添加头像容器和文本标签 ===
    // 1. 在 firstPageView 中添加头像容器 profileContainerView
    UIView *profileContainerView = [[UIView alloc] init];
    profileContainerView.backgroundColor = [UIColor clearColor];
    [firstPageView addSubview:profileContainerView];
    profileContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：相对于 firstPageView 定位
    [NSLayoutConstraint activateConstraints:@[
        [profileContainerView.widthAnchor constraintEqualToConstant:41.14],
        [profileContainerView.heightAnchor constraintEqualToConstant:48.57],
        [profileContainerView.leadingAnchor constraintEqualToAnchor:firstPageView.leadingAnchor constant:35],
        [profileContainerView.topAnchor constraintEqualToAnchor:firstPageView.topAnchor constant:56.43]
    ]];
    // 2. 在 profileContainerView 内添加圆形头像
    UIImageView *profileImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile"]];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    profileImageView.layer.cornerRadius = 41.14 / 2.0;
    profileImageView.layer.masksToBounds = YES;
    profileImageView.layer.borderWidth = 1.0;
    profileImageView.layer.borderColor = [UIColor colorWithRed:1 green:0.887 blue:0.717 alpha:1].CGColor;
    [profileContainerView addSubview:profileImageView];
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [profileImageView.widthAnchor constraintEqualToConstant:41.14],
        [profileImageView.heightAnchor constraintEqualToConstant:41.14],
        [profileImageView.centerXAnchor constraintEqualToAnchor:profileContainerView.centerXAnchor],
        [profileImageView.topAnchor constraintEqualToAnchor:profileContainerView.topAnchor]
    ]];
    // 3. 在 firstPageView 中添加 "+"号图标容器
    UIView *plusContainerView = [[UIView alloc] init];
    plusContainerView.backgroundColor = [UIColor clearColor];
    [firstPageView addSubview:plusContainerView];
    [firstPageView bringSubviewToFront:plusContainerView];
    plusContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [plusContainerView.widthAnchor constraintEqualToConstant:12],
        [plusContainerView.heightAnchor constraintEqualToConstant:12],
        [plusContainerView.centerXAnchor constraintEqualToAnchor:profileContainerView.centerXAnchor],
        [plusContainerView.topAnchor constraintEqualToAnchor:firstPageView.topAnchor constant:93]
    ]];

    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus"]];
    plusImageView.contentMode = UIViewContentModeScaleAspectFit;
    plusImageView.clipsToBounds = YES;
    [plusContainerView addSubview:plusImageView];
    plusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [plusImageView.leadingAnchor constraintEqualToAnchor:plusContainerView.leadingAnchor],
        [plusImageView.trailingAnchor constraintEqualToAnchor:plusContainerView.trailingAnchor],
        [plusImageView.topAnchor constraintEqualToAnchor:plusContainerView.topAnchor],
        [plusImageView.bottomAnchor constraintEqualToAnchor:plusContainerView.bottomAnchor]
    ]];

    UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    plusButton.backgroundColor = [UIColor clearColor];
    plusButton.translatesAutoresizingMaskIntoConstraints = NO;
    [plusContainerView addSubview:plusButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [plusButton.widthAnchor constraintEqualToConstant:14],
        [plusButton.heightAnchor constraintEqualToConstant:14],
        [plusButton.centerXAnchor constraintEqualToAnchor:plusContainerView.centerXAnchor],
        [plusButton.centerYAnchor constraintEqualToAnchor:plusContainerView.centerYAnchor]
    ]];
    [plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // 4. 在 firstPageView 中添加文本标签并保存引用以便动态更新
    self.mainTitleLabel = [self createCustomLabelWithText:self.pendantData.mainTitle fontSize:11 width:91 height:20 top:19 color:[UIColor whiteColor] parent:firstPageView];
    self.userNameLabel = [self createCustomLabelWithText:self.pendantData.userName fontSize:10 width:20 height:12 top:108 color:[UIColor whiteColor] parent:firstPageView];
    self.userTitleLabel = [self createCustomLabelWithText:self.pendantData.userTitle fontSize:10 width:70 height:12 top:122 color:[UIColor whiteColor] parent:firstPageView];
    // 第二页：箭头图标页面
    UIView *secondPageView = [[UIView alloc] initWithFrame:CGRectMake(pageWidth, 0, pageWidth, pageHeight)];
    secondPageView.backgroundColor = [UIColor clearColor]; // 改为透明背景，显示下层渐变
    secondPageView.layer.cornerRadius = 12;
    secondPageView.layer.masksToBounds = YES;
    [carouselScrollView addSubview:secondPageView];
    
    // 在 secondPageView 中添加容器视图
    UIView *arrowContainerView = [[UIView alloc] init];
    arrowContainerView.backgroundColor = [UIColor clearColor];
    [secondPageView addSubview:arrowContainerView];
    arrowContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置容器视图约束，填满整个 secondPageView
    [NSLayoutConstraint activateConstraints:@[
        [arrowContainerView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor],
        [arrowContainerView.trailingAnchor constraintEqualToAnchor:secondPageView.trailingAnchor],
        [arrowContainerView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor],
        [arrowContainerView.bottomAnchor constraintEqualToAnchor:secondPageView.bottomAnchor]
    ]];
    
    // 在容器视图中添加箭头图片
    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [arrowContainerView addSubview:arrowImageView];
    arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置箭头图片约束：Width: 38px, Height: 38px, Top: 45px, Left: 37px
    [NSLayoutConstraint activateConstraints:@[
        [arrowImageView.widthAnchor constraintEqualToConstant:38],
        [arrowImageView.heightAnchor constraintEqualToConstant:38],
        [arrowImageView.leadingAnchor constraintEqualToAnchor:arrowContainerView.leadingAnchor constant:37],
        [arrowImageView.topAnchor constraintEqualToAnchor:arrowContainerView.topAnchor constant:45]
    ]];
    // 创建第二页文本标签并保存引用以便动态更新
    self.challengeTitleLabel = [self createCustomLabelWithText:self.pendantData.challengeTitle fontSize:13 width:91 height:20 top:19 color:[UIColor whiteColor] parent:secondPageView];
    self.progressTextLabel = [self createCustomLabelWithText:self.pendantData.progressText fontSize:10 width:91 height:20 top:87 color:[UIColor whiteColor] parent:secondPageView];
    // 添加新的容器视图 (54x14，位于 top:107, left:14)
    UIView *progressContainerView = [[UIView alloc] init];
    progressContainerView.backgroundColor = [UIColor clearColor];
    [secondPageView addSubview:progressContainerView];
    progressContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置容器视图的约束
    [NSLayoutConstraint activateConstraints:@[
        [progressContainerView.widthAnchor constraintEqualToConstant:54],
        [progressContainerView.heightAnchor constraintEqualToConstant:14],
        [progressContainerView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor constant:107],
        [progressContainerView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor constant:14]
    ]];
    // 在容器内添加渐变视图
    UIView *gradientView = [[UIView alloc] init];
    gradientView.layer.cornerRadius = 5; // 设置圆角为高度的一半（10÷2=5）
    gradientView.layer.masksToBounds = YES;
    [progressContainerView addSubview:gradientView];
    gradientView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置渐变视图的约束（宽54px、高10px，在容器内垂直居中）
    [NSLayoutConstraint activateConstraints:@[
        [gradientView.widthAnchor constraintEqualToConstant:54],
        [gradientView.heightAnchor constraintEqualToConstant:10],
        [gradientView.centerXAnchor constraintEqualToAnchor:progressContainerView.centerXAnchor],
        [gradientView.centerYAnchor constraintEqualToAnchor:progressContainerView.centerYAnchor]
    ]];
    
    // 创建渐变层
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, 54, 10);
    gradientLayer.cornerRadius = 5; // 保持与视图相同的圆角
    // 设置渐变色从左到右 (从 rgba(255, 188, 125, 1) 到 rgba(255, 245, 220, 1))
    gradientLayer.colors = @[
        (__bridge id)[UIColor colorWithRed:255.0/255.0 green:188.0/255.0 blue:125.0/255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:255.0/255.0 green:245.0/255.0 blue:220.0/255.0 alpha:1.0].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5); // 左侧中点
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);   // 右侧中点
    
    // 将渐变层添加到渐变视图
    [gradientView.layer addSublayer:gradientLayer];
    
    // 在progressContainerView中添加fire图片
    UIImageView *fireImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fire"]];
    fireImageView.contentMode = UIViewContentModeScaleAspectFit;
    [progressContainerView addSubview:fireImageView];
    fireImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置fire图片的约束 (Width: 43.75px, Height: 14px, Top: 0px, Left: 10px)
    [NSLayoutConstraint activateConstraints:@[
        [fireImageView.widthAnchor constraintEqualToConstant:43.75],
        [fireImageView.heightAnchor constraintEqualToConstant:14],
        [fireImageView.topAnchor constraintEqualToAnchor:progressContainerView.topAnchor constant:0],
        [fireImageView.leadingAnchor constraintEqualToAnchor:progressContainerView.leadingAnchor constant:10]
    ]];
    self.rewardTextLabel = [self createCustomLabelWithText:self.pendantData.rewardText
                                               fontSize:10
                                                  width:91
                                                 height:20
                                                    top:125
                                                  color:[UIColor colorWithRed:255.0/255.0 green:233.0/255.0 blue:190.0/255.0 alpha:1.0]
                                                 parent:secondPageView];
    // 详细注释：
    // carouselScrollView 为轮播控件，支持左右滑动分页
    // 首页为原有内容，左划后显示同尺寸同圆角的箭头图标页面
    // 2.3 在 carouselScrollView 下方添加 UIPageControl 作为页码指示器
    // 这个小圆点就是页面指示器，用来显示当前是第几页，以及总共有多少页。
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 2; // 总页数
    self.pageControl.currentPage = 0; // 当前页码
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.3]; // 未选中页的圆点颜色
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor]; // 选中页的圆点颜色
    self.pageControl.userInteractionEnabled = NO; // 禁止用户通过点击来切换页面
    [containerView addSubview:self.pageControl]; // 添加到容器视图中
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    // 仅使用 transform 进行大小缩放。
    self.pageControl.transform = CGAffineTransformMakeScale(0.6, 0.6);

    // 对于bottomAnchor，正值会使视图向下移动
    [NSLayoutConstraint activateConstraints:@[
        [self.pageControl.centerXAnchor constraintEqualToAnchor:gradientBackgroundView.centerXAnchor],
        [self.pageControl.bottomAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor constant:7]
    ]];
    // 设置UIScrollView的代理为当前视图控制器，以便监听滚动事件
    // 需在 ViewController.h 或 .m 的 @interface 中声明遵从 <UIScrollViewDelegate> 协议
    carouselScrollView.delegate = self;

    // 3. 创建 bottomBarView 底部栏
    // 这是位于挂件主体下方的深色条状视图。
    UIView *bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 112, 20)];
    bottomBarView.layer.backgroundColor = [UIColor colorWithRed:0.253 green:0.118 blue:0.012 alpha:1].CGColor;
    // 设置整体圆滑（全圆角），不改变尺寸
    bottomBarView.layer.cornerRadius = 10; // 高度的一半，使其两端呈圆形
    bottomBarView.layer.masksToBounds = YES;
    [containerView addSubview:bottomBarView];
    bottomBarView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 bottomBarView 尺寸和位置
    [NSLayoutConstraint activateConstraints:@[
        [bottomBarView.widthAnchor constraintEqualToConstant:112],
        [bottomBarView.heightAnchor constraintEqualToConstant:20],
        // 关键约束：顶部紧贴gradientBackgroundView的底部
        [bottomBarView.topAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor constant:1],
        [bottomBarView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor]
    ]];
    // 4. 在 bottomBarView 内部居中添加文字标签
    self.eventTitleLabel = [self createCustomLabelWithText:self.pendantData.eventTitle fontSize:10 width:93 height:14 top:3.5 color:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] parent:bottomBarView];
    // 详细注释：
    // titleLabel 宽度等于 bottomBarView，内容左右居中，垂直居中
    // 在 bottomBarView 中添加 play 图标
    UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play"]];
    playImageView.contentMode = UIViewContentModeScaleAspectFit;
    [bottomBarView addSubview:playImageView];
    playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：定义图标大小(11x11)，并将其定位在底部栏的右侧区域
    [NSLayoutConstraint activateConstraints:@[
        [playImageView.widthAnchor constraintEqualToConstant:11],
        [playImageView.heightAnchor constraintEqualToConstant:11],
        [playImageView.centerYAnchor constraintEqualToAnchor:bottomBarView.centerYAnchor], // 垂直居中
        [playImageView.leadingAnchor constraintEqualToAnchor:bottomBarView.leadingAnchor constant:95] // 距离左边95pt
    ]];
    // 详细注释：
    // playImageView为11x11，垂直居中，左侧距bottomBarView 95pt，显示play图标
}
// MARK: - 辅助方法 (Helper Methods)

/**
 * @brief 创建一个带有特定样式和颜色的UILabel
 * @param text 文本内容
 * @param fontSize 字体大小
 * @param width 标签宽度
 * @param height 标签高度
 * @param top 距离父视图顶部的距离
 * @param textColor 文本颜色
 * @param parent 父视图
 * @return 配置好的UILabel实例
 */
- (UILabel *)createCustomLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize width:(CGFloat)width height:(CGFloat)height top:(CGFloat)top color:(UIColor *)textColor parent:(UIView *)parent {
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = textColor;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 0.86;
    style.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attr = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
        NSParagraphStyleAttributeName: style
    };
    label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attr];
    
    [parent addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        [label.widthAnchor constraintEqualToConstant:width],
        [label.heightAnchor constraintEqualToConstant:height],
        [label.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:parent.topAnchor constant:top]
    ]];
    return label;
}

// MARK: - 事件处理方法 (Event Handlers)

// 轮播区滑动时，联动更新pageControl
// 这是UIScrollViewDelegate协议中的方法，每当滚动视图的内容发生滚动时，就会被调用。
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width; // 获取一页的宽度
    // 计算当前页码：通过滚动偏移量除以页面宽度，并四舍五入得到最接近的页码
    NSInteger page = (NSInteger)(scrollView.contentOffset.x / pageWidth + 0.5);
    // 更新UIPageControl的当前页码
    self.pageControl.currentPage = page;
}
// plusButton点击事件，弹出提示框
// 当用户点击“+”号按钮时，此方法被调用。
- (void)plusButtonTapped:(UIButton *)sender {
    // 创建一个UIAlertController，样式为Alert
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"关注成功" preferredStyle:UIAlertControllerStyleAlert];
    // 创建一个“确定”按钮
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    // 将按钮添加到弹窗上
    [alert addAction:okAction];
    // 显示弹窗
    [self presentViewController:alert animated:YES completion:nil];
}
@end
