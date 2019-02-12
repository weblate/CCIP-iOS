//
//  IRCViewController.swift
//  OPass
//
//  Created by 腹黒い茶 on 2018/11/5.
//  Copyright © 2018 OPass. All rights reserved.
//

import Foundation

class IRCViewController : OPassWebViewController, OPassWebViewIB {
    @IBOutlet var goReloadButton: UIBarButtonItem?
    @IBOutlet var goBackButton: UIBarButtonItem?
    @IBOutlet var goForwardButton: UIBarButtonItem?
    
    @IBAction override func reload(_ sender: Any) {
        super.reload(sender);
    }
    
    @IBAction override func goBack(_ sender: Any) {
        super.goBack(sender);
    }
    
    @IBAction override func goForward(_ sender: Any) {
        super.goForward(sender);
    }
    
    var titleTextColor: String = "IRCTitleTextColor";
    var titleLeftColor: String = "IRCTitleLeftColor";
    var titleRightColor: String = "IRCTitleRightColor";
    var PageUrl: String = Constants.URL_LOG_BOT;
    var ShowLogo: Bool = true;
}