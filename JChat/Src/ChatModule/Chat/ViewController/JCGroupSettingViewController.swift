//
//  JCGroupSettingViewController.swift
//  JChat
//
//  群组信息设置界面
//

import UIKit
import JMessage

class JCGroupSettingViewController: UIViewController, CustomNavigation {
    
    //群组数据
    var group: JMSGGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //群成员列表
    private var tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    //成员数量
    fileprivate var memberCount = 0
    //成员数组
    fileprivate lazy var users: [JMSGUser] = []
    //是否群主
    fileprivate var isMyGroup = false
    //是否管理员
    fileprivate var isAdmin = false
    //是否更新
    fileprivate var isNeedUpdate = false

    //MARK: - private func
    private func _init() {
        self.title = "群组信息"
        view.backgroundColor = .white

        users = group.memberArray()
        memberCount = users.count
        
        let user = JMSGUser.myInfo()
        //是否我是群所有者
        if group.owner == user.username  {
            isMyGroup = true
        } 
        
        
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexColor = UIColor(netHex: 0x2dd0cf)
        tableView.sectionIndexBackgroundColor = .clear
        tableView.register(JCButtonCell.self, forCellReuseIdentifier: "JCButtonCell")
        tableView.register(JCMineInfoCell.self, forCellReuseIdentifier: "JCMineInfoCell")
        tableView.register(GroupAvatorCell.self, forCellReuseIdentifier: "GroupAvatorCell")
        tableView.frame = CGRect(x: 0, y: 0, width: view.width, height: view.height)
        view.addSubview(tableView)
        
        customLeftBarButton(delegate: self)
        
        //获取群组信息
        JMSGGroup.groupInfo(withGroupId: group.gid) { (result, error) in
            if error == nil {
                guard let group = result as? JMSGGroup else {
                    return
                }
                self.group = group
                self.isNeedUpdate = true
                self._updateGroupInfo()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(_updateGroupInfo), name: NSNotification.Name(rawValue: kUpdateGroupInfo), object: nil)
    }
    
    //更新群组信息
    func _updateGroupInfo() {
        if !isNeedUpdate {//未更新则重新获取
            //根据群组的gid信息得到群组信息
            let conv = JMSGConversation.groupConversation(withGroupId: group.gid)
            group = conv?.target as! JMSGGroup
        }
        if group.memberArray().count != memberCount {//成员数量有变化
            isNeedUpdate = true
            memberCount = group.memberArray().count
        }
        users = group.memberArray()
        memberCount = users.count
        tableView.reloadData()
    }
    
}

//群组信息界面的tableview样式
extension JCGroupSettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    //有几个section
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 4
    }
    
    //每个section的行数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0://群成员占1行
            return 1
        case 1://群基本信息占3行
            return 3
        case 2://群设置占4行
//            return 5
            return 4
        case 3://退出此群按钮占1行
            return 1
        default:
            return 0
        }
    }
    
    //设置行高
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0://群成员列表行
            if isMyGroup || isAdmin {//如果是我的群
                if memberCount > 13 {
                    return 314
                }
                if memberCount > 8 {
                    return 260
                }
                if memberCount > 3 {
                    return 200
                }
                return 100
            } else {//别人的群
                if memberCount > 14 {
                    return 314
                }
                if memberCount > 9 {
                    return 260
                }
                if memberCount > 4 {
                    return 200
                }
                return 100
            }
            
        case 1://群基本信息行高
            return 45
        case 2://群设置行高
            return 40
        default:
            return 45
        }
    }
    
    //设置section header的高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {//群成员信息
            return 0.0001
        }
        //其余默认高度为10
        return 10
    }
    
    
    //每行的布局
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {//群成员信息section
            var cell = tableView.dequeueReusableCell(withIdentifier: "JCGroupSettingCell") as? JCGroupSettingCell
            if isNeedUpdate {
                cell = JCGroupSettingCell(style: .default, reuseIdentifier: "JCGroupSettingCell", group: self.group)
                isNeedUpdate = false
            }
            if cell == nil {
                cell = JCGroupSettingCell(style: .default, reuseIdentifier: "JCGroupSettingCell", group: self.group)
            }
            return cell!
        }
        if indexPath.section == 3 {//退出按钮行
            return tableView.dequeueReusableCell(withIdentifier: "JCButtonCell", for: indexPath)
        }
        if indexPath.section == 1 && indexPath.row == 0 {//群基本信息section
            return tableView.dequeueReusableCell(withIdentifier: "GroupAvatorCell", for: indexPath)
        }
        return tableView.dequeueReusableCell(withIdentifier: "JCMineInfoCell", for: indexPath)
    }
    
    //每行的样式
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle = .none
        if indexPath.section == 3 {
            guard let cell = cell as? JCButtonCell else {
                return
            }
            cell.buttonColor = UIColor(netHex: 0xEB424D)
            cell.buttonTitle = "退出此群"
            cell.delegate = self
            return
        }
        cell.accessoryType = .disclosureIndicator
        if indexPath.section == 0 {
            guard let cell = cell as? JCGroupSettingCell else {
                return
            }
            cell.bindData(self.group)
            cell.delegate = self
            cell.accessoryType = .none
            return
        }

        if let cell = cell as? GroupAvatorCell {
            cell.title = "群头像"
            cell.bindData(group)
        }

        guard let cell = cell as? JCMineInfoCell else {
            return
        }
        if indexPath.section == 2 {
            if indexPath.row == 1 {
                cell.delegate = self
                cell.indexPate = indexPath
                cell.accessoryType = .none
                cell.isSwitchOn = group.isNoDisturb
                cell.isShowSwitch = true
            }
            if indexPath.row == 2 {
                cell.delegate = self
                cell.indexPate = indexPath
                cell.accessoryType = .none
                cell.isSwitchOn = group.isShieldMessage
                cell.isShowSwitch = true
            }
        }
        if indexPath.section == 1 {
            let conv = JMSGConversation.groupConversation(withGroupId: self.group.gid)
            let group = conv?.target as! JMSGGroup
            switch indexPath.row {
            case 1:
                cell.title = "群聊名称"
                cell.detail = group.displayName()
            case 2:
                cell.title = "群描述"
                cell.detail = group.desc
            default:
                break
            }
        } else {
            switch indexPath.row {
            case 0:
                cell.title = "聊天文件"
            case 1:
                cell.title = "消息免打扰"
            case 2:
                cell.title = "消息屏蔽"
//            case 2:
//                cell.title = "清理缓存"
            case 3:
                cell.title = "清空聊天记录"
            default:
                break
            }
        }
        
    }
    
    //选择其中一行的事件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {//群基本信息section
            switch indexPath.row {
            case 0://群头像
                let vc = GroupAvatorViewController()
                vc.group = group
                navigationController?.pushViewController(vc, animated: true)
            case 1://群聊名称
                let vc = JCGroupNameViewController()
                vc.group = group
                navigationController?.pushViewController(vc, animated: true)
            case 2://群描述
                let vc = JCGroupDescViewController()
                vc.group = group
                navigationController?.pushViewController(vc, animated: true)
            default:
                break
            }
        }
        
        if indexPath.section == 2 {//群设置section
            switch indexPath.row {
//            case 2:
//                let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "清理缓存")
//                actionSheet.tag = 1001
//                actionSheet.show(in: self.view)
            case 0://聊天文件
                let vc = FileManagerViewController()
                let conv = JMSGConversation.groupConversation(withGroupId: group.gid)
                vc.conversation  = conv
                navigationController?.pushViewController(vc, animated: true)
            case 3://清空聊天记录
                let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil, otherButtonTitles: "清空聊天记录")
                actionSheet.tag = 1001
                actionSheet.show(in: self.view)
            default:
                break
            }
        }
    }
}


//群设置里面的radio控件事件
extension JCGroupSettingViewController: JCMineInfoCellDelegate {
    func mineInfoCell(clickSwitchButton button: UISwitch, indexPath: IndexPath?) {
        if indexPath != nil {
            switch (indexPath?.row)! {
            case 1:// 消息免打扰
                if group.isNoDisturb == button.isOn {
                    return
                }
                //设置免打扰
                group.setIsNoDisturb(button.isOn, handler: { (result, error) in
                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
                    if error != nil {
                        button.isOn = !button.isOn
                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                    }
                })
            case 2://消息屏蔽
                if group.isShieldMessage == button.isOn {
                    return
                }
                //设置屏蔽
                group.setIsShield(button.isOn, handler: { (result, error) in
                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
                    if error != nil {
                        button.isOn = !button.isOn
                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                    }
                })
            default:
                break
            }
        }
    }
}

//退出此群按钮事件，选择action sheet
extension JCGroupSettingViewController: JCButtonCellDelegate {
    func buttonCell(clickButton button: UIButton) {
        let alertView = UIAlertView(title: "退出此群", message: "确定要退出此群？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
        alertView.show()
    }
}

//退群action sheet事件
extension JCGroupSettingViewController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch buttonIndex {
        case 1://确定退群
            MBProgressHUD_JChat.showMessage(message: "退出中...", toView: self.view)
            group.exit({ (result, error) in
                MBProgressHUD_JChat.hide(forView: self.view, animated: true)
                if error == nil {
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                }
            })
        default:
            break
        }
    }
}

extension JCGroupSettingViewController: JCGroupSettingCellDelegate {
    
    //点击行更多按钮 当成员人数大于15的时候 会出现该按钮
    func clickMoreButton(clickButton button: UIButton) {
        let vc = JCGroupMembersViewController()
        vc.group = self.group
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //点击行添加按钮 添加成员
    func clickAddCell(cell: JCGroupSettingCell) {
        //newchange
        if isMyGroup || isAdmin {//是群主或者管理员才能添加群成员
            let vc = JCUpdateMemberViewController()
            vc.group = group
            self.navigationController?.pushViewController(vc, animated: true)
        }else {//非群主
            MBProgressHUD_JChat.show(text: "您不能添加群成员", view: self.view)
            return
        }
        
    }
    
    //点击行删除按钮 成员删除 必须是自己的群才有该按钮
    func clickRemoveCell(cell: JCGroupSettingCell) {
        let vc = JCRemoveMemberViewController()
        vc.group = group
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //点击行选择 查看成员个人信息
    func didSelectCell(cell: JCGroupSettingCell, indexPath: IndexPath) {
        let index = indexPath.section * 5 + indexPath.row
        let user = users[index]
        //如果点击的是自己本人
        if user.isEqual(to: JMSGUser.myInfo()) {
            navigationController?.pushViewController(JCMyInfoViewController(), animated: true)
            return
        }
        //如果是其他其他人
        let vc = JCUserInfoViewController()
        vc.user = user
        //传入群组对象
        if isMyGroup || isAdmin {
            vc.isFromGroupList = true
            vc.group = group
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

//清空聊天记录按钮的action sheet事件
extension JCGroupSettingViewController: UIActionSheetDelegate {
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
//        if actionSheet.tag == 1001 {
//            // SDK 暂无该功能
//        }
        
        if actionSheet.tag == 1001 {
            if buttonIndex == 1 {
                let conv = JMSGConversation.groupConversation(withGroupId: group.gid)
                conv?.deleteAllMessages()
                NotificationCenter.default.post(name: Notification.Name(rawValue: kDeleteAllMessage), object: nil)
                MBProgressHUD_JChat.show(text: "成功清空", view: self.view)
            }
        }
    }
}

//手势识别
extension JCGroupSettingViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
