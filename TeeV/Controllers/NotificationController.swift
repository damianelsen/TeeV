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
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.center = UNUserNotificationCenter.current()
        self.modelContext = modelContext
    }
    
    func requestNotificationAuthorization() {
        self.center.requestAuthorization(options: [.alert, .badge, .sound]) { (_, _) in }
    }
    
    func createNotification(for episode: Episode) async {
        let settings = await center.notificationSettings()

        guard ( settings.authorizationStatus == .authorized ) else { return }
        guard ( self.episodeHasNotAired(for: episode) ) else { return }
        guard ( self.dailyShowEpisodeNotHostedByJonStewart(episode: episode) ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Episode of \(episode.season.show.name)"
        content.body = "S\(episode.season.seasonNumber) E\(episode.episodeNumber) \(episode.name) airs today."
        content.sound = .default
        
        let triggerDate = createTriggerDate(from: episode.airDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try? await center.add(request)        
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
                .map({ self.createTriggerDate(from: $0.airDate) })
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
    
    func setAppBadgeCount(to number: Int) async {
        do {
            try await self.center.setBadgeCount(number)
        } catch {
            print("Error setting the badge count to \(number): \(error)")
        }
    }
    
    func deleteNotification(for episode: Episode) {
        guard ( episode.notificationId != nil ) else { return }
        
        center.removePendingNotificationRequests(withIdentifiers: [episode.notificationId!])
        
        episode.notificationId = nil
    }
    
    private func episodeHasNotAired(for episode: Episode) -> Bool {
        return max(getDaysBetween(from: getNowAtUtcMidnight(), to: episode.airDate), 0) > 0
    }
    
    private func dailyShowEpisodeNotHostedByJonStewart(episode: Episode) -> Bool {
        return !(episode.season.show.id == 2224 && episode.hostId == 0)
    }
    
    private func createTriggerDate(from airDate: Date) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let notificationDate = calendar.dateComponents(
            [.year, .month, .day],
            from: airDate
        )
        
        var triggerDate = DateComponents()
        triggerDate.timeZone = Calendar.current.timeZone
        triggerDate.year = notificationDate.year
        triggerDate.month = notificationDate.month
        triggerDate.day = notificationDate.day
        triggerDate.hour = 16
        triggerDate.minute = 0
        triggerDate.isLeapMonth = notificationDate.isLeapMonth
        
        return triggerDate
    }
}
