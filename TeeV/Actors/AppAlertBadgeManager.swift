//
//  AppAlertBadgeManager.swift
//  TeeV
//
//  Created by Damian Elsen on 12/12/25.
//

import SwiftUI

@MainActor
protocol BadgeNumberProvidable: AnyObject {
    var applicationIconBadgeNumber: Int { get set }
}

extension UIApplication: BadgeNumberProvidable {}

actor AppAlertBadgeManager {
    
    let application: BadgeNumberProvidable
    
    init(application: BadgeNumberProvidable) {
        self.application = application
    }
    
    func setAlertBadge(number: Int) async {
        await MainActor.run {
            application.applicationIconBadgeNumber = number
        }
    }
}

