//
//  AppDelegate.swift
//  MGTextPlus
//
//  Created by Tuan Truong on 10/26/16.
//  Copyright © 2016 Tuan Truong. All rights reserved.
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var webView: WKWebView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.stringValue = version
        }
        
        if let url = Bundle.main.url(forResource: "info", withExtension: "html") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
   
    @IBAction func openGithub(_ sender: Any) {
        if let url = URL(string: "https://github.com/tuan188/MGTextPlus"), NSWorkspace.shared().open(url) {
            print("default browser was successfully opened")
        }
    }
    
    @IBAction func close(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }
    
}

