//
//  ScaleMateApp.swift
//  ScaleMate
//
//  Created by Anton Schwartz on 11/3/20.
//  Copyright © 2020 Anton Schwartz. All rights reserved.
//

import SwiftUI


@main
struct MarkdownTestApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//	@StateObject var vm = ViewModel()

	var body: some Scene {
		WindowGroup {
			MainView() //.environmentObject(vm)
		}
	}
}


class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
//		sleep(20)		// useful when testing startup screen!

		return true
	}

}
