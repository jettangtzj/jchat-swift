//
//  JCChatViewController.swift
//  JChat
//  会话的主界面
//

import UIKit
import YHPhotoKit
import MobileCoreServices

class JCChatViewController: UIViewController {
    
    open var conversation: JMSGConversation
    fileprivate var isGroup = false
    
    //MARK - life cycle
    public required init(conversation: JMSGConversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
        automaticallyAdjustsScrollViewInsets = false
        if let draft = JCDraft.getDraft(conversation) {
            self.draft = draft
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }
    
    override func loadView() {
        super.loadView()
        let frame = CGRect(x: 0, y: 64, width: self.view.width, height: self.view.height - 64)
        chatView = JCChatView(frame: frame, chatViewLayout: chatViewLayout)
        chatView.delegate = self
        chatView.messageDelegate = self
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.delegate = self
        toolbar.text = draft
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toolbar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        if let group = conversation.target as? JMSGGroup {
            self.title = group.displayName()
        }
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.isTranslucent = true
        JCDraft.update(text: toolbar.text, conversation: conversation)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        JMessage.remove(self, with: conversation)
    }
    
    private var draft: String?
    fileprivate lazy var toolbar: SAIInputBar = SAIInputBar(type: .default)
    fileprivate lazy var inputViews: [String: UIView] = [:]
    fileprivate weak var inputItem: SAIInputItem?
    var chatViewLayout: JCChatViewLayout = .init()
    var chatView: JCChatView!
    fileprivate lazy var reminds: [JCRemind] = []
    fileprivate lazy var documentInteractionController = UIDocumentInteractionController()
    //选择图片界面
    fileprivate lazy var imagePicker: UIImagePickerController = {
        var picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        return picker
    }()
    //选择视频界面
    fileprivate lazy var videoPicker: UIImagePickerController = {
        var picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.sourceType = .camera
        picker.cameraCaptureMode = .video
        picker.videoMaximumDuration = 10
        picker.delegate = self
        return picker
    }()
    //表情组
    fileprivate lazy var _emoticonGroups: [JCCEmoticonGroup] = {
        var groups: [JCCEmoticonGroup] = []
        if let group = JCCEmoticonGroup(identifier: "com.apple.emoji") {
            groups.append(group)
        }
        if let group = JCCEmoticonGroup(identifier: "cn.jchat.guangguang") {
            groups.append(group)
        }
        return groups
    }()
    //表情发送按钮
    fileprivate lazy var _emoticonSendBtn: UIButton = {
        var button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 10 + 8, 0, 8)
        button.setTitle("发送", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setBackgroundImage(UIImage.loadImage("chat_emoticon_btn_send_blue"), for: .normal)
        button.setBackgroundImage(UIImage.loadImage("chat_emoticon_btn_send_gray"), for: .disabled)
        button.addTarget(self, action: #selector(_sendHandler), for: .touchUpInside)
        return button
    }()
    //表情界面
    fileprivate lazy var emoticonView: JCEmoticonInputView = {
        let emoticonView = JCEmoticonInputView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 275))
        emoticonView.delegate = self
        emoticonView.dataSource = self
        return emoticonView
    }()
    //工具栏界面
    fileprivate lazy var toolboxView: SAIToolboxInputView = {
        var toolboxView = SAIToolboxInputView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 197))
        toolboxView.delegate = self
        toolboxView.dataSource = self
        return toolboxView
    }()
    //工具栏的内容组件
    fileprivate lazy var _toolboxItems: [SAIToolboxItem] = {
        return [
            SAIToolboxItem("page:pic", "照片", UIImage.loadImage("chat_tool_pic")),
            SAIToolboxItem("page:camera", "拍照", UIImage.loadImage("chat_tool_camera")),
            SAIToolboxItem("page:video_s", "小视频", UIImage.loadImage("chat_tool_video_short")),
            SAIToolboxItem("page:location", "位置", UIImage.loadImage("chat_tool_location")),
            SAIToolboxItem("page:businessCard", "名片", UIImage.loadImage("chat_tool_businessCard")),
            ]
    }()
    
    //我的头像图片
    fileprivate var myAvator: UIImage?
    //消息内容
    lazy var messages: [JCMessage] = []
    //当前会员
    fileprivate let currentUser = JMSGUser.myInfo()
    //消息页数
    fileprivate var messagePage = 0
    //当前消息
    fileprivate var currentMessage: JCMessageType!
    //最大时长
    fileprivate var maxTime = 0
    //最小时长
    fileprivate var minTime = 0
    fileprivate var minIndex = 0
    //消息数量
    fileprivate var jMessageCount = 0
    fileprivate var isFristLaunch = true
    //录音界面显示
    fileprivate var recordingHub: JCRecordingView!
    //语音录音
    fileprivate lazy var recordHelper: JCRecordVoiceHelper = {
        let recordHelper = JCRecordVoiceHelper()
        recordHelper.delegate = self
        return recordHelper
    }()
    //返回会话列表界面按钮
    fileprivate lazy var leftButton: UIButton = {
        let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 65 / 3))
        leftButton.setImage(UIImage.loadImage("com_icon_back"), for: .normal)
        leftButton.setImage(UIImage.loadImage("com_icon_back"), for: .highlighted)
        leftButton.addTarget(self, action: #selector(_back), for: .touchUpInside)
        leftButton.setTitle("会话", for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        leftButton.contentHorizontalAlignment = .left
        return leftButton
    }()
    
    //初始化
    private func _init() {
        myAvator = UIImage.getMyAvator()
        isGroup = conversation.ex.isGroup
        _updateTitle()
        view.backgroundColor = .white
        JMessage.add(self, with: conversation)
        _setupNavigation()
        _loadMessage(messagePage)
        let tap = UITapGestureRecognizer(target: self, action: #selector(_tapView))
        tap.delegate = self
        chatView.addGestureRecognizer(tap)
        view.addSubview(chatView)
        
        _updateBadge()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_removeAllMessage), name: NSNotification.Name(rawValue: kDeleteAllMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_reloadMessage), name: NSNotification.Name(rawValue: kReloadAllMessage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_updateFileMessage(_:)), name: NSNotification.Name(rawValue: kUpdateFileMessage), object: nil)
    }
    
    //文件消息
    func _updateFileMessage(_ notification: Notification) {
        let userInfo = notification.userInfo
        let msgId = userInfo?[kUpdateFileMessage] as! String
        let message = conversation.message(withMessageId: msgId)!
        let content = message.content as! JMSGFileContent
        let url = URL(fileURLWithPath: content.originMediaLocalPath ?? "")
        let data = try! Data(contentsOf: url)
        updateMediaMessage(message, data: data)
    }
    
    //会话标题或群组显示名称
    private func _updateTitle() {
        if let group = conversation.target as? JMSGGroup {
            title = group.displayName()
        } else {
            title = conversation.title
        }
    }

    //重新加载消息
    func _reloadMessage() {
        //删除所有的消息
        _removeAllMessage()
        //消息页数重置
        messagePage = 0
        _loadMessage(messagePage)
        //加载完毕后，界面滚动至最新一条的位置
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.chatView.scrollToLast(animated: false)
        }
    }
    
    //删除界面所有消息
    func _removeAllMessage() {
        jMessageCount = 0
        messages.removeAll()
        chatView.removeAll()
    }
    
    func _tapView() {
        view.endEditing(true)
        toolbar.resignFirstResponder()
    }
    
    //设置导航按钮
    private func _setupNavigation() {
        let navButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        if isGroup {//是群组消息
            navButton.setImage(UIImage.loadImage("com_icon_group_w"), for: .normal)
            navButton.addTarget(self, action: #selector(_getGroupInfo), for: .touchUpInside)
        } else {//个人消息
            navButton.setImage(UIImage.loadImage("com_icon_user_w"), for: .normal)
            navButton.addTarget(self, action: #selector(_getSingleInfo), for: .touchUpInside)
        }
        let item1 = UIBarButtonItem(customView: navButton)
        navigationItem.rightBarButtonItems =  [item1]

        let item2 = UIBarButtonItem(customView: leftButton)
        navigationItem.leftBarButtonItems =  [item2]
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    //界面回退
    func _back() {
        navigationController?.popViewController(animated: true)
    }
    
    //分页加载消息
    fileprivate func _loadMessage(_ page: Int) {

        let messages = conversation.messageArrayFromNewest(withOffset: NSNumber(value: jMessageCount), limit: NSNumber(value: 17))
        if messages.count == 0 {
            return
        }
        var msgs: [JCMessage] = []
        for index in 0..<messages.count {
            let message = messages[index]
            let msg = _parseMessage(message)
            msgs.insert(msg, at: 0)
            if isNeedInsertTimeLine(message.timestamp.intValue) || index == messages.count - 1 {
                let timeContent = JCMessageTimeLineContent(date: Date(timeIntervalSince1970: TimeInterval(message.timestamp.intValue / 1000)))
                let m = JCMessage(content: timeContent)
                m.options.showsTips = false
                msgs.insert(m, at: 0)
            }
        }
        if page != 0 {
            minIndex = minIndex + msgs.count
            chatView.insert(contentsOf: msgs, at: 0)
        } else {
            minIndex = msgs.count - 1
            chatView.append(contentsOf: msgs)
        }
        self.messages.insert(contentsOf: msgs, at: 0)
    }
    
    //判断是否需要在消息中插入时间线
    private func isNeedInsertTimeLine(_ time: Int) -> Bool {
        if maxTime == 0 || minTime == 0 {
            maxTime = time
            minTime = time
            return true
        }
        if (time - maxTime) >= 5 * 60000 {
            maxTime = time
            return true
        }
        if (minTime - time) >= 5 * 60000 {
            minTime = time
            return true
        }
        return false
    }
    
    // MARK: - parse message
    fileprivate func _parseMessage(_ message: JMSGMessage, _ isNewMessage: Bool = true) -> JCMessage {
        if isNewMessage {
            jMessageCount += 1
        }
        return message.parseMessage(self, { [weak self] (message, data) in
            self?.updateMediaMessage(message, data: data)
        })
    }

    // MARK: - send message
    func send(_ message: JCMessage, _ jmessage: JMSGMessage) {
        if isNeedInsertTimeLine(jmessage.timestamp.intValue) {
            let timeContent = JCMessageTimeLineContent(date: Date(timeIntervalSince1970: TimeInterval(jmessage.timestamp.intValue / 1000)))
            let m = JCMessage(content: timeContent)
            m.options.showsTips = false
            messages.append(m)
            chatView.append(m)
        }
        message.msgId = jmessage.msgId
        message.name = currentUser.displayName()
        message.senderAvator = myAvator
        message.sender = currentUser
        message.options.alignment = .right
        message.options.state = .sending
        if let group = conversation.target as? JMSGGroup {
            message.targetType = .group
            message.unreadCount = group.memberArray().count - 1
        } else {
            message.targetType = .single
            message.unreadCount = 1
        }
        chatView.append(message)
        messages.append(message)
        chatView.scrollToLast(animated: false)
        conversation.send(jmessage, optionalContent: JMSGOptionalContent.ex.default)
    }

    //发送文字消息
    func send(forText text: NSAttributedString) {
        let message = JCMessage(content: JCMessageTextContent(attributedText: text))
        let content = JMSGTextContent(text: text.string)
        let msg = JMSGMessage.ex.createMessage(conversation, content, reminds)
        reminds.removeAll()
        send(message, msg)
    }
    
    //发送表情消息
    func send(forLargeEmoticon emoticon: JCCEmoticonLarge) {
        guard let image = emoticon.contents as? UIImage else {
            return
        }
        let messageContent = JCMessageImageContent()
        messageContent.image = image
        messageContent.delegate = self
        let message = JCMessage(content: messageContent)
        
        let content = JMSGImageContent(imageData: UIImagePNGRepresentation(image)!)
        let msg = JMSGMessage.ex.createMessage(conversation, content!, nil)
        msg.ex.isLargeEmoticon = true
        message.options.showsTips = true
        send(message, msg)
    }
    
    //发送图片消息
    func send(forImage image: UIImage) {
        let data = UIImageJPEGRepresentation(image, 1.0)!
        let content = JMSGImageContent(imageData: data)

        let message = JMSGMessage.ex.createMessage(conversation, content!, nil)
        let imageContent = JCMessageImageContent()
        imageContent.delegate = self
        imageContent.image = image
        content?.uploadHandler = {  (percent:Float, msgId:(String?)) -> Void in
            imageContent.upload?(percent)
        }
        let msg = JCMessage(content: imageContent)
        send(msg, message)
    }
    
    //发送语音消息
    func send(voiceData: Data, duration: Double) {
        let voiceContent = JCMessageVoiceContent()
        voiceContent.data = voiceData
        voiceContent.duration = duration
        voiceContent.delegate = self
        let content = JMSGVoiceContent(voiceData: voiceData, voiceDuration: NSNumber(value: duration))
        let message = JMSGMessage.ex.createMessage(conversation, content, nil)
        
        let msg = JCMessage(content: voiceContent)
        send(msg, message)
    }
    
    //发送文件消息
    func send(fileData: Data) {
        let videoContent = JCMessageVideoContent()
        videoContent.data = fileData
        videoContent.delegate = self
        
        let content = JMSGFileContent(fileData: fileData, fileName: "小视频")
        let message = JMSGMessage.ex.createMessage(conversation, content, nil)
        message.ex.isShortVideo = true
        let msg = JCMessage(content: videoContent)
        send(msg, message)
    }
    
    //发送坐标地址消息
    func send(address: String, lon: NSNumber, lat: NSNumber) {
        let locationContent = JCMessageLocationContent()
        locationContent.address = address
        locationContent.lat = lat.doubleValue
        locationContent.lon = lon.doubleValue
        locationContent.delegate = self
        
        let content = JMSGLocationContent(latitude: lat, longitude: lon, scale: NSNumber(value: 1), address: address)
        let message = JMSGMessage.ex.createMessage(conversation, content, nil)
        let msg = JCMessage(content: locationContent)
        send(msg, message)
    }
    
    //手机键盘
    func keyboardFrameChanged(_ notification: Notification) {
        let dic = NSDictionary(dictionary: (notification as NSNotification).userInfo!)
        let keyboardValue = dic.object(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let bottomDistance = UIScreen.main.bounds.size.height - keyboardValue.cgRectValue.origin.y
        let duration = Double(dic.object(forKey: UIKeyboardAnimationDurationUserInfoKey) as! NSNumber)
        
        UIView.animate(withDuration: duration, animations: {
        }) { (finish) in
            if (bottomDistance == 0 || bottomDistance == self.toolbar.height) && !self.isFristLaunch {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                self.chatView.scrollToLast(animated: false)
            }
            self.isFristLaunch = false
        }
    }
    
    func _sendHandler() {
        let text = toolbar.attributedText
        if text != nil && (text?.length)! > 0 {
            send(forText: text!)
            toolbar.attributedText = nil
        }
    }
    
    //获取个人信息
    func _getSingleInfo() {
        let vc = JCSingleSettingViewController()
        vc.user = conversation.target as? JMSGUser
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //获取群组信息
    func _getGroupInfo() {
        let vc = JCGroupSettingViewController()
        let group = conversation.target as! JMSGGroup
        vc.group = group
        navigationController?.pushViewController(vc, animated: true)
    }
}

//MARK: - JMSGMessage Delegate
//消息
extension JCChatViewController: JMessageDelegate {
    
    //更新多媒体消息
    fileprivate func updateMediaMessage(_ message: JMSGMessage, data: Data) {
        DispatchQueue.main.async {
            if let index = self.messages.index(message) {
                let msg = self.messages[index]
                switch(message.contentType) {
                case .file:
                    if message.ex.isShortVideo {
                        let videoContent = msg.content as! JCMessageVideoContent
                        videoContent.data = data
                        videoContent.delegate = self
                        msg.content = videoContent
                    } else {
                        let fileContent = msg.content as! JCMessageFileContent
                        fileContent.data = data
                        fileContent.delegate = self
                        msg.content = fileContent
                    }
                case .image:
                    let imageContent = msg.content as! JCMessageImageContent
                    let image = UIImage(data: data)
                    imageContent.image = image
                    msg.content = imageContent
                default: break
                }
                msg.updateSizeIfNeeded = true
                self.chatView.update(msg, at: index)
                msg.updateSizeIfNeeded = false
//                self.chatView.update(msg, at: index)
            }
        }
    }
    
    //更新游标
    func _updateBadge() {
        JMSGConversation.allConversations { (result, error) in
            guard let conversations = result as? [JMSGConversation] else {
                return
            }
            let count = conversations.unreadCount
            if count == 0 {
                self.leftButton.setTitle("会话", for: .normal)
            } else {
                self.leftButton.setTitle("会话(\(count))", for: .normal)
            }
        }
    }
    
    
    func onReceive(_ message: JMSGMessage!, error: Error!) {
        if error != nil {
            return
        }
        let message = _parseMessage(message)
        // TODO: 这个判断是sdk bug导致的，暂时只能这么改
        if messages.contains(where: { (m) -> Bool in
            return m.msgId == message.msgId
        }) {
            let indexs = chatView.indexPathsForVisibleItems
            for index in indexs {
                var m = messages[index.row]
                if !m.msgId.isEmpty {
                    m = _parseMessage(conversation.message(withMessageId: m.msgId)!, false)
                    chatView.update(m, at: index.row)
                }
            }
            return
        }
        
        messages.append(message)
        chatView.append(message)
        updateUnread([message])
        conversation.clearUnreadCount()
        if !chatView.isRoll {
            chatView.scrollToLast(animated: true)
        }
        _updateBadge()
    }
    
    //消息发送后的状态回复
    func onSendMessageResponse(_ message: JMSGMessage!, error: Error!) {
        if let error = error as NSError? {
            if error.code == 803009 {
                MBProgressHUD_JChat.show(text: "发送失败，消息中包含敏感词", view: view, 2.0)
            }
            if error.code == 803005 {
                MBProgressHUD_JChat.show(text: "您已不是群成员", view: view, 2.0)
            }
        }
        if let index = messages.index(message) {
            let msg = messages[index]
            msg.options.state = message.ex.state
            chatView.update(msg, at: index)
        }
    }
    
    func onReceive(_ retractEvent: JMSGMessageRetractEvent!) {
        if let index = messages.index(retractEvent.retractMessage) {
            let msg = _parseMessage(retractEvent.retractMessage, false)
            messages[index] = msg
            chatView.update(msg, at: index)
        }
    }
    
    func onSyncOfflineMessageConversation(_ conversation: JMSGConversation!, offlineMessages: [JMSGMessage]!) {
        let msgs = offlineMessages.sorted(by: { (m1, m2) -> Bool in
            return m1.timestamp.intValue < m2.timestamp.intValue
        })
        for item in msgs {
            let message = _parseMessage(item)
            messages.append(message)
            chatView.append(message)
            updateUnread([message])
            conversation.clearUnreadCount()
            if !chatView.isRoll {
                chatView.scrollToLast(animated: true)
            }
        }
        _updateBadge()
    }
    
    func onReceive(_ receiptEvent: JMSGMessageReceiptStatusChangeEvent!) {
        for message in receiptEvent.messages! {
            if let index = messages.index(message) {
                let msg = messages[index]
                msg.unreadCount = message.getUnreadCount()
                chatView.update(msg, at: index)
            }
        }
    }
}

// MARK: - JCEmoticonInputViewDataSource & JCEmoticonInputViewDelegate
// 表情
extension JCChatViewController: JCEmoticonInputViewDataSource, JCEmoticonInputViewDelegate {
    
    open func numberOfEmotionGroups(in emoticon: JCEmoticonInputView) -> Int {
        return _emoticonGroups.count
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, emotionGroupForItemAt index: Int) -> JCEmoticonGroup {
        return _emoticonGroups[index]
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, numberOfRowsForGroupAt index: Int) -> Int {
        return _emoticonGroups[index].rows
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, numberOfColumnsForGroupAt index: Int) -> Int {
        return _emoticonGroups[index].columns
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, moreViewForGroupAt index: Int) -> UIView? {
        if _emoticonGroups[index].type.isSmall {
            return _emoticonSendBtn
        } else {
            return nil
        }
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, insetForGroupAt index: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(12, 10, 12 + 24, 10)
    }

    open func emoticon(_ emoticon: JCEmoticonInputView, didSelectFor item: JCEmoticon) {
        if item.isBackspace {
            toolbar.deleteBackward()
            return
        }
        if let emoticon = item as? JCCEmoticonLarge {
            send(forLargeEmoticon: emoticon)
            return
        }
        if let code = item.contents as? String {
            return toolbar.insertText(code)
        }
        if let image = item.contents as? UIImage {
            let d = toolbar.font?.descender ?? 0
            let h = toolbar.font?.lineHeight ?? 0
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(x: 0, y: d, width: h, height: h)
            toolbar.insertAttributedText(NSAttributedString(attachment: attachment))
            return
        }
    }
}

// MARK: - SAIToolboxInputViewDataSource & SAIToolboxInputViewDelegate
// 工具
extension JCChatViewController: SAIToolboxInputViewDataSource, SAIToolboxInputViewDelegate {
    
    open func numberOfToolboxItems(in toolbox: SAIToolboxInputView) -> Int {
        return _toolboxItems.count
    }
    open func toolbox(_ toolbox: SAIToolboxInputView, toolboxItemForItemAt index: Int) -> SAIToolboxItem {
        return _toolboxItems[index]
    }
    
    open func toolbox(_ toolbox: SAIToolboxInputView, numberOfRowsForSectionAt index: Int) -> Int {
        return 2
    }
    open func toolbox(_ toolbox: SAIToolboxInputView, numberOfColumnsForSectionAt index: Int) -> Int {
        return 4
    }
    open func toolbox(_ toolbox: SAIToolboxInputView, insetForSectionAt index: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(12, 10, 12, 10)
    }
    open func toolbox(_ toolbox: SAIToolboxInputView, shouldSelectFor item: SAIToolboxItem) -> Bool {
        return true
    }
    
    //图片照片选择
    private func _pushToSelectPhotos() {
        let vc = YHPhotoPickerViewController()
        vc.maxPhotosCount = 9;
        vc.pickerDelegate = self
        present(vc, animated: true)
    }
    open func toolbox(_ toolbox: SAIToolboxInputView, didSelectFor item: SAIToolboxItem) {
        toolbar.resignFirstResponder()
        switch item.identifier {
        case "page:pic"://图片
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    DispatchQueue.main.sync {
                        if status != .authorized {
                            JCAlertView.bulid().setTitle("无权限访问照片").setMessage("请在设备的设置中允许访问照片。").setDelegate(self).addCancelButton("好的").addButton("去设置").setTag(10001).show()
                        } else {
                            self._pushToSelectPhotos()
                        }
                    }
                })
            } else {
                _pushToSelectPhotos()
            }
        case "page:camera"://相机
            present(imagePicker, animated: true, completion: nil)
        case "page:video_s"://录像
            present(videoPicker, animated: true, completion: nil)
        case "page:location"://地理位置
            let vc = JCAddMapViewController()
            vc.addressBlock = { (dict: Dictionary?) in
                if dict != nil {
                    let lon = Float(dict?["lon"] as! String)
                    let lat = Float(dict?["lat"] as! String)
                    let address = dict?["address"] as! String
                    self.send(address: address, lon: NSNumber(value: lon!), lat: NSNumber(value: lat!))
                }
            }
            navigationController?.pushViewController(vc, animated: true)
        case "page:businessCard"://个人名片
            let vc = FriendsBusinessCardViewController()
            vc.conversation = conversation
            let nav = JCNavigationController(rootViewController: vc)
            present(nav, animated: true, completion: {
                self.toolbar.isHidden = true
            })
        default:
            break
        }
    }
    
    open override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

// MARK: - UIImagePickerControllerDelegate & YHPhotoPickerViewControllerDelegate
// 图片选择
extension JCChatViewController: YHPhotoPickerViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func selectedPhotoBeyondLimit(_ count: Int32, currentView view: UIView!) {
        MBProgressHUD_JChat.show(text: "最多选择\(count)张图片", view: nil)
    }
    
    func yhPhotoPickerViewController(_ PhotoPickerViewController: YHSelectPhotoViewController!, selectedPhotos photos: [Any]!) {
        for item in photos {
            guard let photo = item as? UIImage else {
                return
            }
            DispatchQueue.main.async {
                self.send(forImage: photo)
            }
        }
    }
    
    //选择取消
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage?
        if let image = image?.fixOrientation() {
            send(forImage: image)
        }
        let videoUrl = info[UIImagePickerControllerMediaURL] as! URL?
        if videoUrl != nil {
            let data = try! Data(contentsOf: videoUrl!)
            send(fileData: data)
        }
    }
}

// MARK: - JCMessageDelegate
// 消息的处理
extension JCChatViewController: JCMessageDelegate {

    //视频消息，则播放视频
    func message(message: JCMessageType, videoData data: Data?) {
        if let data = data {
            JCVideoManager.playVideo(data: data, currentViewController: self)
        }
    }
    
    //地理信息消息，则打开地图组件
    func message(message: JCMessageType, location address: String?, lat: Double, lon: Double) {
        let vc = JCAddMapViewController()
        vc.isOnlyShowMap = true
        vc.lat = lat
        vc.lon = lon
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //图片消息，则打开图片预览
    func message(message: JCMessageType, image: UIImage?) {
        let browserImageVC = JCImageBrowserViewController()
        browserImageVC.messages = messages
        browserImageVC.conversation = conversation
        browserImageVC.currentMessage = message
        present(browserImageVC, animated: true) {
            self.toolbar.isHidden = true
        }
    }
    
    //文件消息，下载文件
    func message(message: JCMessageType, fileData data: Data?, fileName: String?, fileType: String?) {
        if data == nil {//如果数据为空，则进入文件下载
            let vc = JCFileDownloadViewController()
            vc.title = fileName
            let msg = conversation.message(withMessageId: message.msgId)
            vc.fileSize = msg?.ex.fileSize
            vc.message = msg
            navigationController?.pushViewController(vc, animated: true)
        } else {
            guard let fileType = fileType else {
                return
            }
            let msg = conversation.message(withMessageId: message.msgId)!
            let content = msg.content as! JMSGFileContent
            switch fileType.fileFormat() {
            case .document://文档类型
                let vc = JCDocumentViewController()
                vc.title = fileName
                vc.fileData = data
                vc.filePath = content.originMediaLocalPath
                vc.fileType = fileType
                navigationController?.pushViewController(vc, animated: true)
            case .video, .voice://视频或语音类型
                let url = URL(fileURLWithPath: content.originMediaLocalPath ?? "")
                try! JCVideoManager.playVideo(data: Data(contentsOf: url), fileType, currentViewController: self)
            case .photo://照片类型
                let browserImageVC = JCImageBrowserViewController()
                let image = UIImage(contentsOfFile: content.originMediaLocalPath ?? "")
                browserImageVC.imageArr = [image!]
                browserImageVC.imgCurrentIndex = 0
                present(browserImageVC, animated: true) {
                    self.toolbar.isHidden = true
                }
            default://url类型
                let url = URL(fileURLWithPath: content.originMediaLocalPath ?? "")
                documentInteractionController.url = url
                documentInteractionController.presentOptionsMenu(from: .zero, in: self.view, animated: true)
            }
        }
    }

    //用户名片消息，展示用户信息
    func message(message: JCMessageType, user: JMSGUser?, businessCardName: String, businessCardAppKey: String) {
        if let user = user {
            let vc = JCUserInfoViewController()
            vc.user = user
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    //提示点击
    func clickTips(message: JCMessageType) {
        currentMessage = message
        let alertView = UIAlertView(title: "重新发送", message: "是否重新发送该消息？", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "发送")
        alertView.show()
    }
    
    //头像点击，显示用户信息界面
    func tapAvatarView(message: JCMessageType) {
        toolbar.resignFirstResponder()
        if message.options.alignment == .right {
            navigationController?.pushViewController(JCMyInfoViewController(), animated: true)
        } else {
            let vc = JCUserInfoViewController()
            vc.user = message.sender
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    //长按用户头像，消息回复框出现@xxx
    func longTapAvatarView(message: JCMessageType) {
        if !isGroup || message.options.alignment == .right {
            return
        }
        toolbar.becomeFirstResponder()
        if let user = message.sender {
            toolbar.text.append("@")
            handleAt(toolbar, NSMakeRange(toolbar.text.length - 1, 0), user, false, user.displayName().length)
        }
    }

    //未读人数提示点击，则显示未读人列表界面
    func tapUnreadTips(message: JCMessageType) {
        let vc = UnreadListViewController()
        let msg = conversation.message(withMessageId: message.msgId)
        vc.message = msg
        navigationController?.pushViewController(vc, animated: true)
    }
}

//消息界面的事件处理
extension JCChatViewController: JCChatViewDelegate {
    
    //刷新聊天界面
    func refershChatView( chatView: JCChatView) {
        messagePage += 1
        _loadMessage(messagePage)
        chatView.stopRefresh()
    }
    
    //删除消息
    func deleteMessage(message: JCMessageType) {
        conversation.deleteMessage(withMessageId: message.msgId)
        if let index = messages.index(message) {
            jMessageCount -= 1
            messages.remove(at: index)
            if let message = messages.last {
                if message.content is JCMessageTimeLineContent {
                    messages.removeLast()
                    chatView.remove(at: messages.count)
                }
            }
        }
    }
    
    //发送名片或转发消息
    func forwardMessage(message: JCMessageType) {
        if let message = conversation.message(withMessageId: message.msgId) {
            let vc = JCForwardViewController()
            vc.message = message
            let nav = JCNavigationController(rootViewController: vc)
            self.present(nav, animated: true, completion: {
                self.toolbar.isHidden = true
            })
        }
    }
    
    //撤回消息
    func withdrawMessage(message: JCMessageType) {
        guard let message = conversation.message(withMessageId: message.msgId) else {
            return
        }
        JMSGMessage.retractMessage(message, completionHandler: { (result, error) in
            if error == nil {
                if let index = self.messages.index(message) {
                    let msg = self._parseMessage(self.conversation.message(withMessageId: message.msgId)!, false)
                    self.messages[index] = msg
                    self.chatView.update(msg, at: index)
                }
            } else {
                MBProgressHUD_JChat.show(text: "发送时间过长，不能撤回", view: self.view)
            }
        })
    }

    //
    func indexPathsForVisibleItems(chatView: JCChatView, items: [IndexPath]) {
        for item in items {
            if item.row <= minIndex {
                var msgs: [JCMessage] = []
                for index in item.row...minIndex  {
                    msgs.append(messages[index])
                }
                updateUnread(msgs)
                minIndex = item.row
            }
        }
    }

    //更新未读数
    fileprivate func updateUnread(_ messages: [JCMessage]) {
        for message in messages {
            if message.options.alignment != .left {
                continue
            }
            if let msg = conversation.message(withMessageId: message.msgId) {
                if msg.isHaveRead {
                    continue
                }
                msg.setMessageHaveRead({ _ in

                })
            }
        }
    }
}

//扩展 弹出框
extension JCChatViewController: UIAlertViewDelegate {

    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 10001 {
            if buttonIndex == 1 {
                JCAppManager.openAppSetter()
            }
            return
        }
        switch buttonIndex {
        case 1:
            if let index = messages.index(currentMessage) {
                messages.remove(at: index)
                chatView.remove(at: index)
                let msg = conversation.message(withMessageId: currentMessage.msgId)
                currentMessage.options.state = .sending

                if let msg = msg {
                    if let content = currentMessage.content as? JCMessageImageContent,
                        let imageContent = msg.content as? JMSGImageContent
                    {
                        imageContent.uploadHandler = {  (percent:Float, msgId:(String?)) -> Void in
                            content.upload?(percent)
                        }
                    }
                }
                messages.append(currentMessage as! JCMessage)
                chatView.append(currentMessage)
                conversation.send(msg!, optionalContent: JMSGOptionalContent.ex.default)
                chatView.scrollToLast(animated: true)
            }
        default:
            break
        }
    }
}

// MARK: - SAIInputBarDelegate & SAIInputBarDisplayable
// 输入框
extension JCChatViewController: SAIInputBarDelegate, SAIInputBarDisplayable {
    
    open override var inputAccessoryView: UIView? {
        return toolbar
    }
    open var scrollView: SAIInputBarScrollViewType {
        return chatView
    }
    open override var canBecomeFirstResponder: Bool {
        return true
    }
    
    open func inputView(with item: SAIInputItem) -> UIView? {
        if let view = inputViews[item.identifier] {
            return view
        }
        switch item.identifier {
        case "kb:emoticon"://表情
            let view = JCEmoticonInputView()
            view.delegate = self
            view.dataSource = self
            inputViews[item.identifier] = view
            return view
        case "kb:toolbox"://工具
            let view = SAIToolboxInputView()
            view.delegate = self
            view.dataSource = self
            inputViews[item.identifier] = view
            return view
        default:
            return nil
        }
    }
    
    //设置输入内容大小
    open func inputViewContentSize(_ inputView: UIView) -> CGSize {
        return CGSize(width: view.frame.width, height: 216)
    }
    
    func inputBar(_ inputBar: SAIInputBar, shouldDeselectFor item: SAIInputItem) -> Bool {
        return true
    }
    
    open func inputBar(_ inputBar: SAIInputBar, shouldSelectFor item: SAIInputItem) -> Bool {
        if item.identifier == "kb:audio" {
            return true
        }
        guard let _ = inputView(with: item) else {
            return false
        }
        return true
    }
    
    
    open func inputBar(_ inputBar: SAIInputBar, didSelectFor item: SAIInputItem) {
        inputItem = item
        
        if item.identifier == "kb:audio" {
            inputBar.deselectBarAllItem()
            return
        }
        if let kb = inputView(with: item) {
            inputBar.setInputMode(.selecting(kb), animated: true)
        }
    }
    open func inputBar(didChangeMode inputBar: SAIInputBar) {
        if inputItem?.identifier == "kb:audio" {
            return
        }
        if let item = inputItem, !inputBar.inputMode.isSelecting {
            inputBar.deselectBarItem(item, animated: true)
        }
    }
    
    open func inputBar(didChangeText inputBar: SAIInputBar) {
        _emoticonSendBtn.isEnabled = inputBar.attributedText.length != 0
    }
    
    public func inputBar(shouldReturn inputBar: SAIInputBar) -> Bool {
        if inputBar.attributedText.length == 0 {
            return false
        }
        send(forText: inputBar.attributedText)
        inputBar.attributedText = nil
        return false
    }
    
    func inputBar(_ inputBar: SAIInputBar, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let currentIndex = range.location
        if !isGroup {
            return true
        }
        if string == "@" {
            //打开@的会员选择
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                let vc = JCRemindListViewController()
                vc.finish = { (user, isAtAll, length) in
                    self.handleAt(inputBar, range, user, isAtAll, length)
                }
                vc.group = self.conversation.target as? JMSGGroup
                let nav = JCNavigationController(rootViewController: vc)
                self.present(nav, animated: true, completion: {})
            }
        } else {
            return updateRemids(inputBar, string, range, currentIndex)
        }
        return true
    }

    func handleAt(_ inputBar: SAIInputBar, _ range: NSRange, _ user: JMSGUser?, _ isAtAll: Bool, _ length: Int) {
        let text = inputBar.text!
        let currentIndex = range.location
        var displayName = "所有成员"

        if let user = user {
            displayName = user.displayName()
        }
        let remind = JCRemind(user, currentIndex, currentIndex + 2 + displayName.length, displayName.length + 2, isAtAll)
        if text.length == currentIndex + 1 {
            inputBar.text = text + displayName + " "
        } else {
            let index1 = text.index(text.endIndex, offsetBy: currentIndex - text.length + 1)
            let range1 = text.startIndex..<index1
            let prefix = text.substring(with: range1)
            let index2 = text.index(text.startIndex, offsetBy: currentIndex + 1)
            let range2 = index2..<text.endIndex
            let suffix = text.substring(with: range2)
            inputBar.text = prefix + displayName + " " + suffix
            let _ = self.updateRemids(inputBar, "@" + displayName + " ", range, currentIndex)
        }
        self.reminds.append(remind)
        self.reminds.sort(by: { (r1, r2) -> Bool in
            return r1.startIndex < r2.startIndex
        })
    }
    
    func updateRemids(_ inputBar: SAIInputBar, _ string: String, _ range: NSRange, _ currentIndex: Int) -> Bool {
        for index in 0..<reminds.count {
            let remind = reminds[index]
            let length = remind.length
            let startIndex = remind.startIndex
            let endIndex = remind.endIndex
            // Delete
            if currentIndex == endIndex - 1 && string.length == 0 {
                for _ in 0..<length {
                    inputBar.deleteBackward()
                }
                // Move Other Index
                for subIndex in (index + 1)..<reminds.count {
                    let subTemp = reminds[subIndex]
                    subTemp.startIndex -= length
                    subTemp.endIndex -= length
                }
                reminds.remove(at: index)
                return false;
            } else if currentIndex > startIndex && currentIndex < endIndex {
                // Delete Content
                if string.length == 0 {
                    for subIndex in (index + 1)..<reminds.count {
                        let subTemp = reminds[subIndex]
                        subTemp.startIndex -= 1
                        subTemp.endIndex -= 1
                    }
                    reminds.remove(at: index)
                    return true
                }
                // Add Content
                else {
                    for subIndex in (index + 1)..<reminds.count {
                        let subTemp = reminds[subIndex]
                        subTemp.startIndex += string.length
                        subTemp.endIndex += string.length
                    }
                    reminds.remove(at: index)
                    return true
                }
            }
        }
        for index in 0..<reminds.count {
            let tempDic = reminds[index]
            let startIndex = tempDic.startIndex
            if currentIndex <= startIndex {
                if string.length == 0 {
                    for subIndex in index..<reminds.count {
                        let subTemp = reminds[subIndex]
                        subTemp.startIndex -= 1
                        subTemp.endIndex -= 1
                    }
                    return true
                } else {
                    for subIndex in index..<reminds.count {
                        let subTemp = reminds[subIndex]
                        subTemp.startIndex += string.length
                        subTemp.endIndex += string.length
                    }
                    return true
                }
            }
        }
        return true
    }
    
    func inputBar(touchDown recordButton: UIButton, inputBar: SAIInputBar) {
        if recordingHub != nil {
            recordingHub.removeFromSuperview()
        }
        recordingHub = JCRecordingView(frame: CGRect.zero)
        recordHelper.updateMeterDelegate = recordingHub
        recordingHub.startRecordingHUDAtView(view)
        recordingHub.frame = CGRect(x: view.centerX - 70, y: view.centerY - 70, width: 136, height: 136)
        recordHelper.startRecordingWithPath(String.getRecorderPath()) { _ in
        }
    }
    
    func inputBar(dragInside recordButton: UIButton, inputBar: SAIInputBar) {
        recordingHub.pauseRecord()
    }
    
    func inputBar(dragOutside recordButton: UIButton, inputBar: SAIInputBar) {
        recordingHub.resaueRecord()
    }
    
    func inputBar(touchUpInside recordButton: UIButton, inputBar: SAIInputBar) {
        if recordHelper.recorder ==  nil {
            return
        }
        recordHelper.finishRecordingCompletion()
        if (recordHelper.recordDuration! as NSString).floatValue < 1 {
            recordingHub.showErrorTips()
            let time: TimeInterval = 1.5
            let hub = recordingHub
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                hub?.removeFromSuperview()
            }
            return
        } else {
            recordingHub.removeFromSuperview()
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: recordHelper.recordPath!))
        send(voiceData: data, duration: Double(recordHelper.recordDuration!)!)
    }
    
    func inputBar(touchUpOutside recordButton: UIButton, inputBar: SAIInputBar) {
        recordHelper.cancelledDeleteWithCompletion()
        recordingHub.removeFromSuperview()
    }
}

// MARK: - JCRecordVoiceHelperDelegate
// 录音
extension JCChatViewController: JCRecordVoiceHelperDelegate {
    public func beyondLimit(_ time: TimeInterval) {
        recordHelper.finishRecordingCompletion()
        recordingHub.removeFromSuperview()
        let data = try! Data(contentsOf: URL(fileURLWithPath: recordHelper.recordPath!))
        send(voiceData: data, duration: Double(recordHelper.recordDuration!)!)
    }
}

//手势识别
extension JCChatViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {
            return true
        }
        if view.isKind(of: JCMessageTextContentView.self) {
            return false
        }
        return true
    }
}

//电子文档
extension JCChatViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.frame
    }
}
