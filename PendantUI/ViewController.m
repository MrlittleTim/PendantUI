//
//  ViewController.m
//  PendantUI
//
//  Created by tim on 2025/7/17.
//

#import "ViewController.h"
// MARK: - 数据模型 (Data Model)
/**
 * @brief 挂件数据模型 - 核心数据结构定义
 * @discussion 这个数据模型采用面向对象设计，封装了从服务器获取的所有文本信息
 * 
 * 设计原则：
 * 1. 单一职责：专门负责数据存储，不包含业务逻辑
 * 2. 数据完整性：包含UI显示所需的所有数据字段
 * 3. 类型安全：使用强类型属性，避免运行时错误
 * 4. 内存管理：使用strong引用确保数据不被意外释放
 * 
 * 属性说明：
 * - strong修饰符：创建强引用，对象不会被自动释放
 * - NSString*：不可变字符串，线程安全
 * - CGFloat：跨平台的浮点数类型，适用于图形相关计算
 */
// 定义数据模型来存储从服务器获取的文本信息
@interface PendantDataModel : NSObject
@property (nonatomic, strong) NSString *mainTitle;      // 第一页主标题 - 显示在轮播第一页顶部
@property (nonatomic, strong) NSString *userName;       // 用户名 - 显示在头像下方
@property (nonatomic, strong) NSString *userTitle;      // 用户头衔 - 显示用户等级或称号
@property (nonatomic, strong) NSString *challengeTitle; // 挑战标题 - 第二页的主要标题
@property (nonatomic, strong) NSString *progressText;   // 进度描述文本 - 显示当前进度状态
@property (nonatomic, strong) NSString *rewardText;     // 奖励文本 - 显示奖励相关信息
@property (nonatomic, strong) NSString *eventTitle;     // 活动标题 - 显示在底部栏
@property (nonatomic, assign) CGFloat progressValue;    // 进度数值 - 范围0.0到1.0，用于进度条显示
@end
@implementation PendantDataModel
// 空实现 - 使用默认的getter/setter方法
// Objective-C会自动生成属性的访问器方法
@end

// MARK: - 网络配置常量 (Network Configuration Constants)
/**
 * @brief 网络请求相关常量定义
 * @discussion 使用静态常量的优势：
 * 1. 编译时确定：常量在编译时就确定值，运行时效率高
 * 2. 内存优化：全局共享，不会重复创建
 * 3. 类型安全：编译器可以进行类型检查
 * 4. 维护便利：统一管理，修改时只需改一处
 * 
 * const关键字的作用：
 * - 声明常量，运行时不可修改
 * - 编译器优化：可以进行常量折叠等优化
 * - 防止意外修改：提高代码安全性
 */
static NSString * const kServerBaseURL = @"http://172.23.18.107:8080"; // 服务器基础URL - 包含协议、IP地址和端口
static NSString * const kPendantDataEndpoint = @"/pendant-data";        // 挂件数据API端点 - 获取界面显示数据
static NSString * const kStatusEndpoint = @"/status";                   // 服务器状态端点 - 检查服务器运行状态

/**
 * @brief 主视图控制器类扩展 - 私有属性和协议声明
 * @discussion 使用类扩展的优势：
 * 1. 封装性：私有属性和方法不暴露给外部
 * 2. 协议遵循：声明遵循UIScrollViewDelegate协议
 * 3. 编译检查：编译器可以检查协议方法的实现
 */
// 遵从UIScrollViewDelegate协议，用于监听滚动视图事件
@interface ViewController () <UIScrollViewDelegate>

// MARK: - UI控件属性 (UI Component Properties)
@property (nonatomic, strong) UIPageControl *pageControl; // 页面指示器 - 显示当前页面和总页数

// MARK: - 网络数据相关属性 (Network Data Properties)
/**
 * @brief 网络和数据管理属性
 * @discussion 属性设计说明：
 * 
 * pendantData (数据模型实例)：
 * - 作用：存储从服务器获取并解析后的业务数据
 * - 生命周期：与视图控制器同步，应用运行期间持续存在
 * - 线程安全：主要在主线程访问，更新前会切换到主线程
 * 
 * networkSession (网络会话对象)：
 * - 作用：管理所有HTTP网络请求的执行
 * - 优势：复用连接、支持后台传输、线程安全
 * - 配置：包含超时设置、缓存策略等网络行为控制
 */
@property (nonatomic, strong) PendantDataModel *pendantData;  // 数据模型实例 - 存储业务数据
@property (nonatomic, strong) NSURLSession *networkSession;   // 网络会话对象 - 管理HTTP请求

// MARK: - UI元素引用 (UI Element References)
/**
 * @brief 动态UI元素的强引用属性
 * @discussion 保存UI标签引用的设计目的：
 * 1. 动态更新：网络数据更新时能快速定位并更新对应UI元素
 * 2. 性能优化：避免使用tag查找或视图遍历的开销
 * 3. 类型安全：编译时确保类型正确，运行时避免类型转换
 * 4. 代码可读性：明确标识可动态更新的UI元素
 * 
 * 命名规范：
 * - 使用描述性名称，清晰表达用途
 * - 统一使用Label后缀，表明UI元素类型
 */
// UI元素引用，用于动态更新
@property (nonatomic, strong) UILabel *mainTitleLabel;     // 主标题标签引用 - 第一页顶部标题
@property (nonatomic, strong) UILabel *userNameLabel;      // 用户名标签引用 - 头像下方用户名
@property (nonatomic, strong) UILabel *userTitleLabel;     // 用户头衔标签引用 - 用户等级称号
@property (nonatomic, strong) UILabel *challengeTitleLabel; // 挑战标题标签引用 - 第二页主标题
@property (nonatomic, strong) UILabel *progressTextLabel;  // 进度文本标签引用 - 进度描述信息
@property (nonatomic, strong) UILabel *rewardTextLabel;    // 奖励文本标签引用 - 奖励相关信息
@property (nonatomic, strong) UILabel *eventTitleLabel;    // 活动标题标签引用 - 底部栏活动名称

@end

@implementation ViewController

// MARK: - 生命周期方法 (Lifecycle Methods)

/**
 * @brief 视图控制器生命周期 - 视图加载完成后的初始化
 * @discussion viewDidLoad在视图控制器生命周期中的作用：
 * 
 * 调用时机：
 * - 视图层次结构加载到内存后立即调用
 * - 只调用一次，适合进行一次性的初始化操作
 * - 此时视图的bounds可能还未确定，不适合依赖尺寸的操作
 * 
 * 初始化顺序的重要性：
 * 1. setupNetworking: 配置网络环境，为后续数据获取做准备
 * 2. setupUI: 创建用户界面，建立视图层次结构
 * 3. fetchPendantData: 发起网络请求，获取动态数据更新UI
 * 
 * 这种顺序确保了：
 * - 网络配置在使用前完成
 * - UI界面在数据更新前创建完成
 * - 避免了组件间的依赖冲突
 */
- (void)viewDidLoad {
    [super viewDidLoad]; // 调用父类实现，确保基础功能正常
    
    // 1. 初始化网络功能 - 配置NSURLSession和默认数据
    [self setupNetworking];
    
    // 2. 初始化UI界面 - 创建视图层次结构和布局约束
    [self setupUI];
    // 3. 获取服务器数据 - 发起异步网络请求更新界面内容
    [self fetchPendantData];
}

// MARK: - 网络配置与数据获取 (Network Configuration and Data Fetching)

/**
 * @brief 设置网络配置和初始化数据模型
 * @discussion 网络配置的核心要素：
 * 
 * NSURLSessionConfiguration详解：
 * 1. defaultSessionConfiguration - 标准配置，支持完整功能：
 *    - 磁盘缓存：缓存响应数据，提高性能
 *    - Cookie管理：自动处理HTTP Cookie
 *    - 认证支持：支持各种HTTP认证机制
 *    - 代理设置：遵循系统代理配置
 * 
 * 超时设置的策略考虑：
 * - timeoutIntervalForRequest (10秒)：单个请求的超时时间
 *   * 包括建立连接、发送请求、接收响应头的时间
 *   * 10秒是移动应用的合理设置，平衡用户体验和网络容忍度
 * - timeoutIntervalForResource (30秒)：整个资源传输的超时时间
 *   * 包括可能的重定向、完整数据传输的总时间
 *   * 30秒适用于较大文件或网络不稳定的情况
 * 
 * 默认数据的防御性编程：
 * - 目的：确保即使网络失败，应用也有内容显示
 * - 原则：提供有意义的默认值，而不是空字符串或nil
 * - 好处：提升用户体验，避免界面空白或崩溃
 */
- (void)setupNetworking {
    /*
     * NSURLSession配置对象创建：
     * defaultSessionConfiguration创建标准配置，具有以下特性：
     * 1. 支持HTTP/HTTPS协议
     * 2. 自动处理重定向
     * 3. 支持HTTP/2协议
     * 4. 线程安全的会话管理
     */
    // 配置NSURLSession - 创建网络会话配置对象
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    /*
     * 超时参数配置的技术细节：
     * 
     * timeoutIntervalForRequest：
     * - 作用范围：从发送请求到收到响应头的时间
     * - 超时后果：触发NSURLErrorTimedOut错误
     * - 选择依据：移动网络环境下的合理等待时间
     * 
     * timeoutIntervalForResource：
     * - 作用范围：整个HTTP事务的总时间限制
     * - 包含内容：DNS解析、TCP连接、HTTP传输、数据接收
     * - 应用场景：防止长时间占用网络资源
     */
    config.timeoutIntervalForRequest = 10.0; // 请求超时10秒 - 单次HTTP请求的最大等待时间
    config.timeoutIntervalForResource = 30.0; // 资源超时30秒 - 完整资源传输的最大时间限制
    
    /*
     * NSURLSession实例创建：
     * sessionWithConfiguration方法创建会话实例，具有以下特性：
     * 1. 线程安全：可以在多个线程中安全使用
     * 2. 连接复用：自动管理HTTP连接池，提高效率
     * 3. 后台支持：支持应用进入后台时继续传输（需要额外配置）
     * 4. 内存管理：会话对象会持有配置的副本
     */
    self.networkSession = [NSURLSession sessionWithConfiguration:config];
    
    /*
     * 数据模型初始化 - 防御性编程的最佳实践：
     * 
     * 为什么需要默认数据？
     * 1. 用户体验：避免首次启动时界面空白
     * 2. 容错性：网络失败时应用仍能正常显示
     * 3. 开发调试：便于UI布局调试和视觉效果验证
     * 4. 渐进加载：先显示默认内容，再用网络数据替换
     * 
     * 默认值选择原则：
     * 1. 有意义：反映真实的业务场景
     * 2. 完整性：覆盖所有必要的数据字段
     * 3. 一致性：与服务器数据格式保持一致
     */
    // 初始化默认数据模型（作为网络请求失败时的备用数据）
    self.pendantData = [[PendantDataModel alloc] init];
    self.pendantData.mainTitle = @"唱歌十强争夺";        // 默认主标题
    self.pendantData.userName = @"沾沾";               // 默认用户名
    self.pendantData.userTitle = @"巅峰冠军";          // 默认用户头衔
    self.pendantData.challengeTitle = @"心愿挑战";     // 默认挑战标题
    self.pendantData.progressText = @"心愿值还差 50000"; // 默认进度文本
    self.pendantData.rewardText = @"玩法奖励抢先看 >";  // 默认奖励文本
    self.pendantData.eventTitle = @"2024秋季盛典";     // 默认活动标题
    self.pendantData.progressValue = 0.7;              // 默认进度值（70%）
    NSLog(@"🔧 网络配置完成，服务器地址: %@", kServerBaseURL);
}

/**
 * @brief 从服务器获取挂件数据 - 异步网络请求的完整实现
 * @discussion 这是iOS网络编程的核心方法，展示了现代异步网络请求的标准模式：
 * 
 * 网络请求的完整生命周期：
 * 1. URL构建和验证 - 确保请求地址正确
 * 2. 创建NSURLSessionDataTask - 配置请求任务
 * 3. 设置completion handler - 定义异步回调处理
 * 4. 启动任务执行 - resume()开始网络传输
 * 5. 等待异步响应 - 系统在后台线程处理网络IO
 * 6. 执行completion handler - 在后台线程处理响应
 * 7. 解析数据和错误处理 - 业务逻辑处理
 * 8. 切换到主线程更新UI - 保证UI操作的线程安全
 * 
 * 异步编程的优势：
 * - 非阻塞：网络请求不会冻结用户界面
 * - 高效：系统可以并行处理多个请求
 * - 响应性：用户可以继续操作界面
 * - 可扩展：支持并发请求和复杂的网络交互
 */
- (void)fetchPendantData {
    /*
     * URL构建阶段：
     * 
     * stringWithFormat的使用：
     * - 优点：简单直观，适合简单的URL拼接
     * - 缺点：不支持URL编码，不适合复杂参数
     * - 适用场景：固定端点的API调用
     * 
     * 对于复杂URL构建，推荐使用NSURLComponents：
     * NSURLComponents *components = [[NSURLComponents alloc] initWithString:kServerBaseURL];
     * components.path = kPendantDataEndpoint;
     * components.queryItems = queryItems; // 自动处理URL编码
     */
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kServerBaseURL, kPendantDataEndpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    
    /*
     * URL有效性验证：
     * NSURL的URLWithString方法在URL格式错误时返回nil
     * 常见的URL错误：
     * - 格式错误：缺少协议、非法字符等
     * - 编码问题：包含未编码的特殊字符
     * - 为空：字符串为nil或空字符串
     */
    if (!url) {
        NSLog(@"❌ 无效的服务器URL: %@", urlString);
        return; // 提前返回，避免使用无效URL
    }
    
    NSLog(@"🌐 正在从服务器获取数据: %@", urlString);
    
    /*
     * NSURLSessionDataTask创建和配置：
     * 
     * dataTaskWithURL:completionHandler: 方法详解：
     * 1. 自动创建GET请求（最常用的HTTP方法）
     * 2. 任务创建后处于suspended状态，需要调用resume启动
     * 3. completionHandler是核心回调机制
     * 
     * CompletionHandler的执行特性：
     * - 执行线程：后台队列（非主线程）
     * - 执行时机：网络请求完成时（成功或失败）
     * - 参数含义：
     *   * NSData *data: 服务器返回的原始字节数据
     *   * NSURLResponse *response: HTTP响应头信息
     *   * NSError *error: 网络传输层错误（不包括HTTP状态码错误）
     * 
     * 错误处理的层次结构：
     * 1. 网络传输错误：连接失败、超时、DNS解析失败等
     * 2. HTTP协议错误：状态码非200的响应
     * 3. 数据格式错误：JSON解析失败
     * 4. 业务逻辑错误：数据验证失败
     */
    // 创建数据任务 - 配置异步HTTP GET请求
    NSURLSessionDataTask *dataTask = [self.networkSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        /*
         * 第一层错误处理：网络传输层错误
         * 
         * error参数包含的错误类型：
         * - NSURLErrorTimedOut: 请求超时
         * - NSURLErrorNotConnectedToInternet: 无网络连接
         * - NSURLErrorCannotFindHost: DNS解析失败
         * - NSURLErrorCannotConnectToHost: 无法连接到主机
         * - NSURLErrorNetworkConnectionLost: 网络连接中断
         * 
         * 重要概念：HTTP状态码错误不会触发这个error
         * 例如：404、500等响应仍然是"成功的网络传输"
         */
        if (error) {
            NSLog(@"❌ 网络请求失败: %@", error.localizedDescription);
            
            /*
             * GCD (Grand Central Dispatch) 详解：
             * 
             * dispatch_async函数的工作机制：
             * 1. 异步派发：将代码块添加到指定队列，立即返回
             * 2. 队列选择：dispatch_get_main_queue()返回主队列
             * 3. 线程切换：从当前后台线程切换到主线程执行
             * 
             * 为什么必须切换到主线程？
             * 1. UIKit线程安全规则：所有UI操作必须在主线程进行
             * 2. 后台线程UI操作的后果：
             *    - 可能导致应用崩溃
             *    - 可能出现UI显示异常
             *    - 可能导致内存访问错误
             * 3. 苹果官方强制要求：UIKit不是线程安全的框架
             * 
             * GCD队列类型：
             * - 主队列 (Main Queue)：串行队列，在主线程执行，用于UI更新
             * - 全局并发队列 (Global Concurrent Queue)：并发执行，用于CPU密集任务
             * - 自定义队列：可以是串行或并发，用于特定业务逻辑
             * 
             * dispatch_async vs dispatch_sync：
             * - dispatch_async：异步执行，不阻塞当前线程
             * - dispatch_sync：同步执行，阻塞当前线程直到完成
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                /*
                 * 这个block将在主线程中执行：
                 * 1. 可以安全地进行UI操作
                 * 2. 可以安全地访问UIViewController的方法
                 * 3. 用户界面会立即响应错误提示
                 */
                [self showNetworkError:error];
            });
            return; // 提前返回，不继续处理响应数据
        }
        
        /*
         * 第二层错误处理：HTTP状态码验证
         * 
         * HTTP状态码分类：
         * - 1xx：信息性状态码（很少使用）
         * - 2xx：成功状态码（200 OK是最常见的）
         * - 3xx：重定向状态码（NSURLSession通常自动处理）
         * - 4xx：客户端错误（400参数错误、401未授权、404未找到）
         * - 5xx：服务器错误（500内部错误、503服务不可用）
         * 
         * NSHTTPURLResponse类型转换：
         * - NSURLResponse是基类，提供基础响应信息
         * - NSHTTPURLResponse是子类，提供HTTP特有的信息
         * - 只有HTTP/HTTPS请求才会返回NSHTTPURLResponse类型
         * - 类型转换是安全的，因为我们使用的是HTTP URL
         */
        // 检查HTTP响应状态 - 验证服务器响应状态码
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSLog(@"❌ 服务器响应错误，状态码: %ld", (long)httpResponse.statusCode);
            
            /*
             * 状态码错误也需要切换到主线程处理：
             * 原因同上，UI更新必须在主线程进行
             * 
             * 这种一致的错误处理模式：
             * 1. 保证了代码的可预测性
             * 2. 简化了错误处理逻辑
             * 3. 确保了用户体验的一致性
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showServerError:httpResponse.statusCode];
            });
            return;
        }
        
        /*
         * 第三层处理：JSON数据解析
         * 
         * NSJSONSerialization详解：
         * 1. 系统原生JSON解析器，性能优异
         * 2. 线程安全，可以在任意线程使用
         * 3. 支持多种JSON数据结构（对象、数组、基本类型）
         * 
         * JSONObjectWithData方法的特性：
         * - 输入：NSData类型的原始字节数据
         * - 输出：Foundation对象（NSDictionary、NSArray、NSString等）
         * - options：解析选项，0表示使用默认设置
         * - error：解析错误的输出参数
         * 
         * 解析失败的常见原因：
         * 1. 数据不是有效的JSON格式
         * 2. 字符编码问题（如服务器返回了GBK编码的数据）
         * 3. 数据不完整（网络传输中断）
         * 4. 服务器返回了HTML错误页面而不是JSON
         */
        // 解析JSON数据 - 将原始字节数据转换为Objective-C对象
        NSError *parseError;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        
        if (parseError) {
            NSLog(@"❌ JSON解析失败: %@", parseError.localizedDescription);
            return; // 解析失败时直接返回，继续使用默认数据
        }
        
        NSLog(@"✅ 成功获取服务器数据");
        NSLog(@"📄 数据内容: %@", jsonData);
        
        /*
         * 数据处理和UI更新的线程管理：
         * 
         * 再次使用dispatch_async的原因：
         * 1. 当前仍在后台线程中执行
         * 2. 即将进行的操作包含UI更新
         * 3. 数据模型更新可能触发KVO通知，影响UI
         * 
         * 批量操作的优势：
         * 将updateDataModel和updateUIWithNewData放在同一个dispatch_async中：
         * 1. 原子性：两个操作在主线程中连续执行，避免中间状态
         * 2. 性能：减少线程切换的开销
         * 3. 一致性：确保数据和UI的同步更新
         * 
         * 执行顺序的重要性：
         * 1. updateDataModel：先更新内存中的数据模型
         * 2. updateUIWithNewData：再根据新数据更新UI显示
         * 这个顺序确保UI显示的数据是最新的
         */
        // 在主线程更新UI - 切换到主线程执行数据更新和界面刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            /*
             * 主线程中的批量操作：
             * 1. 更新数据模型：将JSON数据映射到本地数据结构
             * 2. 更新UI显示：将新数据反映到用户界面上
             * 
             * 这两个操作都必须在主线程执行：
             * - updateDataModel：可能触发KVO通知，影响UI
             * - updateUIWithNewData：直接操作UIKit组件
             */
            [self updateDataModel:jsonData];     // 更新本地数据模型
            [self updateUIWithNewData];          // 更新用户界面显示
        });
    }];
    
    /*
     * 网络任务启动：
     * 
     * resume方法的重要性：
     * 1. NSURLSessionDataTask创建后处于suspended（暂停）状态
     * 2. 必须调用resume方法才能开始执行网络请求
     * 3. 这种设计允许在启动前进行额外的配置
     *
     * 任务状态管理：
     * - 创建：suspended状态
     * - 启动：调用resume，变为running状态
     * - 完成：调用completion handler，变为completed状态
     * - 取消：可以调用cancel方法提前终止
     * 
     * 这种延迟启动的设计优势：
     * 1. 灵活性：可以在启动前修改请求配置
     * 2. 控制性：可以根据条件决定是否启动请求
     * 3. 批量管理：可以创建多个任务后统一启动
     */
    [dataTask resume]; // 启动网络任务 - 从suspended状态转为running状态
}

/**
 * @brief 更新数据模型 - 将JSON数据安全地映射到本地数据结构
 * @param jsonData 从服务器解析得到的JSON数据字典
 * @discussion 数据映射的安全性策略：
 *
 * 防御性编程的核心原则：
 * 1. 永远不要信任外部数据：服务器数据可能不完整或格式错误
 * 2. 提供合理的默认值：确保应用在任何情况下都能正常工作
 * 3. 进行类型检查：避免运行时类型错误
 * 4. 渐进式更新：只更新有效的数据字段，保留默认值
 * 
 * 三元运算符 ?: 的高级用法：
 * firstPage[@"mainTitle"] ?: self.pendantData.mainTitle
 * 等价于：
 * if (firstPage[@"mainTitle"] != nil) {
 *     self.pendantData.mainTitle = firstPage[@"mainTitle"];
 * } else {
 *     // 保持原有值不变
 * }
 * 
 * 这种模式的优势：
 * 1. 简洁性：一行代码完成条件赋值
 * 2. 安全性：nil值不会覆盖有效的默认值
 * 3. 可读性：意图明确，代码简洁
 */
- (void)updateDataModel:(NSDictionary *)jsonData {
    /*
     * 输入参数验证：
     * 检查jsonData是否为nil，避免后续的空指针访问
     * 这是防御性编程的第一道防线
     */
    if (!jsonData) return;
    
    /*
     * JSON结构解析：
     * 假设服务器返回的JSON具有以下层次结构：
     * {
     *   "firstPage": {
     *     "mainTitle": "...",
     *     "userName": "...",
     *     "userTitle": "..."
     *   },
     *   "secondPage": {
     *     "challengeTitle": "...",
     *     "progressText": "...",
     *     "rewardText": "...",
     *     "progressValue": 0.75
     *   },
     *   "bottomBar": {
     *     "eventTitle": "..."
     *   }
     * }
     * 
     * 这种结构化设计的优势：
     * 1. 逻辑清晰：按UI页面组织数据
     * 2. 扩展性强：容易添加新的页面或字段
     * 3. 维护便利：修改某个页面的数据不影响其他页面
     */
    NSDictionary *firstPage = jsonData[@"firstPage"];
    NSDictionary *secondPage = jsonData[@"secondPage"];
    NSDictionary *bottomBar = jsonData[@"bottomBar"];
    
    /*
     * 第一页数据更新：
     * 
     * 条件检查的必要性：
     * if (firstPage) 确保这个页面的数据存在
     * 服务器可能只返回部分数据，或者某些页面暂时不可用
     * 
     * 安全赋值策略：
     * firstPage[@"mainTitle"] ?: self.pendantData.mainTitle
     * 1. 如果服务器提供了新值，使用新值
     * 2. 如果服务器没有提供或值为nil，保持原有默认值
     * 3. 确保UI始终有有效的显示内容
     */
    // 更新第一页数据 - 用户信息相关字段
    if (firstPage) {
        self.pendantData.mainTitle = firstPage[@"mainTitle"] ?: self.pendantData.mainTitle;
        self.pendantData.userName = firstPage[@"userName"] ?: self.pendantData.userName;
        self.pendantData.userTitle = firstPage[@"userTitle"] ?: self.pendantData.userTitle;
    }
    
    /*
     * 第二页数据更新：
     * 包含特殊的数值类型处理逻辑
     */
    // 更新第二页数据 - 挑战和进度相关字段
    if (secondPage) {
        self.pendantData.challengeTitle = secondPage[@"challengeTitle"] ?: self.pendantData.challengeTitle;
        self.pendantData.progressText = secondPage[@"progressText"] ?: self.pendantData.progressText;
        self.pendantData.rewardText = secondPage[@"rewardText"] ?: self.pendantData.rewardText;
        
        /*
         * 数值类型的特殊处理：
         * 
         * JSON中的数字处理机制：
         * 1. JSON标准：数字可以是整数或浮点数
         * 2. Foundation框架：自动将JSON数字转换为NSNumber对象
         * 3. 类型安全：需要显式转换为目标类型
         * 
         * 为什么需要单独处理？
         * 1. 类型转换：NSNumber -> CGFloat
         * 2. 值验证：确保数值在合理范围内（0.0-1.0）
         * 3. 兼容性：处理服务器可能返回字符串类型的数字
         * 
         * 安全转换的步骤：
         * 1. 存在性检查：NSNumber *progressValue = secondPage[@"progressValue"]
         * 2. 类型验证：if (progressValue)
         * 3. 类型转换：[progressValue floatValue]
         */
        NSNumber *progressValue = secondPage[@"progressValue"];
        if (progressValue) {
            self.pendantData.progressValue = [progressValue floatValue];
            // 可以添加范围验证：
            // if (self.pendantData.progressValue < 0.0) self.pendantData.progressValue = 0.0;
            // if (self.pendantData.progressValue > 1.0) self.pendantData.progressValue = 1.0;
        }
    }
    
    /*
     * 底部栏数据更新：
     * 使用相同的安全赋值策略
     */
    // 更新底部栏数据 - 活动相关信息
    if (bottomBar) {
        self.pendantData.eventTitle = bottomBar[@"eventTitle"] ?: self.pendantData.eventTitle;
    }
    
    NSLog(@"📱 数据模型更新完成");
}

/**
 * @brief 用新数据更新UI - 将数据模型的变化反映到用户界面
 * @discussion UI更新的最佳实践和设计模式：
 * 
 * UI更新的核心原则：
 * 1. 线程安全：必须在主线程中执行（调用此方法前已确保）
 * 2. 存在性检查：更新前验证UI元素是否存在
 * 3. 原子性：批量更新相关UI元素
 * 4. 可观察性：提供详细的日志记录
 * 
 * 为什么需要存在性检查？
 * 1. 异步创建：UI元素可能尚未创建完成
 * 2. 条件显示：某些UI元素可能根据条件隐藏
 * 3. 生命周期：UI元素可能已经被销毁
 * 4. 错误恢复：避免向nil对象发送消息
 * 
 * UI更新的时机考虑：
 * - 应用启动：使用默认数据创建UI
 * - 网络成功：用服务器数据更新UI
 * - 网络失败：保持默认数据显示
 * - 用户刷新：重新获取数据并更新
 */
- (void)updateUIWithNewData {
    /*
     * 第一页UI元素更新：
     * 
     * 条件更新模式：
     * if (self.mainTitleLabel) { ... }
     * 
     * 这种模式的必要性：
     * 1. 防止空指针：如果label为nil，不会执行更新
     * 2. 延迟绑定：支持UI元素的异步创建
     * 3. 错误恢复：即使某个元素创建失败，其他元素仍能正常更新
     * 
     * 属性访问的安全性：
     * self.mainTitleLabel.text = self.pendantData.mainTitle
     * 1. 左侧：UI元素的text属性，用于显示
     * 2. 右侧：数据模型的对应字段，作为数据源
     * 3. 绑定关系：建立数据到视图的单向绑定
     */
    // 更新第一页标签 - 用户信息显示区域
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
    
    /*
     * 第二页UI元素更新：
     * 采用相同的安全更新模式
     */
    // 更新第二页标签 - 挑战和进度显示区域
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
    
    /*
     * 底部栏UI元素更新：
     * 全局信息显示区域
     */
    // 更新底部栏 - 活动信息显示区域
    if (self.eventTitleLabel) {
        self.eventTitleLabel.text = self.pendantData.eventTitle;
        NSLog(@"🔄 更新活动标题: %@", self.pendantData.eventTitle);
    }
    
    /*
     * 更新完成日志：
     * 提供操作完成的确认信息，便于调试和监控
     */
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
    // 2. 创建轮播控件（UIScrollView + 分页）
    // 通过UIScrollView实现一个可以左右滑动的轮播视图。
    UIScrollView *carouselScrollView = [[UIScrollView alloc] init];
    carouselScrollView.pagingEnabled = YES; // 开启分页效果，每次滑动都停在整页位置
    carouselScrollView.showsHorizontalScrollIndicator = NO; // 隐藏水平滚动条
    carouselScrollView.showsVerticalScrollIndicator = NO; // 隐藏垂直滚动条
    carouselScrollView.bounces = YES; // 开启边缘回弹效果
    carouselScrollView.backgroundColor = [UIColor clearColor]; // 设置为透明
    [containerView addSubview:carouselScrollView]; // 添加到容器视图
    carouselScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置轮播视图的约束，占据容器顶部的151高度区域
    [NSLayoutConstraint activateConstraints:@[
        [carouselScrollView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:0.5], // 左侧对齐，微调0.5pt
        [carouselScrollView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-0.5], // 右侧对齐，微调0.5pt
        [carouselScrollView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [carouselScrollView.heightAnchor constraintEqualToConstant:151]
    ]];
    
    // 设置轮播内容尺寸
    CGFloat pageWidth = 111; // 页面宽度
    CGFloat pageHeight = 151; // 页面高度
    carouselScrollView.contentSize = CGSizeMake(pageWidth * 2, pageHeight); // 设置可滚动区域的总大小

    // 3. 创建第一页内容（包含渐变背景和装饰图片）
    UIView *firstPageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
    firstPageView.backgroundColor = [UIColor clearColor]; // 保持透明
    [carouselScrollView addSubview:firstPageView];
    // 3.1 在 firstPageView 中添加渐变背景
    UIView *gradientBackgroundView = [[UIView alloc] init];
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
    layer0.startPoint = CGPointMake(0.0, 0.0);  // 左上角
    layer0.endPoint = CGPointMake(1.0, 1.0);    // 右下角
    // 直接设置渐变层的大小和位置，使其完全覆盖背景视图
    layer0.frame = CGRectMake(0, 0, pageWidth, pageHeight);
    [gradientBackgroundView.layer addSublayer:layer0]; // 将渐变层添加到背景视图的layer上
    [firstPageView addSubview:gradientBackgroundView]; // 将背景视图添加到第一页
    gradientBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置 gradientBackgroundView 的布局约束，填满整个 firstPageView
    [NSLayoutConstraint activateConstraints:@[
        [gradientBackgroundView.leadingAnchor constraintEqualToAnchor:firstPageView.leadingAnchor],
        [gradientBackgroundView.trailingAnchor constraintEqualToAnchor:firstPageView.trailingAnchor],
        [gradientBackgroundView.topAnchor constraintEqualToAnchor:firstPageView.topAnchor],
        [gradientBackgroundView.bottomAnchor constraintEqualToAnchor:firstPageView.bottomAnchor]
    ]];
    // 3.2 在 firstPageView 中添加 Component2 装饰图片
    UIImageView *component2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Component2"]];
    component2ImageView.contentMode = UIViewContentModeScaleAspectFit; // 保持图片比例缩放
    [firstPageView addSubview:component2ImageView]; // 添加到第一页
    component2ImageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 约束：水平居中，顶部对齐，宽度为112（超出页面宽度以营造装饰效果）
    [NSLayoutConstraint activateConstraints:@[
        [component2ImageView.centerXAnchor constraintEqualToAnchor:firstPageView.centerXAnchor],
        [component2ImageView.topAnchor constraintEqualToAnchor:firstPageView.topAnchor],
        [component2ImageView.widthAnchor constraintEqualToConstant:112]
    ]];

    // === 在 firstPageView 中添加头像容器和文本标签 ===
    
    // 4. 在 firstPageView 中添加头像容器 profileContainerView
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
    // 5. 在 profileContainerView 内添加圆形头像
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
    
    // 6. 在 firstPageView 中添加 "+"号图标容器
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
    // 7. 在 firstPageView 中添加文本标签并保存引用以便动态更新
    self.mainTitleLabel = [self createCustomLabelWithText:self.pendantData.mainTitle fontSize:11 width:91 height:20 top:19 color:[UIColor whiteColor] parent:firstPageView];
    self.userNameLabel = [self createCustomLabelWithText:self.pendantData.userName fontSize:10 width:20 height:12 top:108 color:[UIColor whiteColor] parent:firstPageView];
    self.userTitleLabel = [self createCustomLabelWithText:self.pendantData.userTitle fontSize:10 width:70 height:12 top:122 color:[UIColor whiteColor] parent:firstPageView];
    // 8. 创建第二页内容（心愿挑战页面，渐变背景）
    UIView *secondPageView = [[UIView alloc] initWithFrame:CGRectMake(pageWidth, 0, pageWidth, pageHeight)];
    secondPageView.backgroundColor = [UIColor clearColor]; // 设置为透明，使用渐变背景
    secondPageView.layer.cornerRadius = 12;
    secondPageView.layer.masksToBounds = YES;
    [carouselScrollView addSubview:secondPageView];
    
    // 8.1 为 secondPageView 添加渐变背景
    UIView *secondPageGradientView = [[UIView alloc] init];
    secondPageGradientView.layer.cornerRadius = 12;
    secondPageGradientView.layer.masksToBounds = YES;
    [secondPageView addSubview:secondPageGradientView];
    secondPageGradientView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置渐变背景视图约束，填满整个 secondPageView
    [NSLayoutConstraint activateConstraints:@[
        [secondPageGradientView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor],
        [secondPageGradientView.trailingAnchor constraintEqualToAnchor:secondPageView.trailingAnchor],
        [secondPageGradientView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor],
        [secondPageGradientView.bottomAnchor constraintEqualToAnchor:secondPageView.bottomAnchor]
    ]];
    
    // 创建背景渐变层
    CAGradientLayer *backgroundGradient = [CAGradientLayer layer];
    backgroundGradient.frame = CGRectMake(0, 0, pageWidth, pageHeight);
    backgroundGradient.cornerRadius = 12;
    // 设置背景渐变颜色：从 rgba(81, 50, 36, 0) 到 rgba(28, 13, 13, 1)
    backgroundGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:81.0/255.0 green:50.0/255.0 blue:36.0/255.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithRed:28.0/255.0 green:13.0/255.0 blue:13.0/255.0 alpha:1.0].CGColor
    ];
    backgroundGradient.startPoint = CGPointMake(0.0, 0.0);  // 左上角
    backgroundGradient.endPoint = CGPointMake(1.0, 1.0);    // 右下角
    [secondPageGradientView.layer addSublayer:backgroundGradient];
    // 8.2 为 secondPageView 添加渐变边框
    UIView *borderView = [[UIView alloc] init];
    borderView.backgroundColor = [UIColor clearColor];
    borderView.layer.cornerRadius = 12;
    borderView.layer.masksToBounds = YES;
    [secondPageView addSubview:borderView];
    [secondPageView sendSubviewToBack:borderView]; // 将边框视图置于最底层
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置边框视图约束，比内容视图大1px来形成边框效果
    [NSLayoutConstraint activateConstraints:@[
        [borderView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor constant:-1],
        [borderView.trailingAnchor constraintEqualToAnchor:secondPageView.trailingAnchor constant:1],
        [borderView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor constant:-1],
        [borderView.bottomAnchor constraintEqualToAnchor:secondPageView.bottomAnchor constant:1]
    ]];
    
    // 创建边框渐变层
    CAGradientLayer *borderGradient = [CAGradientLayer layer];
    borderGradient.frame = CGRectMake(0, 0, pageWidth + 2, pageHeight + 2);
    borderGradient.cornerRadius = 12;
    // 设置边框渐变颜色：从 rgba(54, 40, 29, 0) 到 rgba(191, 126, 79, 1)
    borderGradient.colors = @[
        (__bridge id)[UIColor colorWithRed:54.0/255.0 green:40.0/255.0 blue:29.0/255.0 alpha:0.0].CGColor,
        (__bridge id)[UIColor colorWithRed:191.0/255.0 green:126.0/255.0 blue:79.0/255.0 alpha:1.0].CGColor
    ];
    borderGradient.startPoint = CGPointMake(0.0, 0.0);  // 左上角
    borderGradient.endPoint = CGPointMake(1.0, 1.0);    // 右下角
    [borderView.layer addSublayer:borderGradient];
    // 添加新的 "page2" 图片，替换原来的箭头图片
    UIImageView *page2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"page2"]];
    page2ImageView.contentMode = UIViewContentModeScaleAspectFit;
    [secondPageView addSubview:page2ImageView];
    page2ImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置 page2 图片约束：Width: 90px, Height: 93px, Top: 1px, Left: 10px
    [NSLayoutConstraint activateConstraints:@[
        [page2ImageView.widthAnchor constraintEqualToConstant:90],
        [page2ImageView.heightAnchor constraintEqualToConstant:93],
        [page2ImageView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor constant:1],
        [page2ImageView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor constant:10]
    ]];
    // 创建第二页文本标签并保存引用以便动态更新
    self.challengeTitleLabel = [self createCustomLabelWithText:self.pendantData.challengeTitle fontSize:13 width:91 height:20 top:19 color:[UIColor whiteColor] parent:secondPageView];
    self.progressTextLabel = [self createCustomLabelWithText:self.pendantData.progressText fontSize:10 width:91 height:20 top:98 color:[UIColor whiteColor] parent:secondPageView];
    // 添加新的容器视图 (54x14，位于 top:107, left:5)
    UIView *progressContainerView = [[UIView alloc] init];
    progressContainerView.backgroundColor = [UIColor clearColor];
    [secondPageView addSubview:progressContainerView];
    progressContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    // 设置容器视图的约束
    [NSLayoutConstraint activateConstraints:@[
        [progressContainerView.widthAnchor constraintEqualToConstant:54],
        [progressContainerView.heightAnchor constraintEqualToConstant:14],
        [progressContainerView.topAnchor constraintEqualToAnchor:secondPageView.topAnchor constant:112],
        [progressContainerView.leadingAnchor constraintEqualToAnchor:secondPageView.leadingAnchor constant:5]
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
    // 设置fire图片的约束 (Width: 43.75px, Height: 14px, Top: -2px, Left: 10px)
    [NSLayoutConstraint activateConstraints:@[
        [fireImageView.widthAnchor constraintEqualToConstant:43.75],
        [fireImageView.heightAnchor constraintEqualToConstant:14],
        [fireImageView.topAnchor constraintEqualToAnchor:progressContainerView.topAnchor constant:-2],
        [fireImageView.leadingAnchor constraintEqualToAnchor:progressContainerView.leadingAnchor constant:10]
    ]];
    self.rewardTextLabel = [self createCustomLabelWithText:self.pendantData.rewardText
                                                  fontSize:10
                                                     width:91
                                                    height:20
                                                       top:122
                                                     color:[UIColor colorWithRed:255.0/255.0 green:233.0/255.0 blue:190.0/255.0 alpha:1.0]
                                                    parent:secondPageView];
    // 9. 在 containerView 下方添加 UIPageControl 作为页码指示器
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
    // 页面指示器位于轮播视图下方7pt的位置
    [NSLayoutConstraint activateConstraints:@[
        [self.pageControl.centerXAnchor constraintEqualToAnchor:carouselScrollView.centerXAnchor],
        [self.pageControl.topAnchor constraintEqualToAnchor:carouselScrollView.bottomAnchor constant:-20]
    ]];
    
    // 设置UIScrollView的代理为当前视图控制器，以便监听滚动事件
    carouselScrollView.delegate = self;
    // 10. 创建 bottomBarView 底部栏
    // 这是位于挂件主体下方的深色条状视图。
    UIView *bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 112, 20)];
    bottomBarView.layer.backgroundColor = [UIColor colorWithRed:0.253 green:0.118 blue:0.012 alpha:1].CGColor;
    // 设置整体圆滑（全圆角），不改变尺寸
    bottomBarView.layer.cornerRadius = 10; // 高度的一半，使其两端呈圆形
    bottomBarView.layer.masksToBounds = YES;
    [containerView addSubview:bottomBarView];
    bottomBarView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置 bottomBarView 尺寸和位置（位于轮播视图下方）
    [NSLayoutConstraint activateConstraints:@[
        [bottomBarView.widthAnchor constraintEqualToConstant:112],
        [bottomBarView.heightAnchor constraintEqualToConstant:20],
        // 关键约束：顶部距离轮播视图底部一定距离
        [bottomBarView.topAnchor constraintEqualToAnchor:carouselScrollView.bottomAnchor constant:1],
        [bottomBarView.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor]
    ]];
    
    // 11. 在 bottomBarView 内部居中添加文字标签
    self.eventTitleLabel = [self createCustomLabelWithText:self.pendantData.eventTitle fontSize:10 width:93 height:14 top:3.5 color:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] parent:bottomBarView];
    
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