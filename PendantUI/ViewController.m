//
//  ViewController.m
//  PendantUI
//
//  Created by tim on 2025/7/17.
//

#import "ViewController.h"
// 遵从UIScrollViewDelegate协议，用于监听滚动视图事件
@interface ViewController () <UIScrollViewDelegate>

// 在 @interface ViewController () 内部添加 pageControl 属性
// @property: 定义一个属性，Xcode会自动生成getter和setter方法。
// nonatomic: 非原子性，性能更高，适用于单线程环境或已手动处理线程安全的UI对象。
// strong: 强引用，只要该指针存在，对象就不会被释放。这是ARC（自动引用计数）下的默认行为。
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation ViewController

// 工具方法：创建自定义UILabel
// 这是一个辅助方法，用于快速创建一个具有特定样式和布局的UILabel，提高了代码的复用性。
- (UILabel *)createCustomLabelWithText:(NSString *)text fontSize:(CGFloat)fontSize width:(CGFloat)width height:(CGFloat)height top:(CGFloat)top parent:(UIView *)parent {
    // 1. 初始化UILabel实例
    UILabel *label = [[UILabel alloc] init];
    // 2. 设置文本居中对齐
    label.textAlignment = NSTextAlignmentCenter;
    // 3. 设置文本颜色为白色
    label.textColor = [UIColor whiteColor];
    // 4. 设置段落样式，用于调整行高等富文本属性
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 0.86; // 设置行高倍数
    style.alignment = NSTextAlignmentCenter; // 再次确保文本居中
    // 5. 将字体和段落样式打包成一个属性字典
    NSDictionary *attr = @{
        NSFontAttributeName: [UIFont systemFontOfSize:fontSize],
        NSParagraphStyleAttributeName: style
    };
    // 6. 创建并设置UILabel的富文本（Attributed String）
    label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attr];
    // 7. 禁用自动转换AutoresizingMask为约束，以便使用Auto Layout
    label.translatesAutoresizingMaskIntoConstraints = NO;
    // 8. 将标签添加到指定的父视图
    [parent addSubview:label];
    // 9. 激活Auto Layout约束，定义标签的位置和大小
    [NSLayoutConstraint activateConstraints:@[
        [label.widthAnchor constraintEqualToConstant:width],      // 设置宽度
        [label.heightAnchor constraintEqualToConstant:height],   // 设置高度
        [label.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor], // 水平居中于父视图
        [label.topAnchor constraintEqualToAnchor:parent.topAnchor constant:top] // 与父视图顶部的距离
    ]];
    return label;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // viewDidLoad 是视图控制器生命周期中的一个重要方法。当视图控制器的视图被加载到内存后，系统会调用此方法。
    // 这里是执行UI初始化和一次性设置的最佳位置。

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
    [gradientBackgroundView addSubview:carouselScrollView]; // 添加到渐变背景上
    carouselScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：使其完全填满 gradientBackgroundView
    [NSLayoutConstraint activateConstraints:@[
        [carouselScrollView.leadingAnchor constraintEqualToAnchor:gradientBackgroundView.leadingAnchor],
        [carouselScrollView.trailingAnchor constraintEqualToAnchor:gradientBackgroundView.trailingAnchor],
        [carouselScrollView.topAnchor constraintEqualToAnchor:gradientBackgroundView.topAnchor],
        [carouselScrollView.bottomAnchor constraintEqualToAnchor:gradientBackgroundView.bottomAnchor]
    ]];
    // 添加两个页面：第一页为原有内容，第二页为纯色方块
    CGFloat pageWidth = 111; // 页面宽度
    CGFloat pageHeight = 151; // 页面高度
    carouselScrollView.contentSize = CGSizeMake(pageWidth * 2, pageHeight); // 设置可滚动区域的总大小
    // 首页内容（可放置原有内容或留空）
    UIView *firstPageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
    firstPageView.backgroundColor = [UIColor clearColor]; // 保持透明，这样能看到下层的gradientBackgroundView
    [carouselScrollView addSubview:firstPageView];
    // 第二页：纯色方块
    UIView *secondPageView = [[UIView alloc] initWithFrame:CGRectMake(pageWidth, 0, pageWidth, pageHeight)];
    secondPageView.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]; // 示例纯色
    secondPageView.layer.cornerRadius = 12;
    secondPageView.layer.masksToBounds = YES;
    [carouselScrollView addSubview:secondPageView];
    // 详细注释：
    // carouselScrollView 为轮播控件，支持左右滑动分页
    // 首页为原有内容，左划后显示同尺寸同圆角的纯色方块
    // 2.3 在 carouselScrollView 下方添加 UIPageControl 作为页码指示器
    // 这个小圆点就是页面指示器，用来显示当前是第几页，以及总共有多少页。
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = 2; // 总页数
    self.pageControl.currentPage = 0; // 当前页码
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.3]; // 未选中页的圆点颜色
    self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor]; // 选中页的圆点颜色
    self.pageControl.userInteractionEnabled = NO; // 禁止用户通过点击来切换页面
    [gradientBackgroundView addSubview:self.pageControl]; // 添加到背景视图上
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
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 93, 14)];
    titleLabel.textColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:10];
    titleLabel.text = @"2024秋季盛典";
    // 通过设置段落样式来精确控制行高，确保垂直居中
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = 14;
    style.maximumLineHeight = 14;
    titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleLabel.text attributes:@{NSParagraphStyleAttributeName: style}];
    titleLabel.textAlignment = NSTextAlignmentCenter; // 确保文本内容在UILabel内部水平居中
    [bottomBarView addSubview:titleLabel];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：宽度等于 bottomBarView，使其在底部栏内部垂直和水平居中
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.widthAnchor constraintEqualToAnchor:bottomBarView.widthAnchor],
        [titleLabel.heightAnchor constraintEqualToConstant:14],
        [titleLabel.centerXAnchor constraintEqualToAnchor:bottomBarView.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:bottomBarView.centerYAnchor]
    ]];
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
    // 在 containerView 中新增头像容器 profileContainerView，位于 component2ImageView 上层
    // 这个容器用于包裹头像和加号按钮，方便整体定位
    UIView *profileContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41.14, 48.57)];
    profileContainerView.backgroundColor = [UIColor clearColor];
    [containerView addSubview:profileContainerView];
    [containerView bringSubviewToFront:profileContainerView]; // 保证在 component2ImageView 上层
    profileContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：精确定位头像容器的位置
    [NSLayoutConstraint activateConstraints:@[
        [profileContainerView.widthAnchor constraintEqualToConstant:41.14],
        [profileContainerView.heightAnchor constraintEqualToConstant:48.57],
        [profileContainerView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:35],
        [profileContainerView.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:56.43]
    ]];
    // 在 profileContainerView 内添加圆形头像
    UIImageView *profileImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile"]];
    profileImageView.contentMode = UIViewContentModeScaleAspectFill; // 填充模式，可能会裁剪图片
    profileImageView.clipsToBounds = YES; // 裁剪超出边界的内容
    [profileContainerView addSubview:profileImageView];
    profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：定义头像图片的大小和位置
    [NSLayoutConstraint activateConstraints:@[
        [profileImageView.widthAnchor constraintEqualToConstant:41.14],
        [profileImageView.heightAnchor constraintEqualToConstant:41.14],
        [profileImageView.centerXAnchor constraintEqualToAnchor:profileContainerView.centerXAnchor],
        [profileImageView.topAnchor constraintEqualToAnchor:profileContainerView.topAnchor]
    ]];
    // 设置圆形和描边效果
    profileImageView.layer.cornerRadius = 41.14 / 2.0; // 半径设为宽度的一半，形成圆形
    profileImageView.layer.masksToBounds = YES; // 确保圆形裁剪生效
    profileImageView.layer.borderWidth = 1.0; // 描边宽度
    profileImageView.layer.borderColor = [UIColor colorWithRed:1 green:0.887 blue:0.717 alpha:1].CGColor; // 描边颜色
    // 详细注释：
    // profileContainerView 作为头像父容器，无背景色，内部图片为圆形，带1pt描边，描边色为RGB(1,0.887,0.717)
    // 在 profileContainerView 中添加 12x12 的 plus 容器视图
    // 这个小容器用于包裹加号图标和其点击区域
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
    // 约束：让“+”号图片填满其父容器 `plusContainerView`
    [NSLayoutConstraint activateConstraints:@[
        [plusImageView.leadingAnchor constraintEqualToAnchor:plusContainerView.leadingAnchor],
        [plusImageView.trailingAnchor constraintEqualToAnchor:plusContainerView.trailingAnchor],
        [plusImageView.topAnchor constraintEqualToAnchor:plusContainerView.topAnchor],
        [plusImageView.bottomAnchor constraintEqualToAnchor:plusContainerView.bottomAnchor]
    ]];
    // 详细注释：
    // plusContainerView 为12x12，父视图为profileContainerView，水平居中，顶部距父视图93，内部plus图片填满，且在profile图片上层

    // 在 plusContainerView 中心添加透明按钮，14x14
    // 为了扩大点击区域，使用一个比图标本身(12x12)稍大的透明按钮(14x14)。
    UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    plusButton.backgroundColor = [UIColor clearColor]; // 透明背景
    plusButton.translatesAutoresizingMaskIntoConstraints = NO;
    [plusContainerView addSubview:plusButton];
    // 约束：宽高14，中心与 plusContainerView 重合
    [NSLayoutConstraint activateConstraints:@[
        [plusButton.widthAnchor constraintEqualToConstant:14],
        [plusButton.heightAnchor constraintEqualToConstant:14],
        [plusButton.centerXAnchor constraintEqualToAnchor:plusContainerView.centerXAnchor],
        [plusButton.centerYAnchor constraintEqualToAnchor:plusContainerView.centerYAnchor]
    ]];
    // 添加点击事件，当按钮被点击时，调用 `plusButtonTapped:` 方法
    [plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    // 详细注释：
    // plusButton 为14x14透明按钮，覆盖plusContainerView中心，点击弹出提示框
    // 使用之前创建的工具方法，快速添加几个文本标签
    // 创建“沾沾”标签
    [self createCustomLabelWithText:@"沾沾" fontSize:10 width:20 height:12 top:108 parent:containerView];
    // 创建“巅峰冠军”标签
    [self createCustomLabelWithText:@"巅峰冠军" fontSize:10 width:70 height:12 top:122 parent:containerView];
    // 创建“唱歌十强争夺”标签
    [self createCustomLabelWithText:@"唱歌十强争夺" fontSize:11 width:91 height:20 top:19 parent:containerView];
}

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
