//
//  FriendsBusinessCardViewController.swift
//  JChat
//
//  个人名片选择发送
//

import UIKit

class FriendsBusinessCardViewController: UIViewController {
    
    //会话
    var conversation: JMSGConversation!

    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }

    //工作区域
    fileprivate lazy var toolView: UIView = UIView(frame: CGRect(x: 0, y: 64, width: self.view.width, height: 55))
    //列表
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionIndexColor = UIColor(netHex: 0x2dd0cf)
        tableView.sectionIndexBackgroundColor = .clear
        tableView.register(JCContacterCell.self, forCellReuseIdentifier: "JCContacterCell")
        tableView.frame = CGRect(x: 0, y: 31 + 64, width: self.view.width, height: self.view.height - 31 - 64)
        return tableView
    }()
    //搜索区域
    fileprivate lazy var searchView: UISearchBar = UISearchBar.default
    //首字母分组
    fileprivate lazy var users: [JMSGUser] = []
    fileprivate lazy var keys: [String] = []
    fileprivate lazy var data: Dictionary<String, [JMSGUser]> = Dictionary()
    //搜索结果
    fileprivate lazy var filteredUsersArray: [JMSGUser] = []
    fileprivate var searchUser: JMSGUser?
    fileprivate var selectUser: JMSGUser!

    //导航左键 取消按钮
    private lazy var navLeftButton: UIBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(_clickNavLeftButton))

    //提示区域
    fileprivate lazy var tipsView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 64 + 31 + 5, width: self.view.width, height: self.view.height - 31 - 64 - 5))
        view.backgroundColor = .white
        let tips = UILabel(frame: CGRect(x: 0, y: 0, width: view.width, height: 50))
        tips.font = UIFont.systemFont(ofSize: 16)
        tips.textColor = UIColor(netHex: 0x999999)
        tips.textAlignment = .center
        tips.text = "未搜索到用户"
        view.addSubview(tips)
        view.isHidden = true
        return view
    }()

    private func _init() {
        self.title = "发送名片"
        view.backgroundColor = .white
        automaticallyAdjustsScrollViewInsets = false

        view.addSubview(toolView)
        view.addSubview(tableView)
        view.addSubview(tipsView)

        _classify([], isFrist: true)

        searchView.frame = CGRect(x: 0, y: 0, width: toolView.width, height: 31)
        searchView.delegate = self

        toolView.addSubview(searchView)

        _setupNavigation()
    }

    //设置导航
    private func _setupNavigation() {
        navigationItem.leftBarButtonItem =  navLeftButton
    }

    //导航取消按钮
    func _clickNavLeftButton() {
        dismiss(animated: true, completion: nil)
    }

    //分组排序
    fileprivate func _classify(_ users: [JMSGUser], isFrist: Bool = false) {

        if users.count > 0 {
            tipsView.isHidden = true
        }

        if isFrist {

            JMSGConversation.allConversations { (result, error) in
                if error == nil {
                    if let conversations = result as? [JMSGConversation] {
                        for conv in conversations {
                            if let user = conv.target as? JMSGUser {
                                self.users.append(user)
                            }
                        }
                    }
                }
            }

            JMSGFriendManager.getFriendList { (result, error) in
                if error == nil {
                    for item in result as! [JMSGUser] {
                        if !self.users.contains(item) {
                            self.users.append(item)
                        }
                    }
                    for item in self.users {
                        var key = item.displayName().firstCharacter()
                        if !key.isLetterOrNum() {
                            key = "#"
                        }
                        var array = self.data[key]
                        if array == nil {
                            array = [item]
                        } else {
                            array?.append(item)
                        }
                        if !self.keys.contains(key) {
                            self.keys.append(key)
                        }
                        self.data[key] = array
                    }
                    self.filteredUsersArray = self.users
                    self.keys = self.keys.sortedKeys()
                    self.tableView.reloadData()
                }
            }
        } else {
            filteredUsersArray = users
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
            tableView.reloadData()
        }
    }

    //过滤搜索
    fileprivate func filter(_ searchString: String) {
        if searchString.isEmpty || searchString == "" {
            _classify(users)
            return
        }
        let searchString = searchString.uppercased()
        filteredUsersArray = _JCFilterUsers(users: users, string: searchString)
        _classify(filteredUsersArray)
    }
}

//Mark: - 接收消息人员列表tableview的设置
extension FriendsBusinessCardViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if filteredUsersArray.count > 0 {
            return keys.count
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[keys[section]]!.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return keys[section]
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return keys
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 30
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
        let user = data[keys[indexPath.section]]?[indexPath.row]
        cell.bindDate(user!)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectUser = data[keys[indexPath.section]]?[indexPath.row]
        var displayName = ""
        if conversation.ex.isGroup {
            let group = conversation.target as! JMSGGroup
            displayName = group.displayName()
        } else {
            displayName = conversation.title ?? ""
        }
        JCAlertView.bulid().setTitle("发送给：\(displayName)")
            .setMessage(selectUser.displayName() + "的名片")
            .setDelegate(self)
            .addCancelButton("取消")
            .addButton("确定")
            .show()
    }
}

//弹出框的按钮事件
extension FriendsBusinessCardViewController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex != 1 {
            return
        }

        let message = JMSGMessage.ex.createBusinessCardMessage(conversation, selectUser.username, selectUser.appKey ?? "")
        JMSGMessage.send(message, optionalContent: JMSGOptionalContent.ex.default)
        MBProgressHUD_JChat.show(text: "已发送", view: view, 2)
        weak var weakSelf = self
        let time: TimeInterval = 2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kReloadAllMessage), object: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
            weakSelf?.dismiss(animated: true, completion: nil)
        }
    }
}

//搜索操作事件
extension FriendsBusinessCardViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }

//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        // 搜索非好友
//        let searchText = searchBar.text!
//        JMSGUser.userInfoArray(withUsernameArray: [searchText]) { (result, error) in
//            if error == nil {
//                let users = result as! [JMSGUser]
//                self.searchUser = users.first
//                self._classify([self.searchUser!])
//                self.tipsView.isHidden = true
//            } else {
//                // 未查询到该用户的信息
//                self.tipsView.isHidden = false
//            }
//        }
//    }
}
