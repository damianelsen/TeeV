//
//  NotificationController.swift
//  TeeV
//
//  Created by Damian Elsen on 12/12/25.
//

import Foundation
import SwiftUI
import SwiftData

class NotificationController {
    private var center: UNUserNotificationCenter!
    private var settings: UNNotificationSettings!
    private let modelContext: ModelContext

    init(modelContext: ModelContext) async {
        self.center = UNUserNotificationCenter.current()
        self.settings = await center.notificationSettings()
        self.modelContext = modelContext
    }
    
    func createNotificationFor(episode: Episode) async {
        guard ( settings.authorizationStatus == .authorized ) else { return }
        guard ( self.episodeHasNotAiredFor(episode: episode) ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Episode of \(episode.season.show.name)"
        content.body = "S\(episode.season.seasonNumber) E\(episode.episodeNumber) \(episode.name) airs today."
        content.sound = .default
        
        let triggerDate = createTriggerDateFrom(airDate: episode.airDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try? await center.add(request)
        print("Added notification for \(episode.season.show.name) S\(episode.season.seasonNumber) E\(episode.episodeNumber) \(episode.name) with trigger date \(Calendar.current.date(from: triggerDate)!)")
        
        await self.updateNotificationBadgeCounts()
        
        episode.notificationId = identifier
    }
    
    func updateNotificationBadgeCounts() async {
        let unwatchedEpisodes = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { episode in
            !episode.watched
        }))

        for notification in await center.pendingNotificationRequests() {
            let notificationTrigger = notification.trigger as! UNCalendarNotificationTrigger
            let episodesNotAired = unwatchedEpisodes!
                .map({ self.createTriggerDateFrom(airDate: $0.airDate) })
                .map({ Calendar.current.date(from: $0)! })
                .filter({ $0 <= notificationTrigger.nextTriggerDate()! })
                .count
            
            let content = UNMutableNotificationContent()
            content.title = notification.content.title
            content.body = notification.content.body
            content.sound = notification.content.sound
            content.badge = episodesNotAired as NSNumber

            let request = UNNotificationRequest(
                identifier: notification.identifier,
                content: content,
                trigger: notification.trigger
            )
            
            try? await center.add(request)
        }
    }
    
    func deleteNotificationFor(episode: Episode) {
        guard ( episode.notificationId != nil ) else { return }
        
        center.removePendingNotificationRequests(withIdentifiers: [episode.notificationId!])
        
        episode.notificationId = nil
    }
    
    private func episodeHasNotAiredFor(episode: Episode) -> Bool {
        return max(getDaysBetween(from: getNowAtUtcMidnight(), to: episode.airDate), 0) > 0
    }
    
    private func createTriggerDateFrom(airDate: Date) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let notificationDate = calendar.dateComponents(
//            [.timeZone, .year, .month, .day, .hour, .minute],
            [.year, .month, .day],
//            from: calendar.date(byAdding: .day, value: 1, to: airDate)!
            from: airDate
        )
        
        var triggerDate = DateComponents()
        triggerDate.timeZone = Calendar.current.timeZone
        triggerDate.year = notificationDate.year
        triggerDate.month = notificationDate.month
        triggerDate.day = notificationDate.day
        triggerDate.hour = 17
        triggerDate.minute = 0
        triggerDate.isLeapMonth = notificationDate.isLeapMonth
        
        return triggerDate
    }
}
