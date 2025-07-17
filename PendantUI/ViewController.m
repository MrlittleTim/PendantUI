//
//  ViewController.m
//  PendantUI
//
//  Created by tim on 2025/7/17.
//

#import "ViewController.h"

@interface ViewController ()

// 在 @interface ViewController () 内部添加 pageControl 属性
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation ViewController

// 工具方法：创建自定义UILabel
- (UILabel *)createCustomLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize width:(CGFloat)width height:(CGFloat)height top:(CGFloat)top parent:(UIView *)parent {
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 0.86;
    style.alignment = NSTextAlignmentCenter;
    NSDictionary *attr = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
        NSParagraphStyleAttributeName: style
    };
    label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attr];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [parent addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.widthAnchor constraintEqualToConstant:width],
        [label.heightAnchor constraintEqualToConstant:height],
        [label.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:parent.topAnchor constant:top]
    ]];
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 在此处实现挂件UI demo
    // 1. 创建 containerView 作为逻辑容器（不可见，仅用于布局）
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor clearColor]; // 不可见
    [self.view addSubview:containerView];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 containerView 尺寸 112x172，居中
    [NSLayoutConstraint activateConstraints:@[
        [containerView.widthAnchor constraintEqualToConstant:112],
        [containerView.heightAnchor constraintEqualToConstant:172],
        [containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];

    // 2. 创建 gradientBackgroundView 视觉背景
    UIView *gradientBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 111, 151)];
    gradientBackgroundView.alpha = 0.88;
    gradientBackgroundView.layer.cornerRadius = 12;
    gradientBackgroundView.layer.masksToBounds = YES;
    // 添加渐变层
    CAGradientLayer *layer0 = [CAGradientLayer layer];
    layer0.colors = @[(__bridge id)[UIColor colorWithRed:0.354 green:0.229 blue:0.132 alpha:1].CGColor,
                      (__bridge id)[UIColor colorWithRed:0.326 green:0.167 blue:0.056 alpha:1].CGColor,
                      (__bridge id)[UIColor colorWithRed:0.191 green:0.07 blue:0 alpha:1].CGColor];
    layer0.locations = @[@0, @0.42, @0.83];
    layer0.startPoint = CGPointMake(0.25, 0.5);
    layer0.endPoint = CGPointMake(0.75, 0.5);
    // 仿射变换
    layer0.affineTransform = CGAffineTransformMake(-0.59, 1.02, -0.65, -0.29, 1.1, 0.15);
    // 设置渐变层大小和位置
    layer0.bounds = CGRectInset(gradientBackgroundView.bounds, -0.5 * gradientBackgroundView.bounds.size.width, -0.5 * gradientBackgroundView.bounds.size.height);
    layer0.position = CGPointMake(CGRectGetMidX(gradientBackgroundView.bounds), CGRectGetMidY(gradientBackgroundView.bounds));
    [gradientBackgroundView.layer addSublayer:layer0];
    [containerView addSubview:gradientBackgroundView];
    gradientBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 gradientBackgroundView 尺寸和位置
    [NSLayoutConstraint activateConstraints:@[
        [gradientBackgroundView.widthAnchor constraintEqualToConstant:111],
        [gradientBackgroundView.heightAnchor constraintEqualToConstant:151],
        [gradientBackgroundView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [gradientBackgroundView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor]
    ]];

    // 2.1 在 gradientBackgroundView 上方添加 Component2 图片
    UIImageView *component2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Component2"]];
    component2ImageView.contentMode = UIViewContentModeScaleAspectFit;
    [containerView addSubview:component2ImageView];
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
    UIScrollView *carouselScrollView = [[UIScrollView alloc] init];
    carouselScrollView.pagingEnabled = YES;
    carouselScrollView.showsHorizontalScrollIndicator = NO;
    carouselScrollView.showsVerticalScrollIndicator = NO;
    carouselScrollView.bounces = YES;
    carouselScrollView.layer.cornerRadius = 12;
    carouselScrollView.layer.masksToBounds = YES;
    [gradientBackgroundView addSubview:carouselScrollView];
    carouselScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：填满 gradientBackgroundView
    [NSLayoutConstraint activateConstraints:@[
        [carouselScrollView.leadingAnchor constraintEqualToAnchor:gradientBackgroundView.leadingAnchor],
        [carouselScrollView.trailingAnchor constraintEqualToAnchor:gradientBackgroundView.trailingAnchor],
        [carouselScrollView.topAnchor constraintEqualToAnchor:gradientBackgroundView.topAnchor],
        [carouselScrollView.bottomAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor]
    ]];
    // 添加两个页面：第一页为原有内容，第二页为纯色方块
    CGFloat pageWidth = 111;
    CGFloat pageHeight = 151;
    carouselScrollView.contentSize = CGSizeMake(pageWidth * 2, pageHeight);
    // 首页内容（可放置原有内容或留空）
    UIView *firstPageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
    firstPageView.backgroundColor = [UIColor clearColor]; // 保持透明，显示原有内容
    [carouselScrollView addSubview:firstPageView];
    // 第二页：纯色方块
    UIView *secondPageView = [[UIView alloc] initWithFrame:CGRectMake(pageWidth, 0, pageWidth, pageHeight)];
    secondPageView.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]; // 示例纯色
    secondPageView.layer.cornerRadius = 12;
    secondPageView.layer.masksToBounds = YES;
    [carouselScrollView addSubview:secondPageView];
    // 详细注释：
    // carouselScrollView 为轮播控件，支持左右滑动分页
    // 首页为原有内容，左划后显示同尺寸同圆角的纯色方块写·

    // 2.3 在 carouselScrollView 下方添加 UIPageControl 作为页码指示器
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 2;
    self.pageControl.currentPage = 0;
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.3]; // 非当前页为浅色
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor]; // 当前页为白色
    self.pageControl.userInteractionEnabled = NO; // 禁止手动点击
    [gradientBackgroundView addSubview:self.pageControl];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageControl.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.6, 0.6), CGAffineTransformMakeTranslation(0, 15));
    // 约束：居中于 gradientBackgroundView 底部，距离底部8pt
    [NSLayoutConstraint activateConstraints:@[
        [self.pageControl.centerXAnchor constraintEqualToAnchor:gradientBackgroundView.centerXAnchor],
        [self.pageControl.bottomAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor constant:-8]
    ]];
    
    // 需在 ViewController.h 声明 <UIScrollViewDelegate> 并设置代理
    carouselScrollView.delegate = (id<UIScrollViewDelegate>)self;

    // 3. 创建 bottomBarView 底部栏
    UIView *bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 112, 20)];
    bottomBarView.layer.backgroundColor = [UIColor colorWithRed:0.253 green:0.118 blue:0.012 alpha:1].CGColor;
    // 设置整体圆滑（全圆角），不改变尺寸
    bottomBarView.layer.cornerRadius = 10; // 高度一半，形成圆滑条状
    bottomBarView.layer.masksToBounds = YES;
    [containerView addSubview:bottomBarView];
    bottomBarView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 bottomBarView 尺寸和位置
    [NSLayoutConstraint activateConstraints:@[
        [bottomBarView.widthAnchor constraintEqualToConstant:112],
        [bottomBarView.heightAnchor constraintEqualToConstant:20],
        [bottomBarView.topAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor constant:0],
        [bottomBarView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor]
    ]];

    // 4. 在 bottomBarView 内部居中添加文字标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 93, 14)];
    titleLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:10];
    titleLabel.text = @"2024秋季盛典";
    // 设置行高为14pt（与高度一致）
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = 14;
    style.maximumLineHeight = 14;
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleLabel.text attributes:@{NSParagraphStyleAttributeName: style}];
    // 关键：设置 textAlignment，确保内容水平居中
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [bottomBarView addSubview:titleLabel];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：宽度等于 bottomBarView，底部栏内部垂直居中、水平居中
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.widthAnchor constraintEqualToAnchor:bottomBarView.widthAnchor],
        [titleLabel.heightAnchor constraintEqualToConstant:14],
        [titleLabel.centerXAnchor constraintEqualToAnchor:bottomBarView.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:bottomBarView.centerYAnchor]
    ]];
    // 详细注释：
    // titleLabel 宽度等于 bottomBarView，内容左右居中，垂直居中

    // 在 containerView 中新增头像容器 profileContainerView，位于 component2ImageView 上层
    UIView *profileContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41.14, 48.57)];
    profileContainerView.backgroundColor = [UIColor clearColor];
    [containerView addSubview:profileContainerView];
    [containerView bringSubviewToFront:profileContainerView]; // 保证在 component2ImageView 上层
    profileContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：左侧对齐 containerView 左侧，向右偏移35，顶部距离 containerView 顶部56.43
    [NSLayoutConstraint activateConstraints:@[
        [profileContainerView.widthAnchor constraintEqualToConstant:41.14],
        [profileContainerView.heightAnchor constraintEqualToConstant:48.57],
        [profileContainerView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:35],
        [profileContainerView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:56.43]
    ]];
    // 在 profileContainerView 内添加圆形头像
    UIImageView *profileImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile"]];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.clipsToBounds = YES;
    [profileContainerView addSubview:profileImageView];
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：宽高均为41.14，居中于 profileContainerView 顶部
    [NSLayoutConstraint activateConstraints:@[
        [profileImageView.widthAnchor constraintEqualToConstant:41.14],
        [profileImageView.heightAnchor constraintEqualToConstant:41.14],
        [profileImageView.centerXAnchor constraintEqualToAnchor:profileContainerView.centerXAnchor],
        [profileImageView.topAnchor constraintEqualToAnchor:profileContainerView.topAnchor]
    ]];
    // 设置圆形和描边
    profileImageView.layer.cornerRadius = 41.14/2.0;
    profileImageView.layer.masksToBounds = YES;
    profileImageView.layer.borderWidth = 1.0;
    profileImageView.layer.borderColor = [UIColor colorWithRed:1 green:0.887 blue:0.717 alpha:1].CGColor;
    // 详细注释：
    // profileContainerView 作为头像父容器，无背景色，内部图片为圆形，带1pt描边，描边色为RGB(1,0.887,0.717)

    // 在 profileContainerView 中添加 12x12 的 plus 容器视图
    UIView *plusContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    plusContainerView.backgroundColor = [UIColor clearColor];
    [profileContainerView addSubview:plusContainerView];
    [profileContainerView bringSubviewToFront:plusContainerView]; // 保证在 profileImageView 上层
    plusContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：宽高12，水平居中，顶部距离 containerView 顶部93
    [NSLayoutConstraint activateConstraints:@[
        [plusContainerView.widthAnchor constraintEqualToConstant:12],
        [plusContainerView.heightAnchor constraintEqualToConstant:12],
        [plusContainerView.centerXAnchor constraintEqualToAnchor:profileContainerView.centerXAnchor],
        [plusContainerView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:93]
    ]];
    // 在 plusContainerView 中添加 plus 图片
    UIImageView *plusImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus"]];
    plusImageView.contentMode = UIViewContentModeScaleAspectFit;
    plusImageView.clipsToBounds = YES;
    [plusContainerView addSubview:plusImageView];
    plusImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：填满 plusContainerView
    [NSLayoutConstraint activateConstraints:@[
        [plusImageView.leadingAnchor constraintEqualToAnchor:plusContainerView.leadingAnchor],
        [plusImageView.trailingAnchor constraintEqualToAnchor:plusContainerView.trailingAnchor],
        [plusImageView.topAnchor constraintEqualToAnchor:plusContainerView.topAnchor],
        [plusImageView.bottomAnchor constraintEqualToAnchor:plusContainerView.bottomAnchor]
    ]];
    // 详细注释：
    // plusContainerView 为12x12，父视图为profileContainerView，水平居中，顶部距父视图93，内部plus图片填满，且在profile图片上层

    // 在 plusContainerView 中心添加透明按钮，14x14
    UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    plusButton.backgroundColor = [UIColor clearColor];
    plusButton.translatesAutoresizingMaskIntoConstraints = NO;
    [plusContainerView addSubview:plusButton];
    // 约束：宽高14，中心与 plusContainerView 重合
    [NSLayoutConstraint activateConstraints:@[
        [plusButton.widthAnchor constraintEqualToConstant:14],
        [plusButton.heightAnchor constraintEqualToConstant:14],
        [plusButton.centerXAnchor constraintEqualToAnchor:plusContainerView.centerXAnchor],
        [plusButton.centerYAnchor constraintEqualToAnchor:plusContainerView.centerYAnchor]
    ]];
    // 添加点击事件，弹出提示框
    [plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // 详细注释：
    // plusButton 为14x14透明按钮，覆盖plusContainerView中心，点击弹出提示框

    // 已移除shadowLabel相关所有代码，避免重复显示“唱歌十强争夺”
    // 创建“沾沾”标签
    [self createCustomLabelWithText:@"沾沾" fontSize:10 width:20 height:12 top:108 parent:containerView];
    // 创建“巅峰冠军”标签
    [self createCustomLabelWithText:@"巅峰冠军" fontSize:10 width:70 height:12 top:122 parent:containerView];
    // 创建“唱歌十强争夺”标签
    [self createCustomLabelWithText:@"唱歌十强争夺" fontSize:11 width:91 height:20 top:19 parent:containerView];
}


// plusButton点击事件，弹出提示框
- (void)plusButtonTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"关注成功" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
