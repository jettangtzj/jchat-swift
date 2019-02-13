//
//  FileManagerViewController.swift
//  JChat
//
//  聊天文件列表显示
//

import UIKit

protocol FileManagerDelegate {
    func didSelectFile(_ fileMessage: JMessage)
    func isEditModel() -> Bool
}

class FileManagerViewController: UIViewController {
    
    //聊天会话
    var conversation: JMSGConversation!

    override func viewDidLoad() {
        super.viewDidLoad()
        _init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //图片查看
    fileprivate let imageFileViewController = ImageFileViewController()
    //doc文档查看
    fileprivate let docFileViewController =  FileViewController()
    //视频查看
    fileprivate let videoFileViewController =  FileViewController()
    //音频查看
    fileprivate let musicFileViewController =  FileViewController()
    //其他文件查看
    fileprivate let otherFileViewController =  FileViewController()
    
    //全部聊天文件数组
    private var allMessage: [JMSGMessage] = []
    private var imageMessages: [JMSGMessage] = []
    private var docMessages: [JMSGMessage] = []
    private var videoMessages: [JMSGMessage] = []
    private var musicMessages: [JMSGMessage] = []
    private var otherFileMessages: [JMSGMessage] = []
    private var selectMessage: [JMSGMessage] = []

    //距顶
    private var topOffset: CGFloat {
        if isIPhoneX {
//            return 88
            return 112
        }
        return 64
    }
    
    private lazy var tabedSlideView: DLTabedSlideView = {
        var tabedSlideView = DLTabedSlideView(frame: CGRect(x: 0, y: self.topOffset, width: self.view.width, height: self.view.height - self.topOffset))
        tabedSlideView.delegate = self
        tabedSlideView.baseViewController = self
        tabedSlideView.tabItemNormalColor = .black
        tabedSlideView.tabItemSelectedColor =  UIColor(netHex: 0x2DD0CF)
        tabedSlideView.tabbarTrackColor = UIColor(netHex: 0x2DD0CF)
        tabedSlideView.tabbarBackgroundImage = UIImage.createImage(color: .white, size: CGSize(width: self.view.width, height: 39))
        tabedSlideView.tabbarBottomSpacing = 3.0
        return tabedSlideView
    }()
    
    //导航右按钮 选择按钮
    private lazy var navRightButton: UIBarButtonItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(_clickNavRightButton))
    //是否文件可编辑删除状态
    fileprivate var isEditMode = false
    //bar区域
    private lazy var barView: UIView = {
        var barView = UIView(frame: CGRect(x: 0, y: self.view.height - 45, width: self.view.width, height: 45))
        let line = UILabel(frame: CGRect(x: 0, y: 0, width: barView.width, height: 0.5))
        line.layer.backgroundColor = UIColor(netHex: 0xE8E8E8).cgColor
        barView.addSubview(line)
        barView.backgroundColor = .white
        barView.isHidden = true
        return barView
    }()
    //文件删除按钮
    private lazy var delButton: UIButton = {
        var delButton = UIButton()
        delButton.setTitle("删除", for: .normal)
        delButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        delButton.layer.cornerRadius = 3
        delButton.layer.masksToBounds = true
        delButton.addTarget(self, action: #selector(_delFile), for: .touchUpInside)
        delButton.backgroundColor = UIColor(netHex: 0xEB424D)
        return delButton
    }()
    //选择文件数量显示标签
    private lazy var selectCountLabel: UILabel = {
        var label = UILabel(frame: CGRect(x: 17.5, y: 11.5, width: 120, height: 22))
        label.textAlignment = .left
        label.textColor = UIColor(netHex: 0x999999)
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    private func _init() {
        self.title = "聊天文件"
        view.backgroundColor = UIColor(netHex: 0xe8edf3)
        
        view.addSubview(tabedSlideView)
        let imageItem = DLTabedbarItem(title: "照片", image: nil, selectedImage: nil)
        let fileItem = DLTabedbarItem(title: "文档", image: nil, selectedImage: nil)
        let videoItem = DLTabedbarItem(title: "视频", image: nil, selectedImage: nil)
        let musicItem = DLTabedbarItem(title: "音乐", image: nil, selectedImage: nil)
        let otherItem = DLTabedbarItem(title: "其它", image: nil, selectedImage: nil)
        tabedSlideView.tabbarItems = [imageItem!, fileItem!, videoItem!, musicItem!, otherItem!]
        tabedSlideView.buildTabbar()
        tabedSlideView.selectedIndex = 0
        
        view.addSubview(barView)
        barView.addSubview(delButton)
        barView.addSubview(selectCountLabel)
        delButton.frame = CGRect(x: barView.width - 72 - 16.6, y: 8.5, width: 72, height: 29)
        _setupNavigation()
        
        //获取全部聊天文件
        conversation.allMessages({ (result, error) in
            if let message = result as? [JMSGMessage] {
                self.allMessage = message
                self.classifyMessage(message)
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(_didSelectFileMessage), name: NSNotification.Name(rawValue: "kDidSelectFileMessage"), object: nil)
    }
    
    //已选择文件
    func _didSelectFileMessage() {
        selectMessage.removeAll()
        selectMessage.append(contentsOf: imageFileViewController.selectMessages)
        selectMessage.append(contentsOf: docFileViewController.selectMessages)
        selectMessage.append(contentsOf: videoFileViewController.selectMessages)
        selectMessage.append(contentsOf: musicFileViewController.selectMessages)
        selectMessage.append(contentsOf: otherFileViewController.selectMessages)
        
        if selectMessage.count > 0 {
            selectCountLabel.isHidden = false
            selectCountLabel.text = "已选（\(selectMessage.count)）"
        } else {
            selectCountLabel.isHidden = true
        }
    }
    
    //分组和排序文件
    func classifyMessage(_ messages: [JMSGMessage]) {
        docMessages.removeAll()
        videoMessages.removeAll()
        musicMessages.removeAll()
        imageMessages.removeAll()
        otherFileMessages.removeAll()
        for message in messages {
            if message.contentType == .image {
                imageMessages.append(message)
                continue
            }
            if !message.ex.isFile {
                continue
            }
            if let fileType = message.ex.fileType {
                switch fileType.fileFormat() {
                case .document:
                    docMessages.append(message)
                case .video:
                    videoMessages.append(message)
                case .voice:
                    musicMessages.append(message)
                case .photo:
                    imageMessages.append(message)
                default:
                    otherFileMessages.append(message)
                }
            }
        }
        reloadAllFileViewController()
    }
    
    //重新加载文件
    func reloadAllFileViewController() {
        imageFileViewController.messages = imageMessages
        docFileViewController.messages = docMessages
        videoFileViewController.messages = videoMessages
        musicFileViewController.messages = musicMessages
        otherFileViewController.messages = otherFileMessages
        
        imageFileViewController.reloadDate()
        docFileViewController.reloadDate()
        videoFileViewController.reloadDate()
        musicFileViewController.reloadDate()
        otherFileViewController.reloadDate()
    }
    
    //设置导航
    private func _setupNavigation() {
        self.navigationItem.rightBarButtonItem =  navRightButton
    }
    
    //导航按钮事件
    func _clickNavRightButton() {
        if isEditMode {
            navRightButton.title = "选择"
            tabedSlideView.frame = CGRect(x: tabedSlideView.x, y: tabedSlideView.y, width: tabedSlideView.width, height: tabedSlideView.height + 45)
            barView.isHidden = true
        } else {
            navRightButton.title = "取消"
            tabedSlideView.frame = CGRect(x: tabedSlideView.x, y: tabedSlideView.y, width: tabedSlideView.width, height: tabedSlideView.height - 45)
            barView.isHidden = false
        }
        isEditMode = !isEditMode
        imageFileViewController.isEditModel = isEditMode
        otherFileViewController.isEditModel = isEditMode
        videoFileViewController.isEditModel = isEditMode
        musicFileViewController.isEditModel = isEditMode
        docFileViewController.isEditModel = isEditMode
        selectMessage = []
    }
    
    //删除文件操作
    func _delFile() {
        if selectMessage.count <= 0 {
            return
        }
        isEditMode = true
        for message in selectMessage {
            allMessage = allMessage.filter({ (m) -> Bool in
                message.msgId != m.msgId
            })
            //会话中删除该消息
            conversation.deleteMessage(withMessageId: message.msgId)
        }
        //重新分组排序
        classifyMessage(allMessage)
        _clickNavRightButton()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kReloadAllMessage), object: nil)
    }
}


extension FileManagerViewController: DLTabedSlideViewDelegate {
    func numberOfTabs(in sender: DLTabedSlideView!) -> Int {
        return 5
    }
    
    func dlTabedSlideView(_ sender: DLTabedSlideView!, controllerAt index: Int) -> UIViewController! {
        switch index {
        case 0:
            return imageFileViewController
        case 1:
            docFileViewController.fileType = .doc
            return docFileViewController
        case 2:
            videoFileViewController.fileType = .video
            return videoFileViewController
        case 3:
            musicFileViewController.fileType = .music
            return musicFileViewController
        default:
            otherFileViewController.fileType = .other
            return otherFileViewController
        }
    }
}
