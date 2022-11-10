//
//  StringExtension.swift
//  Oculo
//
//  Created by 최윤석 on 2022/11/10.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation

// 출처: https://medium.com/@PhiJay/why-swift-enums-with-associated-values-cannot-have-a-raw-value-21e41d5ec11

protocol Localizable: Identifiable, CaseIterable, RawRepresentable where RawValue: StringProtocol {}

extension Localizable {
    
    var localized: String {
        NSLocalizedString(String(rawValue), comment: "")
    }
    
    var id: String {
        String(self.rawValue)
    }
}

enum Language: String, Localizable {
    // Main View
    case navigation = "Navigation"
    case environmentReader = "Environment Reader"
    case textReader = "Text Reader"
    case settings = "Settings"
    // Settings View
    case membership = "Membership"
    case agreement =  "Agreement on sending recorded video"
    case arrangement = "Terms of arrangement"
    case privacy = "Privacy"
    case license = "License"
    case contactUS = "Contact Us"
}
