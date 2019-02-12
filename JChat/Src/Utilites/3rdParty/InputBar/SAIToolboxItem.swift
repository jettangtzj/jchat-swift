//
//  SAIToolboxItem.swift
//  SAC
//  工具栏组件
//

import UIKit

@objc open class SAIToolboxItem: NSObject {
    //工具名称
    open var name: String
    //工具标示
    open var identifier: String
    //工具图片
    open var image: UIImage?
    //工具高亮图片
    open var highlightedImage: UIImage?
    //初始化
    public init(_ identifier: String, _ name: String, _ image: UIImage?, _ highlightedImage: UIImage? = nil) {
        self.identifier = identifier
        self.name = name
        self.image = image
        self.highlightedImage = highlightedImage
    }
}
