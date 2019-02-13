//
//  JCDocumentViewController.swift
//  JChat
//
//  文档预览查看
//

import UIKit
import WebKit

class JCDocumentViewController: UIViewController, CustomNavigation {
    
    //文件路径
    var filePath: String!
    //文件类型
    var fileType: String!
    //文件数据
    var fileData: Data!

    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }

    //webview控件
    fileprivate lazy var webView: UIWebView = {
        var webView = UIWebView(frame: .zero)
        webView.delegate = self
        webView.backgroundColor = .white
        webView.scrollView.isDirectionalLockEnabled = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        return webView
    }()
    //文件的url
    private var fileUrl: URL?
    //文档交互控件
    private lazy var documentInteractionController = UIDocumentInteractionController()
    //导航左按钮
    fileprivate lazy var leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 65 / 3))
    
    private func _init() {
        view.backgroundColor = .white
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(webView)
        
        _setupNavigation()
        //webview的显示约束
        view.addConstraint(_JCLayoutConstraintMake(webView, .left, .equal, view, .left))
        view.addConstraint(_JCLayoutConstraintMake(webView, .right, .equal, view, .right))
        view.addConstraint(_JCLayoutConstraintMake(webView, .top, .equal, view, .top, 64))
        view.addConstraint(_JCLayoutConstraintMake(webView, .bottom, .equal, view, .bottom))
        //文档url地址转码
        let encodeWord = filePath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(fileURLWithPath: encodeWord!)
        let fileName = url.lastPathComponent
        //临时存储路径
        let path = "\(NSHomeDirectory())/tmp/" + fileName + "." + fileType
        //文件保存至本地
        if JCFileManager.saveFileToLocal(data: fileData, savaPath: path) {
            fileUrl = URL(fileURLWithPath: path)
            do {
                //使用webview加载html字符串形式显示内容
                let string = try String(contentsOf: fileUrl!, encoding: .utf8)
                webView.loadHTMLString(string, baseURL: nil)
            } catch {
                //直接webview请求
                let request = URLRequest(url: fileUrl!)
                webView.loadRequest(request)
            }
        }
    }
    
    //设置打开的导航按钮
    private func _setupNavigation() {
        let navButton = UIButton(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
        navButton.setImage(UIImage.loadImage("com_icon_file_more"), for: .normal)
        navButton.addTarget(self, action: #selector(_openFile), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: navButton)
        navigationItem.rightBarButtonItems =  [item1]
        
        customLeftBarButton(delegate: self)
    }

    //导航按钮打开的具体操作
    func _openFile() {
        guard let url = fileUrl else {
            return
        }
        documentInteractionController.url = url
        documentInteractionController.delegate = self
        documentInteractionController.presentOptionsMenu(from: .zero, in: self.view, animated: true)
    }

}

//文档交互操作
extension JCDocumentViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return self.view.frame
    }
}

//webview显示操作
extension JCDocumentViewController: UIWebViewDelegate {
    //完成加载
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("webViewDidFinishLoad")
        
    }
    //加载发送错误
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print(error.localizedDescription)
    }
}

//手势识别操作
extension JCDocumentViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
