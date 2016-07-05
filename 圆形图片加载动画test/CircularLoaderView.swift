//
//  CircularLoaderView.swift
//  圆形图片加载动画test
//
//  Created by lidongxi on 16/7/5.
//  Copyright © 2016年 don. All rights reserved.
//

import UIKit

class CircularLoaderView: UIView {
    
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

    let circlePathLayer = CAShapeLayer()
    let circleRadius : CGFloat = 20.0
    
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
        circlePathLayer.frame = bounds;
        circlePathLayer.lineWidth = 2.0
        circlePathLayer.fillColor = UIColor.clearColor().CGColor
        circlePathLayer.strokeColor = UIColor.redColor().CGColor
        layer.addSublayer(circlePathLayer)
        backgroundColor = UIColor.whiteColor()
        progress = 0.0
    }
    
    // 小矩形的frame
    func circleFrame() -> CGRect {
        var circleFrame = CGRect(x: 0, y: 0, width: 2*circleRadius, height: 2*circleRadius)
        
        circleFrame.origin.x = CGRectGetMidX(circlePathLayer.bounds) - CGRectGetMidX(circleFrame)
        circleFrame.origin.y = CGRectGetMidY(circlePathLayer.bounds) - CGRectGetMidY(circleFrame)
        return circleFrame
    }
    
    
    // 通过一个矩形（正方形）绘制椭圆（圆形）路径
    func circlePath() -> UIBezierPath {
        return UIBezierPath(ovalInRect: circleFrame())
    }
    
    // 由于layer没有autoresizingMask这个属性，
    // 覆盖 在此方法中，更新circlePathLayer的frame来恰当的响应view的size变化
    override func layoutSubviews() {
        super.layoutSubviews()
        
        circlePathLayer.frame = bounds
        circlePathLayer.path = circlePath().CGPath
    }
    
    
    func reveal() {
        // 背景透明，那么藏着后面的imageView将显示出来
        backgroundColor = UIColor.clearColor()
        progress = 1.0
        
        // 移除隐式动画,否则干扰reveal animation
        circlePathLayer.removeAnimationForKey("strokenEnd")
        
        // 从它的superLayer 移除circlePathLayer ,然后赋值给super的layer mask
        circlePathLayer.removeFromSuperlayer()
        // 通过这个这个circlePathLayer 的mask hole动画 ,image 逐渐可见
        superview?.layer.mask = circlePathLayer
        
        // 1 求出最终形状
        let center = CGPoint(x:CGRectGetMidX(bounds),y: CGRectGetMidY(bounds))
        let finalRadius = sqrt((center.x*center.x) + (center.y*center.y))
        let radiusInset = finalRadius - circleRadius
        let outerRect = CGRectInset(circleFrame(), -radiusInset, -radiusInset)
        // CAShapeLayer mask最终形状
        let toPath = UIBezierPath(ovalInRect: outerRect).CGPath
        
        
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
        circlePathLayer.addAnimation(groupAnimation, forKey: "strokeWidth")
    }
    
    // 移除mask
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        superview?.layer.mask = nil;
    }
    
}
