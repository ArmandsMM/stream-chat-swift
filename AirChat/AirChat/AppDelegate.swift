//
//  AppDelegate.swift
//  AirChat
//
//  Created by Vojta on 14/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let client = Client()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let navVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let chatVC = navVC.viewControllers.first as! ChatViewController
        
        chatVC.channelRef = client.channelReference(id: "chat_with_bahadir")
        
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()
        
        return true
    }
}

