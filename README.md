
![效果](https://github.com/dongxiexidu/swift-circleProgressLoadingAnimation/blob/master/demo.gif)


如图,这个动画的是如何做的呢?
### 分析:
- 1.环形进度指示器,根据下载进度来更新它
- 2.扩展环,向内向外扩展这个环,中间扩展的时候,去掉这个遮盖

### 一.环形进度指示器
1.自定义View继承UIView,命名为CircularLoaderView.swift,此View将用来保存动画的代码

2.创建`CAShapeLayer`
```objc
let circlePathLayer = CAShapeLayer()
let circleRadius: CGFloat = 20.0
```
3.初始化`CAShapeLayer`
```objc
// 两个初始化方法都调用configure方法
override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
}

required init?(coder aDecoder: NSCoder) {
    super.init(coder : aDecoder)
    configure()
}


// 初始化代码来配置这个shape layer:
func configure(){
    circlePathLayer.frame = bounds
    circlePathLayer.lineWidth = 2.0
    circlePathLayer.fillColor = UIColor.clear.cgColor
    circlePathLayer.strokeColor = UIColor.red.cgColor
    layer.addSublayer(circlePathLayer)
    backgroundColor = .white
    progress = 0.0
}
```
4.设置环形进度条的矩形frame
```objc
// 小矩形的frame
func circleFrame() -> CGRect {
    
    var circleFrame = CGRect(x: 0, y: 0, width: 2*circleRadius, height: 2*circleRadius)
    let circlePathBounds = circlePathLayer.bounds
    circleFrame.origin.x = circlePathBounds.midX - circleFrame.midX
    circleFrame.origin.y = circlePathBounds.midY - circleFrame.midY
    return circleFrame
}
```
可以参考下图,理解这个`circleFrame`

![Snip20160705_3.png](http://upload-images.jianshu.io/upload_images/987457-ca67dde6412bfdc7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

5.每次自定义的这个view的size改变时，你都需要重新计算circleFrame，所以要将它放在一个独立的方法,方便调用
```objc
// 通过一个矩形（正方形）绘制椭圆（圆形）路径
func circlePath() -> UIBezierPath {
    return UIBezierPath.init(ovalIn: circleFrame())
}
```

6.由于`layers`没有`autoresizingMask`这个属性，你需要在`layoutSubviews`方法中更新`circlePathLayer`的`rame`来恰当地响应`view`的`size`变化
```objc
override func layoutSubviews() {
    super.layoutSubviews()
    
    circlePathLayer.frame = bounds
    circlePathLayer.path = circlePath().cgPath
}
```

7.给`CircularLoaderView.swift`文件添加一个`CGFloat`类型属性,自定义的`setter`和`getter`方法,`setter`方法验证输入值要在0到1之间，然后赋值给`layer`的`strokeEnd`属性。
```objc
var progress : CGFloat{
    get{
        return circlePathLayer.strokeEnd
    }
    
    set{
        if (newValue > 1) {
            circlePathLayer.strokeEnd = 1
        }else if(newValue < 0){
            circlePathLayer.strokeEnd = 0
        }else{
            circlePathLayer.strokeEnd = newValue
        }
    }
}
```

8.利用`Kingfisher`,在image下载回调方法中更新progress.
此处是自定义ImageView,在storyboard中拖个ImageView,设置为自定义的ImageView类型,在这个ImageView初始化的时候就会调用下面的代码
```objc
class CustomImageView: UIImageView {
    // 创建一个实例对象
    let progressIndicatorView = CircularLoaderView(frame: CGRect.zero)
    
    // 从xib中加载会走这个方法
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addSubview(progressIndicatorView)
        progressIndicatorView.frame = bounds
        

        let url = URL.init(string: "https://koenig-media.raywenderlich.com/uploads/2015/02/mac-glasses.jpeg")
        
        self.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: { [weak self] (reseivdSize, expectedSize) in
            self?.progressIndicatorView.progress = CGFloat(reseivdSize) / CGFloat(expectedSize)
        }) { [weak self] (image, error, _, _) in
            self?.progressIndicatorView.reveal()
        }
    }
}
```

### 二.扩展这个环
仔细看,此处是两个动画一起执行,1是向外扩展2.是向内扩展.但可以用一个Bezier path完成此动画,需要用到组动画.
- 1.增加圆的半径(path属性)来向外扩展
- 2.同时增加line的宽度(lineWidth属性)来使环更加厚和向内扩展


```objc
func reveal() {
    // 背景透明，那么藏着后面的imageView将显示出来
    backgroundColor = .clear
    progress = 1.0
    
    // 移除隐式动画,否则干扰reveal animation
    circlePathLayer.removeAnimation(forKey: "strokenEnd")
    
    // 从它的superLayer 移除circlePathLayer ,然后赋值给super的layer mask
    circlePathLayer.removeFromSuperlayer()
    // 通过这个这个circlePathLayer 的mask hole动画 ,image 逐渐可见
    superview?.layer.mask = circlePathLayer
    
    // 1 求出最终形状
    let center = CGPoint(x:bounds.midX,y: bounds.midY)
    let finalRadius = sqrt((center.x*center.x) + (center.y*center.y))
    let radiusInset = finalRadius - circleRadius
    
    
    let outerRect = circleFrame().insetBy(dx: -radiusInset, dy: -radiusInset)
    // CAShapeLayer mask最终形状
    let toPath = UIBezierPath.init(ovalIn: outerRect).cgPath
    
    
    // 2 初始值
    let fromPath = circlePathLayer.path
    let fromLineWidth = circlePathLayer.lineWidth
    
    // 3 最终值
    CATransaction.begin()
    // 防止动画完成跳回原始值
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    circlePathLayer.lineWidth = 2 * finalRadius
    circlePathLayer.path = toPath
    CATransaction.commit()
    
    // 4 路径动画,lineWidth动画
    let lineWidthAnimation = CABasicAnimation(keyPath: "lineWidth")
    lineWidthAnimation.fromValue = fromLineWidth
    lineWidthAnimation.toValue = 2*finalRadius
    let pathAnimation = CABasicAnimation(keyPath: "path")
    pathAnimation.fromValue = fromPath
    pathAnimation.toValue = toPath
    
    // 5 组动画
    let groupAnimation = CAAnimationGroup()
    groupAnimation.duration = 1
    groupAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    groupAnimation.animations = [pathAnimation ,lineWidthAnimation]
    groupAnimation.delegate = self
    circlePathLayer.add(groupAnimation, forKey: "strokeWidth")
}
```


![photo-loading-diagram.png](http://upload-images.jianshu.io/upload_images/987457-308bae99068c55b0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###三.监听动画的结束
```objc
extension CircularLoaderView :CAAnimationDelegate {
    // 移除mask
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        superview?.layer.mask = nil
    }
}
```
[简书:iOS-Swift环形进度指示器+图片加载动画](https://www.jianshu.com/p/a9d7e39c7312)
示例下载地址[github](https://github.com/dongxiexidu/-test)
原文地址[ Rounak Jain](https://www.raywenderlich.com/94302/implement-circular-image-loader-animation-cashapelayer)
[参考地址](http://www.cocoachina.com/ios/20150617/12140.html)


