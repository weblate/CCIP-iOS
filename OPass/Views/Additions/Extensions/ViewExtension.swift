//
//  ViewExtension.swift
//  OPass
//
//  Created by 張智堯 on 2022/5/3.
//  2022 OPass.
//

import SwiftUI

extension View {
    func LocalizeIn<T>(zh: T, en: T) -> T {
        if Bundle.main.preferredLocalizations[0] ==  "zh-Hant" { return zh }
        else { return en }
    }
    
    func processURL(_ rawURL: URL) -> URL? {
        var result: URL? = rawURL
        if !rawURL.absoluteString.lowercased().hasPrefix("http") {
            result = URL(string: "http://" + rawURL.absoluteString)
        }
        return result
    }
}