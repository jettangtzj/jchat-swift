//
//  JCFriendSettingViewController.swift
//  JChat
//
//  个人详情 右上按钮 好友设置界面
//  备注名 发送名片 加入黑名单
//

import UIKit
import JMessage

class JCFriendSettingViewController: UIViewController {

    var user: JMSGUser!
    var isFromGroupList = false//是否进入页面来源是群组成员列表用户查看
    var group: JMSGGroup? //群组信息
    
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
        tableview.register(JCMineInfoCell.self, forCellReuseIdentifier: "JCMineInfoCell")
        tableview.register(JCButtonCell.self, forCellReuseIdentifier: "JCButtonCell")
        tableview.separatorStyle = .none
        tableview.backgroundColor = UIColor(netHex: 0xe8edf3)
        return tableview
    }()
    
    //MARK: - private func
    private func _init() {
        self.title = "设置"
        automaticallyAdjustsScrollViewInsets = false
        view.addSubview(tableview)
        
        NotificationCenter.default.addObserver(self, selector: #selector(_updateFriendInfo), name: NSNotification.Name(rawValue: kUpdateFriendInfo), object: nil)
    }
    
    func _updateFriendInfo() {
        tableview.reloadData()
    }
}

//MARK: - UITableViewDataSource & UITableViewDelegate
extension JCFriendSettingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if user.isFriend {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isFromGroupList {//群组页面来源
                if user.isFriend {//当前对象是好友
                    return 5
                }
                return 4
            } else {//非群组页面来源
                if user.isFriend {//当前对象是好友
                    return 3
                }
                return 2
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 45
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "JCButtonCell", for: indexPath)
        }
        return tableView.dequeueReusableCell(withIdentifier: "JCMineInfoCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.selectionStyle = .none
        if indexPath.section == 1 {
            guard let cell = cell as? JCButtonCell else {
                return
            }
            cell.delegate = self
            cell.buttonColor = UIColor(netHex: 0xEB424D)
            cell.buttonTitle = "删除好友"
        }
        
        if indexPath.section == 0 {
            guard let cell = cell as? JCMineInfoCell else {
                return
            }
            if isFromGroupList {//群组页面来源
                if user.isFriend {//是否好友
                    switch indexPath.row {
                    case 0:
                        cell.title = "备注名"
                        cell.accessoryType = .disclosureIndicator
                        cell.detail = user.noteName ?? ""
                    case 1:
                        cell.title = "发送名片"
                        cell.accessoryType = .disclosureIndicator
                    case 2:
                        cell.isSwitchOn = user.isInBlacklist
                        cell.delegate = self
                        cell.accessoryType = .none
                        cell.isShowSwitch = true
                        cell.title = "加入黑名单"
                        cell.switchButtonTag = 1
                    case 3:
//                        cell.isSwitchOn = (group?.isAdminMember(withUsername: user.username, appKey: ""))!
//                        cell.delegate = self
//                        cell.accessoryType = .none
//                        cell.isShowSwitch = true
//                        cell.title = "设为群管理员"
//                        cell.switchButtonTag = 2
                        break
                    case 4:
//                        cell.isSwitchOn = (group?.isSilenceMember(withUsername: user.username, appKey: ""))!
//                        cell.delegate = self
//                        cell.accessoryType = .none
//                        cell.isShowSwitch = true
//                        cell.title = "设为群内禁言"
//                        cell.switchButtonTag = 3
                        break
                    default:
                        break
                    }
                } else {
                    switch indexPath.row {
                    case 0:
                        cell.title = "发送名片"
                        cell.accessoryType = .disclosureIndicator
                    case 1:
                        cell.isSwitchOn = user.isInBlacklist
                        cell.delegate = self
                        cell.accessoryType = .none
                        cell.isShowSwitch = true
                        cell.title = "加入黑名单"
                        cell.switchButtonTag = 1
                        
                    case 2:
//                        cell.isSwitchOn = (group?.isAdminMember(withUsername: user.username, appKey: ""))!
//                        cell.delegate = self
//                        cell.accessoryType = .none
//                        cell.isShowSwitch = true
//                        cell.title = "设为群管理员"
//                        cell.switchButtonTag = 2
                        break
                    case 3:
//                        cell.isSwitchOn = (group?.isSilenceMember(withUsername: user.username, appKey: ""))!
//                        cell.delegate = self
//                        cell.accessoryType = .none
//                        cell.isShowSwitch = true
//                        cell.title = "设为群内禁言"
//                        cell.switchButtonTag = 3
                        break
                    default:
                        break
                    }
                }
            } else {//非群组页面来源
                if user.isFriend {//是否好友
                    switch indexPath.row {
                    case 0:
                        cell.title = "备注名"
                        cell.accessoryType = .disclosureIndicator
                        cell.detail = user.noteName ?? ""
                    case 1:
                        cell.title = "发送名片"
                        cell.accessoryType = .disclosureIndicator
                    case 2:
                        cell.isSwitchOn = user.isInBlacklist
                        cell.delegate = self
                        cell.accessoryType = .none
                        cell.isShowSwitch = true
                        cell.title = "加入黑名单"
                        cell.switchButtonTag = 1
                    default:
                        break
                    }
                } else {
                    switch indexPath.row {
                    case 0:
                        cell.title = "发送名片"
                        cell.accessoryType = .disclosureIndicator
                    case 1:
                        cell.isSwitchOn = user.isInBlacklist
                        cell.delegate = self
                        cell.accessoryType = .none
                        cell.isShowSwitch = true
                        cell.title = "加入黑名单"
                        cell.switchButtonTag = 1
                    default:
                        break
                    }
                }
            }
            
        }
    }
    
    //列表中的选择点击
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0://备注名
                if user.isFriend {//备注名
                    let vc = JCNoteNameViewController()
                    vc.user = user
                    navigationController?.pushViewController(vc, animated: true)
                } else {//个人名片
                    //newchange
                    MBProgressHUD_JChat.show(text: "您不能发送个人名片", view: self.view)
//                    let vc = JCForwardViewController()
//                    vc.fromUser = user
//                    let nav = JCNavigationController(rootViewController: vc)
//                    present(nav, animated: true)
                }
            case 1://个人名片
                if user.isFriend {
                    //newchange
                    MBProgressHUD_JChat.show(text: "您不能发送个人名片", view: self.view)
//                    let vc = JCForwardViewController()
//                    vc.fromUser = user
//                    let nav = JCNavigationController(rootViewController: vc)
//                    present(nav, animated: true)
                }
            default:
                break
            }
            
        }
    }
    
}

//删除好友按钮事件
extension JCFriendSettingViewController: JCButtonCellDelegate {
    func buttonCell(clickButton button: UIButton) {
        let alertView = UIAlertView(title: "删除好友", message: "是否确认删除该好友？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "删除")
        alertView.show()
    }
}

//删除好友弹窗提示选择事件
extension JCFriendSettingViewController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {//选择确认删除
            JMSGFriendManager.removeFriend(withUsername: user.username, appKey: user.appKey, completionHandler: { (result, error) in
                if error == nil {
                    if JMSGConversation.singleConversation(withUsername: self.user.username) != nil {
                        JMSGConversation.deleteSingleConversation(withUsername: self.user.username)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateConversation), object: nil)
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateFriendList), object: nil)
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                }
            })
        }
    }
}

//switch 切换事件
extension JCFriendSettingViewController: JCMineInfoCellDelegate {
    func mineInfoCell(clickSwitchButton button: UISwitch, indexPath: IndexPath?) {
        MBProgressHUD_JChat.showMessage(message: "修改中", toView: view)
        
        if button.tag == 1 {//黑名单
            if button.isOn {
                JMSGUser.addUsers(toBlacklist: [user.username]) { (result, error) in
                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
                    if error == nil {
                        MBProgressHUD_JChat.show(text: "修改成功", view: self.view)
                    } else {
                        button.isOn = !button.isOn
                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                    }
                }
            } else {
                JMSGUser.delUsers(fromBlacklist: [user.username]) { (result, error) in
                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
                    if error == nil {
                        MBProgressHUD_JChat.show(text: "修改成功", view: self.view)
                    } else {
                        button.isOn = !button.isOn
                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
                    }
                }
            }
        }else if button.tag == 2 {//设置群管理员
            if button.isOn {
//                self.group?.addAdmin(withUsername: user.username, appKey: nil, completionHandler: { (result, error) in
//                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
//                    if error == nil {
//                        MBProgressHUD_JChat.show(text: "修改成功", view: self.view)
//                    } else {
//                        button.isOn = !button.isOn
//                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
//                    }
//                })
            } else {
//                self.group?.deleteAdmin(withUsername: user.username, appKey: nil, completionHandler: {(result, error) in
//                    MBProgressHUD_JChat.hide(forView: self.view, animated: true)
//                    if error == nil {
//                        MBProgressHUD_JChat.show(text: "修改成功", view: self.view)
//                    } else {
//                        button.isOn = !button.isOn
//                        MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
//                    }
//                })
            }
        }else if button.tag == 3 {//设置群禁言
//            self.group?.setGroupMemberSilence(button.isOn, username: user.username, appKey: nil, handler: { (result, error) in
//                MBProgressHUD_JChat.hide(forView: self.view, animated: true)
//                if error == nil {
//                    MBProgressHUD_JChat.show(text: "修改成功", view: self.view)
//                } else {
//                    button.isOn = !button.isOn
//                    MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.view)
//                }
//            })
        }
    }
    
}
