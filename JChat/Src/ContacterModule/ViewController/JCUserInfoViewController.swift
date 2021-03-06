//
//  JCUserInfoViewController.swift
//  JChat
//
//  用户信息查看界面
//

import UIKit
import JMessage

class JCUserInfoViewController: UIViewController {
    
    var user: JMSGUser!
    var isOnConversation = false
    var isOnAddFriend = false//是否来自于添加好友搜索
    var isFromGroupList = false//是否进入页面来源是群组成员列表
    var group: JMSGGroup?//群组信息
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate lazy var tableview: UITableView = {
        var tableview = UITableView(frame: CGRect(x: 0, y: 64, width: self.view.width, height: self.view.height - 64), style: .grouped)
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(JCUserAvatorCell.self, forCellReuseIdentifier: "JCUserAvatorCell")
        tableview.register(JCUserInfoCell.self, forCellReuseIdentifier: "JCUserInfoCell")
        tableview.register(JCButtonCell.self, forCellReuseIdentifier: "JCButtonCell")
        tableview.register(JCDoubleButtonCell.self, forCellReuseIdentifier: "JCDoubleButtonCell")
        tableview.separatorStyle = .none
        tableview.backgroundColor = UIColor(netHex: 0xe8edf3)
        return tableview
    }()
    private lazy var moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    
    //MARK: - private func
    private func _init() {
        self.title = "详细信息"
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(tableview)
        _setupNavigation()
        NotificationCenter.default.addObserver(self, selector: #selector(_updateUserInfo), name: NSNotification.Name(rawValue: kUpdateFriendInfo), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_updateUserInfo), name: NSNotification.Name(rawValue: kUpdateUserInfo), object: nil)
    }
    
    //右上的导航按钮
    private func _setupNavigation() {
        moreButton.addTarget(self, action: #selector(_clickNavRightButton), for: .touchUpInside)
        moreButton.setImage(UIImage.loadImage("com_icon_more"), for: .normal)
        let item = UIBarButtonItem(customView: moreButton)
        navigationItem.rightBarButtonItem =  item
    }
    
    func _updateUserInfo() {
        tableview.reloadData()
    }
    
    //右上导航按钮点击
    func _clickNavRightButton() {
        let vc = JCFriendSettingViewController()
        vc.user = self.user
        //传入群组对象
        if self.isFromGroupList {
            vc.isFromGroupList = self.isFromGroupList
            vc.group = self.group
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: - UITableViewDataSource & UITableViewDelegate
extension JCUserInfoViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1
        }
        return 6
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 175
        }
        if indexPath.section == 1 {
            return 40
        }
        return 45
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 15
        }
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "JCUserAvatorCell", for: indexPath)
        }
        if indexPath.section == 1  {//按钮的样式
            if user.isFriend || isOnAddFriend {//如果双方是好友或者来源是添加好友操作
                return tableView.dequeueReusableCell(withIdentifier: "JCButtonCell", for: indexPath)
            } else {//其他情况不显示按钮
                //newchange
//                return tableView.dequeueReusableCell(withIdentifier: "JCDoubleButtonCell", for: indexPath)
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: "JCUserInfoCell", for: indexPath)
    }
    
    
    //设置列表显示
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        //没有选中样式
        cell.selectionStyle = .none
        
        if indexPath.section == 0 && indexPath.row == 0 {
            guard let cell = cell as? JCUserAvatorCell else {
                return
            }
            cell.delegate = self
            cell.bindData(user: user)
        }
        
        if indexPath.section == 1 {
            //newchange
            if user.isFriend {//如果双方是好友
                guard let cell = cell as? JCButtonCell else {
                    return
                }
                cell.delegate = self
                cell.buttonTitle = "发送消息"
            }else if isOnAddFriend {//如果是好友添加
                guard let cell = cell as? JCButtonCell else {
                    return
                }
                cell.delegate = self
                cell.buttonTitle = "添加好友"
            }else{//其他情况不显示按钮
                
            }
            
//            if user.isFriend || isOnAddFriend {//如果双方是好友或者是添加好友搜索
//                guard let cell = cell as? JCButtonCell else {
//                    return
//                }
//                cell.delegate = self
//                if isOnAddFriend {//是添加好友搜索
//                    cell.buttonTitle = "添加好友"
//                } else {//其他搜索
//                    cell.buttonTitle = "发送消息"
//                }
//            } else {//非好友、发起聊天搜索来源
//                //newchange
////                guard let cell = cell as? JCDoubleButtonCell else {
////                    return
////                }
////                cell.delegate = self
//            }
        }
        
        if indexPath.section == 0 {
            guard let cell = cell as? JCUserInfoCell else {
                return
            }
            
            switch indexPath.row {
            case 1:
                cell.title = "昵称"
                cell.detail = user.nickname ?? ""
                cell.icon = UIImage.loadImage("com_icon_nickname")
            case 2:
                cell.title = "用户名"
                //newchange
                if user.isFriend {
                    cell.detail = user.username
                }else{
                    cell.detail = ""
                }
                //
                cell.icon = UIImage.loadImage("com_icon_username")
            case 3:
                cell.title = "性别"
                cell.icon = UIImage.loadImage("com_icon_gender")
                switch user.gender {
                case .male:
                    cell.detail = "男"
                case .female:
                    cell.detail = "女"
                case .unknown:
                    cell.detail = "保密"
                }
            case 4:
                cell.title = "生日"
                cell.icon = UIImage.loadImage("com_icon_birthday")
                cell.detail = user.birthday
            case 5:
                cell.title = "地区"
                cell.icon = UIImage.loadImage("com_icon_region")
                cell.detail = user.region
            default:
                break
            }
        }
    }
    
}

//单一样式按钮事件
extension JCUserInfoViewController: JCButtonCellDelegate {
    //按钮点击事件处理
    func buttonCell(clickButton button: UIButton) {
        //如果是添加好友，进入添加好友验证发送
        if isOnAddFriend {
            let vc = JCAddFriendViewController()
            vc.user = user
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        //如果在会话中，进入会话，发送消息
        if isOnConversation {
            for vc in (navigationController?.viewControllers)! {
                if vc is JCChatViewController {
                    navigationController?.popToViewController(vc, animated: true)
                }
            }
            return
        }
        //发送消息，创建会话
        JMSGConversation.createSingleConversation(withUsername: (user?.username)!, appKey: (user?.appKey)!) { (result, error) in
            if error == nil {
                let conv = result as! JMSGConversation
                let vc = JCChatViewController(conversation: conv)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kUpdateConversation), object: nil, userInfo: nil)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

//双按钮样式处理事件
extension JCUserInfoViewController: JCDoubleButtonCellDelegate {
    //添加好友
    func doubleButtonCell(clickLeftButton button: UIButton) {
        //去发送加好友验证消息
        let vc = JCAddFriendViewController()
        vc.user = user
        navigationController?.pushViewController(vc, animated: true)
    }
    //发送非好友消息
    func doubleButtonCell(clickRightButton button: UIButton) {
        //非好友发送消息
        JMSGConversation.createSingleConversation(withUsername: (user?.username)!, appKey: (user?.appKey)!) { (result, error) in
            if error == nil {
                let conv = result as! JMSGConversation
                let vc = JCChatViewController(conversation: conv)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kUpdateConversation), object: nil, userInfo: nil)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

extension JCUserInfoViewController: JCUserAvatorCellDelegate {
    func tapAvator(_ image: UIImage?) {
        guard let image = image else {
            return
        }
        let browserImageVC = JCImageBrowserViewController()
        browserImageVC.imageArr = [image]
        browserImageVC.imgCurrentIndex = 0
        present(browserImageVC, animated: true) {
        
        }
    }
}


