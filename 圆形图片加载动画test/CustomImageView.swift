//
//  CustomImageView.swift
//  圆形图片加载动画test
//
//  Created by lidongxi on 16/7/5.
//  Copyright © 2016年 don. All rights reserved.
//

import UIKit

class CustomImageView: UIImageView {

    // 创建一个实例对象
    let progressIndicatorView = CircularLoaderView(frame: CGRectZero)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addSubview(progressIndicatorView)
        progressIndicatorView.frame = bounds
        
        // 注意写法
        progressIndicatorView.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
        
      //  progressIndicatorView.progress =
        
        let url = NSURL(string: "http://www.raywenderlich.com/wp-content/uploads/2015/02/mac-glasses.jpeg")
        
        self.sd_setImageWithURL(url, placeholderImage: nil, options: .CacheMemoryOnly, progress: { [weak self](reseivdSize, expectedSize) -> Void in
            self!.progressIndicatorView.progress = CGFloat(reseivdSize) / CGFloat(expectedSize)
            
            }) { [weak self](image, error, _, _) -> Void in
             self?.progressIndicatorView.reveal()
        }
        
    }

}
