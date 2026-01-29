//
//  DataController.swift
//  TeeV
//
//  Created by Damian Elsen on 11/18/25.
//

import Foundation
import SwiftData
import SwiftUI

class DataController {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addNewShow(with id: Int) async throws {
        let shows = try? modelContext.fetch(FetchDescriptor<Show>(predicate: #Predicate {
            show in show.id == id
        }))
        guard (shows?.count == 0) else { return }
        
        let showResponse = try await getShow(with: id)
        let showPoster = try await getPoster(from: showResponse.poster_path)
        let showBackdrop = try await getPoster(from: showResponse.backdrop_path, asBackdrop: true)
        let newShow = self.createNewShow(from: showResponse, withPoster: showPoster, andBackdrop: showBackdrop)
        let notifications = NotificationController(modelContext: modelContext)
        
        for season in showResponse.seasons.filter({$0.season_number > 0}) {
            let seasonResponse = try await getSeason(forShow: id, with: season.season_number)
            let seasonPoster = try await getPoster(from: seasonResponse.poster_path)
            let newSeason = self.createNewSeason(for: newShow, from: seasonResponse, withPoster: seasonPoster)
            
            for episode in seasonResponse.episodes {
                let newEpisode = self.createNewEpisode(for: newSeason, from: episode)
                await notifications.createNotification(for: newEpisode)
                
                newSeason.episodes.append(newEpisode)
            }

            newShow.seasons.append(newSeason)
        }
        
        let firstEpisode = newShow.seasons
            .first(where: { $0.seasonNumber == 1 })!.episodes
            .first(where: { $0.episodeNumber == 1 })
        newShow.nextEpisode = firstEpisode
        newShow.daysToNextEpisode = self.daysUntilBroadcast(for: firstEpisode!)
        
        // Special case for Daily Show episode with no air date
        if (id == 2224) {
            let offendingEpisode = newShow.seasons.first(where: { $0.seasonNumber == 6 })?.episodes.first(where: { $0.episodeNumber == 111 })

            offendingEpisode?.airDate = convertDate(from: "2001-09-17")
        }
    }

    func refreshShows() async throws -> String {
        let shows = try modelContext.fetch(FetchDescriptor<Show>())
        let notifications = NotificationController(modelContext: modelContext)
        var updatedMessage = ""

//        try await withThrowingTaskGroup(of: Void.self) { group in
        for show in shows {
//                group.addTask {
            // Update the show
            let showResponse = try await getShow(with: show.id)
            show.name = showResponse.name
            show.overview = showResponse.overview
            show.poster = try await self.getPoster(from: showResponse.poster_path)
            show.status = showResponse.status
            
            // Update the most recent season
            let mostRecentSeason = show.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })!
            let seasonResponse = try await getSeason(forShow: show.id, with: mostRecentSeason.seasonNumber)
            mostRecentSeason.name = seasonResponse.name
            mostRecentSeason.overview = seasonResponse.overview
            mostRecentSeason.poster = try await self.getPoster(from: seasonResponse.poster_path)
            mostRecentSeason.airDate = seasonResponse.air_date != nil ? convertDate(from: seasonResponse.air_date!) : Date.distantPast

            let mostRecentEpisode = mostRecentSeason.episodes.max(by: { $0.episodeNumber < $1.episodeNumber })
            let mostRecentEpisodeNumber = mostRecentEpisode == nil ? 0 : mostRecentEpisode!.episodeNumber
            let existingEpisodeResponses = seasonResponse.episodes.filter({ $0.episode_number <= mostRecentEpisodeNumber })
            let newEpisodeResponses = seasonResponse.episodes.filter({ $0.episode_number > mostRecentEpisodeNumber })

            // Update the existing episodes
            for existingEpisodeResponse in existingEpisodeResponses {
                let existingEpisode = mostRecentSeason.episodes.first(where: { $0.episodeNumber == existingEpisodeResponse.episode_number })!

                if self.episodeHasChanged(from: existingEpisode, to: existingEpisodeResponse) {
                    notifications.deleteNotification(for: existingEpisode)
                    await notifications.createNotification(for: existingEpisode)
                }
            }

            // Add any new episodes
            for newEpisodeResponse in newEpisodeResponses {
                let newEpisode = self.createNewEpisode(for: mostRecentSeason, from: newEpisodeResponse)
                await notifications.createNotification(for: newEpisode)

                mostRecentSeason.episodes.append(newEpisode)
                mostRecentSeason.watched = false
            }

            // Get and add any mew seasons
            let newSeasonCount = showResponse.number_of_seasons - show.seasonCount
            if showResponse.number_of_seasons > show.seasonCount {
                show.seasonCount = showResponse.number_of_seasons
                
                for seasonNumber in show.seasons.count + 1...show.seasonCount {
                    let seasonResponse = try await getSeason(forShow: show.id, with: seasonNumber)
                    let seasonPoster = try await self.getPoster(from: seasonResponse.poster_path)
                    let newSeason = self.createNewSeason(for: show, from: seasonResponse, withPoster: seasonPoster)
                    
                    for episode in seasonResponse.episodes {
                        let newEpisode = self.createNewEpisode(for: newSeason, from: episode)
                        
                        await notifications.createNotification(for: newEpisode)
                        newSeason.episodes.append(newEpisode)
                    }

                    show.seasons.append(newSeason)
                }
            }
            
            if show.nextEpisode == nil {
                show.nextEpisode = self.getNextUnwatchedEpisode(for: show)
                show.nextEpisodeNumber += show.nextEpisode != nil ? 1 : 0
            }
            show.daysToNextEpisode = show.nextEpisode != nil ? self.daysUntilBroadcast(for: show.nextEpisode!) : TeeVConstants.distantFutureDays

            if newEpisodeResponses.count > 0 || newSeasonCount > 0 {
                updatedMessage += updatedMessage.isEmpty ? "" : "\n"
                updatedMessage += "\(show.name) updated with "
                updatedMessage += newEpisodeResponses.count > 0 ? "\(newEpisodeResponses.count) new episode" : ""
                updatedMessage += newEpisodeResponses.count > 1 ? "s" : ""
                updatedMessage += newEpisodeResponses.count > 0 && newSeasonCount > 0 ? " and " : ""
                updatedMessage += newSeasonCount > 0 ? "\(newSeasonCount) new season" : ""
                updatedMessage += newSeasonCount > 1 ? "s" : ""
                updatedMessage += "."
            }
  //              }
  //          }
  //          try await group.waitForAll()
        }
        
        return updatedMessage
    }
    
    func removeShow(with id: Int) {
        let shows = try? modelContext.fetch(FetchDescriptor<Show>(predicate: #Predicate { show in
            show.id == id
        }))
        guard let show = shows?.first else { return }
        
        let showId = show.id
        let episodes = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { episode in
            episode.season.show.id == showId
        }))

        if let episodes {
            let notificationController = NotificationController(modelContext: modelContext)

            for episode in episodes where episode.notificationId != nil {
                notificationController.deleteNotification(for: episode)
            }
        }
        
        modelContext.delete(show)
    }
    
    func markNextEpisodeAsWatched(for show: Show) {
        let notificationController = NotificationController(modelContext: modelContext)
        
        show.nextEpisode!.watched = true
        show.nextEpisode!.season.watched = show.nextEpisode!.season.episodes.allSatisfy({ $0.watched })
        notificationController.deleteNotification(for: show.nextEpisode!)
        show.nextEpisode = self.getNextUnwatchedEpisode(for: show)
        show.nextEpisodeNumber += show.nextEpisode != nil ? 1 : 0
        show.daysToNextEpisode = show.nextEpisode != nil ? self.daysUntilBroadcast(for: show.nextEpisode!) : TeeVConstants.distantFutureDays
        show.lastWatched = Date.now
        show.started = true
    }
    
    func markAllWatched(for season: Season) {
        let lastEpisode = season.episodes.max(by: { $0.episodeNumber < $1.episodeNumber })!
        
        self.markAllWatched(for: lastEpisode)
    }
    
    func markAllWatched(for episode: Episode) {
        repeat {
            if self.daysUntilBroadcast(for: episode.season.show.nextEpisode!) == 0 {
                self.markNextEpisodeAsWatched(for: episode.season.show)
            } else {
                break
            }
        } while episode.season.show.nextEpisode != episode
        
        if self.daysUntilBroadcast(for: episode.season.show.nextEpisode!) == 0 {
            self.markNextEpisodeAsWatched(for: episode.season.show)
        }
    }
    
    func getTotalUnwatchedEpisodes() -> Int {
        let unwatchedEpisodes = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { episode in
            episode.watched == false
        }))
        
        if let unwatchedEpisodes {
            return unwatchedEpisodes
                .filter({ self.daysUntilBroadcast(for: $0) == 0 })
                .count
        } else {
            return 0
        }
    }

    private func getNextUnwatchedEpisode(for show: Show) -> Episode? {
        let firstSeason = show.seasons.first(where: { $0.seasonNumber == 1 })

        return self.getNextUnwatchedEpisode(for: firstSeason)
    }

    private func getNextUnwatchedEpisode(for season: Season?) -> Episode? {
        guard ( season != nil ) else { return nil }
        
        let oldestUnwatchedEpisode = season!.episodes
            .filter({ !$0.watched })
            .max(by: { $1.episodeNumber < $0.episodeNumber })

        if oldestUnwatchedEpisode == nil {
            let nextSeason = season!.show.seasons.first(where: { $0.seasonNumber == season!.seasonNumber + 1 })
            return self.getNextUnwatchedEpisode(for: nextSeason)
        } else {
            return oldestUnwatchedEpisode!
        }
    }

    private func createNewShow(from show: ShowResponse, withPoster poster: Data, andBackdrop backdrop: Data) -> Show {
        let newShow = Show(
            id: show.id,
            name: show.name,
            overview: show.overview,
            poster: poster,
            backdrop: backdrop,
            status: show.status,
            seasonCount: show.number_of_seasons
        )
        
        self.modelContext.insert(newShow)
        
        return newShow
    }
    
    private func createNewSeason(for show: Show, from season: SeasonResponse, withPoster poster: Data) -> Season {
        let newSeason = Season(
            show: show,
            seasonNumber: season.season_number,
            name: season.name,
            overview: season.overview,
            poster: poster,
            airDate: season.air_date != nil ? convertDate(from: season.air_date!) : Date.distantPast
        )
        
        self.modelContext.insert(newSeason)
        
        return newSeason
    }
    
    private func createNewEpisode(for season: Season, from episode: SeasonEpisodeResponse, withInsert insert: Bool = true) -> Episode {
        let hostId = episode.guest_stars?.first(where: { $0.id == 12219 })?.id ?? 0
        let newEpisode = Episode(
            season: season,
            episodeNumber: episode.episode_number,
            name: episode.name,
            overview: episode.overview ?? String(),
            airDate: episode.air_date != nil ? convertDate(from: episode.air_date!) : Date.distantPast,
            hostId: hostId
        )
        
        if insert {
            self.modelContext.insert(newEpisode)
        }
        
        return newEpisode
    }
    
    private func episodeHasChanged(from oldEpisode: Episode, to newEpisodeResponse: SeasonEpisodeResponse) -> Bool {
        let newEpisode = self.createNewEpisode(for: oldEpisode.season, from: newEpisodeResponse, withInsert: false)
        let episodeHasChanged = oldEpisode != newEpisode
        
        if episodeHasChanged {
            oldEpisode.name = newEpisode.name
            oldEpisode.overview = newEpisode.overview
            oldEpisode.airDate = newEpisode.airDate
        }
        
        return episodeHasChanged
    }
    
    private func daysUntilBroadcast(for episode: Episode) -> Int {
        guard ( episode.airDate != Date.distantPast ) else { return TeeVConstants.distantFutureDays }
        
        return max(getDaysBetween(from: getNowAtUtcMidnight(), to: episode.airDate), 0)
    }
    
    private func getPoster(from path: String?, asBackdrop: Bool = false) async throws -> Data {
        return path == nil ? Data.init() : try await getImage(from: path!, asBackdrop: asBackdrop)
    }
}

