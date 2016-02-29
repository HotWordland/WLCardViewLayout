# WLCardViewLayout

[![CI Status](http://img.shields.io/travis/HotWordland/WLCardViewLayout.svg?style=flat)](https://travis-ci.org/HotWordland/WLCardViewLayout)
[![Version](https://img.shields.io/cocoapods/v/WLCardViewLayout.svg?style=flat)](http://cocoapods.org/pods/WLCardViewLayout)
[![License](https://img.shields.io/cocoapods/l/WLCardViewLayout.svg?style=flat)](http://cocoapods.org/pods/WLCardViewLayout)
[![Platform](https://img.shields.io/cocoapods/p/WLCardViewLayout.svg?style=flat)](http://cocoapods.org/pods/WLCardViewLayout)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

WLCardViewLayout is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "WLCardViewLayout"
```

#效果

![](https://github.com/HotWordland/WLCardViewLayout/blob/master/demo.gif)

#使用

在可视化编辑里:
![](https://github.com/HotWordland/WLCardViewLayout/blob/master/use.jpeg)

然后关联cardlayout至Controller:
```Objective-C
@property (weak, nonatomic) IBOutlet WLCardViewLayout *cardLayout;
```


```Objective-C
- (void)viewDidLoad {
    [super viewDidLoad];
    // 将一个红色的view 尺寸为100 100 位于视图中心
    //初始化View
    UIView *view = [UIView new];
    //添加进父视图
    [self.view addSubview:view];
    //设置背景颜色
    [view setBackgroundColor:[UIColor redColor]];
    /*** 布局核心 ***/
    //准备好view 为view添加autolayout属性
    PREPCONSTRAINTS(view);
    //设置尺寸
    CONSTRAIN_SIZE(view, 100, 100);
    //在父视图居中
    CENTER(view);
    /*** ***/
    
   }

```



## Author

巫龙, 454763196@qq.com

## License

WLCardViewLayout is available under the MIT license. See the LICENSE file for more info.
