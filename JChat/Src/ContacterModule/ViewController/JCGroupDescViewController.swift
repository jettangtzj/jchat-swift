//
//  JCGroupDescViewController.swift
//  JChat
//
//  群描述显示与设置界面
//

import UIKit
import JMessage

class JCGroupDescViewController: UIViewController {
    
    //群信息
    var group: JMSGGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
        descTextView.text = group.desc
        var count = 80 - (group.desc?.length ?? 0)
        count = count < 0 ? 0 : count
        tipLabel.text = "\(count)"
        descTextView.becomeFirstResponder()
    }

    //背景区域
    private lazy var bgView: UIView = UIView(frame: CGRect(x: 0, y: 64, width: self.view.width, height: 120))
    //描述内容的输入控件
    private lazy var descTextView: UITextView = UITextView(frame: CGRect(x: 15, y: 15, width: self.view.width - 30, height: 90))
    //完成按钮
    private lazy var navRightButton: UIBarButtonItem = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(_saveSignature))
    //提示标签控件
    fileprivate lazy var tipLabel:  UILabel = UILabel(frame: CGRect(x: self.bgView.width - 15 - 50, y: self.bgView.height - 24, width: 50, height: 12))
    
    //MARK: - private func
    private func _init() {
        self.title = "群描述"
        automaticallyAdjustsScrollViewInsets = false;
        view.backgroundColor = UIColor(netHex: 0xe8edf3)
        
        bgView.backgroundColor = .white
        view.addSubview(bgView)
        
        descTextView.delegate = self
        descTextView.font = UIFont.systemFont(ofSize: 16)
        descTextView.backgroundColor = .white
        bgView.addSubview(descTextView)
        
        tipLabel.textColor = UIColor(netHex: 0x999999)
        tipLabel.font = UIFont.systemFont(ofSize: 12)
        tipLabel.textAlignment = .right
        bgView.addSubview(tipLabel)
        
        _setupNavigation()
    }
    
    //设置导航按钮
    private func _setupNavigation() {
        navigationItem.rightBarButtonItem =  navRightButton
    }
    
    //MARK: - click func
    func _saveSignature() {
        descTextView.resignFirstResponder()
        let desc = descTextView.text!
        MBProgressHUD_JChat.showMessage(message: "修改中...", toView: view)
        var name: String? = group.name
        if name!.isEmpty {
            name = nil
        }
        //更新群描述信息
        JMSGGroup.updateGroupInfo(withGroupId: group.gid, name: name, desc: desc) { (result, error) in
            MBProgressHUD_JChat.hide(forView: self.view, animated: true)
            if error == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateGroupInfo), object: nil)
                self.navigationController?.popViewController(animated: true)
            } else {
                MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
            }
        }
    }
}

//80个文字的提示
extension JCGroupDescViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.limitNonMarkedTextSize(80)

        let count = 80 - (nonMarkedText(textView)?.length ?? 0)
        tipLabel.text = "\(count)"
    }
}

