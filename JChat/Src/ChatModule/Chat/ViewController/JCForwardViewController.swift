//
//  JCForwardViewController.swift
//  JChat
//
//  转发消息界面
//

import UIKit

class JCForwardViewController: UIViewController {
    
    //转发的消息
    var message: JMSGMessage?
    //发送人
    var fromUser: JMSGUser!

    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }

    //取消按钮
    private lazy var cancelButton = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    //联系人列表
    fileprivate lazy var contacterView: UITableView = {
        var contacterView = UITableView(frame: .zero, style: .grouped)
        contacterView.delegate = self
        contacterView.dataSource = self
        contacterView.separatorStyle = .none
        contacterView.sectionIndexColor = UIColor(netHex: 0x2dd0cf)
        contacterView.sectionIndexBackgroundColor = .clear
        contacterView.register(JCContacterCell.self, forCellReuseIdentifier: "JCContacterCell")
        contacterView.frame = CGRect(x: 0, y: 0, width: self.view.width, height: self.view.height)
        return contacterView
    }()
    //搜索结果显示区域
    let searchResultVC = JCSearchResultViewController()
    //搜索控件
    private lazy var searchController: JCSearchController = JCSearchController(searchResultsController: JCNavigationController(rootViewController: self.searchResultVC))
    //搜索区域
    private lazy var searchView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 31))
    //角标数
    fileprivate var badgeCount = 0
    
    fileprivate lazy var tagArray = ["群组"]
    //首字母分组
    fileprivate lazy var users: [JMSGUser] = []
    fileprivate lazy var keys: [String] = []
    fileprivate lazy var data: Dictionary<String, [JMSGUser]> = Dictionary()
    //选择接收的会员
    fileprivate var selectUser: JMSGUser!

    private func _init() {
        if message == nil {
            self.title = "发送名片"
        } else {
            self.title = "转发"
        }
        
        searchResultVC.message = message
        searchResultVC.fromUser = fromUser
        searchResultVC.delegate = self

        view.backgroundColor = UIColor(netHex: 0xe8edf3)
        _setupNavigation()
        
        let nav = searchController.searchResultsController as! JCNavigationController
        let vc = nav.topViewController as! JCSearchResultViewController
        searchController.delegate = self
        searchController.searchResultsUpdater = vc
        
        searchView.addSubview(searchController.searchBar)
        contacterView.tableHeaderView = searchView

        view.addSubview(contacterView)
        
        _getFriends()
    }
    
    //设置导航左侧的取消按钮
    private func _setupNavigation() {
        cancelButton.addTarget(self, action: #selector(_clickNavleftButton), for: .touchUpInside)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        let item = UIBarButtonItem(customView: cancelButton)
        navigationItem.leftBarButtonItem = item
    }
    
    //导航按钮点击事件
    func _clickNavleftButton() {
        dismiss(animated: true, completion: nil)
    }
    
    //获取会员好友信息，分组排序，并加载至界面
    func _updateUserInfo() {
        let users = self.users
        _classify(users)
        contacterView.reloadData()
    }
    
    //分组排序
    func _classify(_ users: [JMSGUser]) {
        self.users = users
        keys.removeAll()
        data.removeAll()
        for item in users {
            var key = item.displayName().firstCharacter()
            if !key.isLetterOrNum() {
                key = "#"
            }
            var array = data[key]
            if array == nil {
                array = [item]
            } else {
                array?.append(item)
            }
            if !keys.contains(key) {
                keys.append(key)
            }
            data[key] = array
        }
        keys = keys.sortedKeys()
    }
    
    //获取好友
    func _getFriends() {
        JMSGFriendManager.getFriendList { (result, error) in
            if let users = result as? [JMSGUser] {
                self._classify(users)
                self.contacterView.reloadData()
            }
        }
    }

}

//Mark: - 设置tableview数据源
extension JCForwardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if users.count > 0 {
            return keys.count + 1
        }
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return tagArray.count
        }
        return data[keys[section - 1]]!.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return ""
        }
        return keys[section - 1]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return keys
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 5
        }
        return 10
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "JCContacterCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? JCContacterCell else {
            return
        }
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.title = "群组"
                cell.icon = UIImage.loadImage("com_icon_group_36")
                cell.isShowBadge = false
            default:
                break
            }
            return
        }
        let user = data[keys[indexPath.section - 1]]?[indexPath.row]
        cell.isShowBadge = false
        cell.bindDate(user!)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let vc = JCGroupListViewController()
            vc.message = message
            vc.fromUser = fromUser
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        selectUser = data[keys[indexPath.section - 1]]?[indexPath.row]
        if let message = message {
            forwardMessage(message)
        } else {
            sendBusinessCard()
        }
        
    }
    
    //发送名片消息
    private func sendBusinessCard() {
        fromUser = fromUser ?? JMSGUser.myInfo()
        JCAlertView.bulid().setTitle("发送给：\(selectUser.displayName())")
            .setMessage(fromUser.displayName() + "的名片")
            .setDelegate(self)
            .addCancelButton("取消")
            .addButton("确定")
            .setTag(10003)
            .show()
    }
    
    //转发消息
    private func forwardMessage(_ message: JMSGMessage) {
        JCAlertView.bulid().setJMessage(message)
            .setTitle("发送给：\(selectUser.displayName())")
            .setDelegate(self)
            .setTag(10001)
            .show()
    }
}

//搜索显示隐藏操作
extension JCForwardViewController: UISearchControllerDelegate {
    //显示搜索，隐藏联系人
    func willPresentSearchController(_ searchController: UISearchController) {
        contacterView.isHidden = true
    }
    //隐藏搜索，显示联系人
    func willDismissSearchController(_ searchController: UISearchController) {
        contacterView.isHidden = false
        let nav = searchController.searchResultsController as! JCNavigationController
        nav.isNavigationBarHidden = true
        nav.popToRootViewController(animated: false)
    }
}

//弹出提示框操作
extension JCForwardViewController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex != 1 {
            return
        }
        switch alertView.tag {
        case 10001:
            JMSGMessage.forwardMessage(message!, target: selectUser, optionalContent: JMSGOptionalContent.ex.default)
            
        case 10003:
            JMSGConversation.createSingleConversation(withUsername: selectUser.username) { (result, error) in
                if let conversation = result as? JMSGConversation {
                    let message = JMSGMessage.ex.createBusinessCardMessage(conversation, self.fromUser.username, self.fromUser.appKey ?? "")
                    JMSGMessage.send(message, optionalContent: JMSGOptionalContent.ex.default)
                }
            }
        default:
            break
        }
        MBProgressHUD_JChat.show(text: "已发送", view: view, 2)

        let time: TimeInterval = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kReloadAllMessage), object: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
