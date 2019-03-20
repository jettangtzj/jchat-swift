//
//  AppDelegate.swift
//  JChat
//
//  Created by deng on 2017/2/16.
//  Copyright © 2017年 HXHG. All rights reserved.
//
import UIKit
import JMessage
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let JMAPPKEY = "51f20827335dfeeed460d842"
    // 百度地图 SDK AppKey，请自行申请你对应的 AppKey
    let BMAPPKEY = "yDRGI5wvCKFjb0eUo3lLhvrA9iCGQg9S"
    
    var _mapManager: BMKMapManager?
    
    fileprivate var hostReachability: Reachability!
    
    var player:AVAudioPlayer = AVAudioPlayer()
    
    deinit {
        hostReachability.stopNotifier()
    }
    
    //MARK: - life cycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        #if READ_VERSION
        print("-------------READ_VERSION------------")
        print("如果不需要支持已读未读功能")
        print("在 Build Settings 中，找到 Swift Compiler - Custom Flags，并在其中的 Other Swift Flags 删除 -D READ_VERSION")
        print("-------------------------------------")
        #endif
        
        //        DispatchQueue.main.async {
        //            if let window = self.window {
        //                let label = JCFPSLabel(frame: CGRect(x: window.bounds.width - 55 - 8, y: 10, width: 55, height: 20))
        //                label.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        //                window.addSubview(label)
        //                window.backgroundColor = .white
        //            }
        //        }
        if #available(iOS 11.0, *) {
            UITableView.appearance().estimatedRowHeight = 0
            UITableView.appearance().estimatedSectionFooterHeight = 0
            UITableView.appearance().estimatedSectionHeaderHeight = 0
        }
        
        JMessage.setupJMessage(launchOptions, appKey: JMAPPKEY, channel: nil, apsForProduction: true, category: nil, messageRoaming: true)
        _setupJMessage()
        
        _mapManager = BMKMapManager()
        BMKMapManager.setCoordinateTypeUsedInBaiduMapSDK(BMK_COORDTYPE_BD09LL)
        _mapManager?.start(BMAPPKEY, generalDelegate: nil)
        
        hostReachability = Reachability(hostName: "www.apple.com")
        hostReachability.startNotifier()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        _setupRootViewController()
        window?.makeKeyAndVisible()
        musicplay()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        JMessage.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void){
        let status = application.applicationState
        switch status {
        case .active:
            NSLog("在前台收到推送")
            break
        case .inactive:
            NSLog("后台->前台")
            break
        case .background:
            NSLog("后台")
            JMSGConversation.allConversations { (result, error) in
                
            }
            break
        }
        completionHandler(.newData)
    }
    
    var backgroundTask:UIBackgroundTaskIdentifier! = nil
    var timer:Timer! = nil
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("进入后台")
        resetBadge(application)
        //如果已存在后台任务，先将其设为完成
        if self.backgroundTask != nil {
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
        self.backgroundTask = application.beginBackgroundTask(expirationHandler: {
            () -> Void in
            //如果没有调用endBackgroundTask，时间耗尽时应用程序将被终止
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        })
        //创建定时任务
        timer = Timer.scheduledTimer(timeInterval: 10,target:self,selector:#selector(taskWork),
                                         userInfo:nil,repeats:true)
        timer.fire()
    }
    
    var missionNO = 0
    func taskWork(){
        missionNO += 1
        NSLog("========启动定时任务\(missionNO)")
//        JMSGConversation.allConversations { (result, error) in
//
//        }
    }
    
    //音乐播放-消声
    func musicplay(){
        do
        {
            let audioPath = Bundle.main.path(forResource: "song", ofType: "mp3")
            try player = AVAudioPlayer(contentsOf: NSURL(fileURLWithPath: audioPath!) as URL)
        }
        catch
        {
            NSLog("play error")
        }
        
        let session = AVAudioSession.sharedInstance()
        
        do
        {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        }
        catch
        {
            NSLog("play error")
        }
        //无限循环
        player.numberOfLoops = -1
        //音量
        player.volume = 0.0
        player.play()
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        NSLog("即将进入前台")
        resetBadge(application)
        if timer != nil {
            missionNO = 0
            timer.invalidate()
        }
        if !player.isPlaying {
            player.play()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        NSLog("取消激活")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NSLog("程序被激活")
    }
    
    
    
    
    // MARK: - private func
    private func _setupJMessage() {
        JMessage.add(self, with: nil)
        //        JMessage.setLogOFF()
        JMessage.setDebugMode()
        if #available(iOS 8, *) {
            JMessage.register(
                forRemoteNotificationTypes: UIUserNotificationType.badge.rawValue |
                    UIUserNotificationType.sound.rawValue |
                    UIUserNotificationType.alert.rawValue,
                categories: nil)
        } else {
            // iOS 8 以前 categories 必须为nil
            JMessage.register(
                forRemoteNotificationTypes: UIRemoteNotificationType.badge.rawValue |
                    UIRemoteNotificationType.sound.rawValue |
                    UIRemoteNotificationType.alert.rawValue,
                categories: nil)
        }
    }
    
    private func _setupRootViewController() {
        if UserDefaults.standard.object(forKey: kCurrentUserName) != nil {
            window?.rootViewController = JCMainTabBarController()
        } else {
            let nav = JCNavigationController(rootViewController: JCLoginViewController())
            window?.rootViewController = nav
        }
    }
    
    private func resetBadge(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        JMessage.resetBadge()
    }
}

//MARK: - JMessage Delegate
extension AppDelegate: JMessageDelegate {
    //数据库升级
    func onDBMigrateStart() {
        MBProgressHUD_JChat.showMessage(message: "数据库升级中", toView: nil)
    }
    
    //数据库升级结束
    func onDBMigrateFinishedWithError(_ error: Error!) {
        MBProgressHUD_JChat.hide(forView: nil, animated: true)
        MBProgressHUD_JChat.show(text: "数据库升级完成", view: nil)
    }
    
    
    
    func onReceive(_ event: JMSGNotificationEvent!) {
        switch event.eventType {
        case .receiveFriendInvitation, .acceptedFriendInvitation, .declinedFriendInvitation:
            cacheInvitation(event: event)
        case .loginKicked, .serverAlterPassword, .userLoginStatusUnexpected:
            _logout()
        case .deletedFriend, .receiveServerFriendUpdate:
            NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateFriendList), object: nil)
        default:
            break
        }
    }
    
    private func cacheInvitation(event: JMSGNotificationEvent) {
        let friendEvent =  event as! JMSGFriendNotificationEvent
        let user = friendEvent.getFromUser()
        let reason = friendEvent.getReason()
        let info = JCVerificationInfo.create(username: user!.username, nickname: user?.nickname, appkey: user!.appKey!, resaon: reason, state: JCVerificationType.wait.rawValue)
        switch event.eventType {
        case .receiveFriendInvitation:
            info.state = JCVerificationType.receive.rawValue
            JCVerificationInfoDB.shareInstance.insertData(info)
        case .acceptedFriendInvitation:
            info.state = JCVerificationType.accept.rawValue
            JCVerificationInfoDB.shareInstance.updateData(info)
            NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateFriendList), object: nil)
        case .declinedFriendInvitation:
            info.state = JCVerificationType.reject.rawValue
            JCVerificationInfoDB.shareInstance.updateData(info)
        default:
            break
        }
        if UserDefaults.standard.object(forKey: kUnreadInvitationCount) != nil {
            let count = UserDefaults.standard.object(forKey: kUnreadInvitationCount) as! Int
            UserDefaults.standard.set(count + 1, forKey: kUnreadInvitationCount)
        } else {
            UserDefaults.standard.set(1, forKey: kUnreadInvitationCount)
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: kUpdateVerification), object: nil)
    }
    
    func _logout() {
        JCVerificationInfoDB.shareInstance.queue = nil
        UserDefaults.standard.removeObject(forKey: kCurrentUserName)
        let alertView = UIAlertView(title: "您的账号在其它设备上登录", message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "重新登录")
        alertView.show()
    }
}

extension AppDelegate: UIAlertViewDelegate {
    
    private func pushToLoginView() {
        UserDefaults.standard.removeObject(forKey: kCurrentUserPassword)
        if let appDelegate = UIApplication.shared.delegate,
            let window = appDelegate.window {
            window?.rootViewController = JCNavigationController(rootViewController: JCLoginViewController())
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {
            guard let username = UserDefaults.standard.object(forKey: kLastUserName) as? String  else {
                pushToLoginView()
                return
            }
            guard let password = UserDefaults.standard.object(forKey: kCurrentUserPassword) as? String else {
                pushToLoginView()
                return
            }
            MBProgressHUD_JChat.showMessage(message: "登录中", toView: nil)
            JMSGUser.login(withUsername: username, password: password) { (result, error) in
                MBProgressHUD_JChat.hide(forView: nil, animated: true)
                if error == nil {
                    UserDefaults.standard.set(username, forKey: kLastUserName)
                    UserDefaults.standard.set(username, forKey: kCurrentUserName)
                    UserDefaults.standard.set(password, forKey: kCurrentUserPassword)
                } else {
                    self.pushToLoginView()
                    MBProgressHUD_JChat.show(text: "\(String.errorAlert(error! as NSError))", view: self.window?.rootViewController?.view, 2)
                }
            }
        } else {
            pushToLoginView()
        }
    }
}
