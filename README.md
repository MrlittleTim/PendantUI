# PendantUI 项目 UI 布局结构说明

## 总览
本项目为 iOS 挂件风格 UI Demo，所有核心界面元素均以代码方式实现，布局层级清晰，便于扩展和维护。

---

## 1. 顶层结构
- **ViewController.view**
  - 作为屏幕主视图，所有内容均居中显示。

---

## 2. containerView（逻辑容器）
- 尺寸：112 × 172，整体居中于屏幕。
- 作为所有挂件内容的父视图，便于整体布局和子视图定位。

---

## 3. 主要子视图

### 3.1 component2ImageView（顶部图片）
- 父视图：containerView
- 尺寸：宽112，高度自适应
- 位置：containerView 顶部正中
- 内容：Assets.xcassets 中的 Component2.png

### 3.2 gradientBackgroundView（视觉背景）
- 父视图：containerView
- 尺寸：111 × 151，圆角12
- 位置：component2ImageView 下方
- 样式：自定义渐变背景，圆角
- **内部包含：**
  - **carouselScrollView（轮播控件）**
    - 填满 gradientBackgroundView，支持左右滑动分页
    - 首页为原有内容，左划后为同尺寸同圆角的纯色方块
  - **UIPageControl（页码指示器）**
    - 位于 gradientBackgroundView 底部，居中，缩小为原来的60%，整体下移10pt
    - 显示两个小圆点，动态提示当前轮播页

### 3.3 profileContainerView（头像容器）
- 父视图：containerView
- 尺寸：41.14 × 48.57
- 位置：左侧对齐 containerView 左侧，右偏35，顶部距 containerView 顶部56.43
- **内部包含：**
  - **profileImageView（头像）**
    - 尺寸：41.14 × 41.14，顶部居中
    - 样式：圆形，1pt描边，描边色RGB(1,0.887,0.717)
  - **plusContainerView（加号容器）**
    - 尺寸：12 × 12，顶部距 containerView 顶部93，水平居中
    - **plusImageView（加号图片）**：填满 plusContainerView
    - **plusButton（透明按钮）**：14 × 14，覆盖 plusContainerView，点击弹出“关注成功”提示

### 3.4 bottomBarView（底部栏）
- 父视图：containerView
- 尺寸：112 × 20，圆角10，颜色深棕色
- 位置：紧贴 gradientBackgroundView 下方
- **内部包含：**
  - **titleLabel**：宽度等于 bottomBarView，内容“2024秋季盛典”，白色，居中

### 3.5 其它标签
- **“沾沾”标签**
  - 父视图：containerView
  - 尺寸：20 × 12，系统字体10pt，白色，行高0.86倍，水平居中，顶部距 containerView 顶部108pt
- **“巅峰冠军”标签**
  - 父视图：containerView
  - 尺寸：70 × 12，系统字体10pt，白色，行高0.86倍，水平居中，顶部距 containerView 顶部122pt
- **“唱歌十强争夺”标签**
  - 父视图：containerView
  - 尺寸：91 × 20，系统字体11pt，白色，行高0.86倍，水平居中，顶部距 containerView 顶部19pt

---

## 4. 结构关系示意

```
ViewController.view
└── containerView (112x172, 居中)
    ├── component2ImageView (顶部, 宽112)
    ├── gradientBackgroundView (111x151, 圆角12)
    │   ├── carouselScrollView (分页, 填满, 圆角12)
    │   │   ├── firstPageView (透明)
    │   │   └── secondPageView (纯色, 圆角12)
    │   └── UIPageControl (底部, 居中, 缩小, 下移)
    ├── profileContainerView (41.14x48.57, 左偏, 顶部56.43)
    │   ├── profileImageView (圆形头像, 1pt描边)
    │   └── plusContainerView (12x12, 顶部93, 居中)
    │       ├── plusImageView (加号)
    │       └── plusButton (透明按钮, 14x14)
    ├── bottomBarView (底部, 112x20, 圆角10)
    │   └── titleLabel ("2024秋季盛典")
    ├── “沾沾”标签 (20x12, 顶部108, 居中)
    ├── “巅峰冠军”标签 (70x12, 顶部122, 居中)
    └── “唱歌十强争夺”标签 (91x20, 顶部19, 居中)
```

---

## 5. 主要样式说明
- 所有标签均用系统字体，行高、字间距等通过 attributedText 设置
- 主要色彩：白色文字、深棕色底栏、头像描边色、渐变背景
- 所有布局均采用 AutoLayout，适配性强

---

## 6. 维护建议
- 新增控件建议统一用工具方法创建，保持风格一致
- 如需调整布局，优先修改约束参数
- 资源图片请放入 Assets.xcassets 并确保命名一致

---

如需进一步扩展或调整UI结构，请参考本说明进行开发。 