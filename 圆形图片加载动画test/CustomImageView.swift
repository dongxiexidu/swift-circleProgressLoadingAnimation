//
//  CustomImageView.swift
//  圆形图片加载动画test
//
//  Created by lidongxi on 16/7/5.
//  Copyright © 2016年 don. All rights reserved.
//

import UIKit
import Kingfisher

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
