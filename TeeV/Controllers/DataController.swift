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

    func addNewShowWith(id: Int) async throws {
        let shows = try? modelContext.fetch(FetchDescriptor<Show>(predicate: #Predicate {
            show in show.id == id
        }))
        guard (shows?.count == 0) else { return }
        
        let showResponse = try await getShow(id: id)
        let showPoster = try await getPosterFrom(path: showResponse.poster_path)
        let showBackdrop = try await getPosterFrom(path: showResponse.backdrop_path, asBackdrop: true)
        let newShow = self.createNewShow(from: showResponse, withPoster: showPoster, andBackdrop: showBackdrop)
        let notifications = await NotificationController(modelContext: modelContext)
        
        for season in showResponse.seasons.filter({$0.season_number > 0}) {
            let seasonResponse = try await getSeason(showId: id, seasonNumber: season.season_number)
            let seasonPoster = try await getPosterFrom(path: seasonResponse.poster_path)
            let newSeason = self.createNewSeason(for: newShow, from: seasonResponse, withPoster: seasonPoster)
            
            for episode in seasonResponse.episodes {
                let newEpisode = self.createNewEpisode(for: newSeason, from: episode)
                await notifications.createNotificationFor(episode: newEpisode)
                
                newSeason.episodes.append(newEpisode)
            }

            newShow.seasons.append(newSeason)
        }
        
        let firstEpisode = newShow.seasons
            .first(where: { $0.seasonNumber == 1 })!.episodes
            .first(where: { $0.episodeNumber == 1 })
        newShow.nextEpisode = firstEpisode
        newShow.daysToNextEpisode = self.daysUntilBroadcastFor(episode: firstEpisode!)
    }

    func refreshShows() async throws -> String {
        let shows = try modelContext.fetch(FetchDescriptor<Show>())
        let notifications = await NotificationController(modelContext: modelContext)
        var updatedMessage = ""

//        try await withThrowingTaskGroup(of: Void.self) { group in
        for show in shows {
//                group.addTask {
                    // Update the show
            let showResponse = try await getShow(id: show.id)
            show.name = showResponse.name
            show.overview = showResponse.overview
            show.poster = try await self.getPosterFrom(path: showResponse.poster_path)
            show.status = showResponse.status
            
            // Update the most recent season
            let mostRecentSeason = show.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })!
            let seasonResponse = try await getSeason(showId: show.id, seasonNumber: mostRecentSeason.seasonNumber)
            mostRecentSeason.name = seasonResponse.name
            mostRecentSeason.overview = seasonResponse.overview
            mostRecentSeason.poster = try await self.getPosterFrom(path: seasonResponse.poster_path)
            mostRecentSeason.airDate = seasonResponse.air_date != nil ? convertDateFrom(dateString: seasonResponse.air_date!) : Date.distantPast

            let mostRecentEpisode = mostRecentSeason.episodes.max(by: { $0.episodeNumber < $1.episodeNumber })
            let mostRecentEpisodeNumber = mostRecentEpisode == nil ? 0 : mostRecentEpisode!.episodeNumber
            let existingEpisodes = seasonResponse.episodes.filter({ $0.episode_number <= mostRecentEpisodeNumber })
            let newEpisodes = seasonResponse.episodes.filter({ $0.episode_number > mostRecentEpisodeNumber })

            // Update the existing episodes
            for episode in existingEpisodes {
                let existingEpisode = mostRecentSeason.episodes.first(where: { $0.episodeNumber == episode.episode_number })!
                let existingEpisodeAirDate = existingEpisode.airDate

                existingEpisode.name = episode.name
                existingEpisode.overview = episode.overview ?? String()
                existingEpisode.airDate = episode.air_date != nil ? convertDateFrom(dateString: episode.air_date!) : Date.distantPast
                if existingEpisodeAirDate != existingEpisode.airDate {
                    print("existingEpisodeAirDate:\(existingEpisodeAirDate) != existingEpisode.airDate\(existingEpisode.airDate)")
                    notifications.deleteNotificationFor(episode: existingEpisode)
                    await notifications.createNotificationFor(episode: existingEpisode)
                }
            }

            // Add any new episodes
            for episode in newEpisodes {
                let newEpisode = self.createNewEpisode(for: mostRecentSeason, from: episode)
                await notifications.createNotificationFor(episode: newEpisode)

                mostRecentSeason.episodes.append(newEpisode)
                mostRecentSeason.watched = false
            }

            // Get and add any mew seasons
            let newSeasonCount = showResponse.number_of_seasons - show.seasonCount
            if showResponse.number_of_seasons > show.seasonCount {
                show.seasonCount = showResponse.number_of_seasons
                
                for seasonNumber in show.seasons.count + 1...show.seasonCount {
                    let seasonResponse = try await getSeason(showId: show.id, seasonNumber: seasonNumber)
                    let seasonPoster = try await self.getPosterFrom(path: seasonResponse.poster_path)
                    let newSeason = self.createNewSeason(for: show, from: seasonResponse, withPoster: seasonPoster)
                    
                    for episode in seasonResponse.episodes {
                        let newEpisode = self.createNewEpisode(for: newSeason, from: episode)
                        
                        await notifications.createNotificationFor(episode: newEpisode)
                        newSeason.episodes.append(newEpisode)
                    }

                    show.seasons.append(newSeason)
                }
            }
            
            if show.nextEpisode == nil {
                show.nextEpisode = self.getNextUnwatchedEpisodeFor(show: show)
                show.nextEpisodeNumber += show.nextEpisode != nil ? 1 : 0
            }
            show.daysToNextEpisode = show.nextEpisode != nil ? self.daysUntilBroadcastFor(episode: show.nextEpisode!) : 9999

            if newEpisodes.count > 0 || newSeasonCount > 0 {
                updatedMessage += updatedMessage.isEmpty ? "" : "\n"
                updatedMessage += "\(show.name) updated with "
                updatedMessage += newEpisodes.count > 0 ? "\(newEpisodes.count) new episode" : ""
                updatedMessage += newEpisodes.count > 1 ? "s" : ""
                updatedMessage += newEpisodes.count > 0 && newSeasonCount > 0 ? " and " : ""
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
    
    func removeShowWith(id: Int) async {
        let shows = try? modelContext.fetch(FetchDescriptor<Show>(predicate: #Predicate { show in
            show.id == id
        }))
        guard let show = shows?.first else { return }
        
        let showId = show.id
        let episodes = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { episode in
            episode.season.show.id == showId
        }))

        if let episodes {
            let notificationController = await NotificationController(modelContext: modelContext)

            for episode in episodes where episode.notificationId != nil {
                notificationController.deleteNotificationFor(episode: episode)
            }
        }
        
        modelContext.delete(show)
    }
    
    func markNextEpisodeAsWatchedFor(show: Show) async {
        let notificationController = await NotificationController(modelContext: modelContext)
        
        show.nextEpisode!.watched = true
        show.nextEpisode!.season.watched = show.nextEpisode!.season.episodes.allSatisfy({ $0.watched })
        notificationController.deleteNotificationFor(episode: show.nextEpisode!)
        show.nextEpisode = self.getNextUnwatchedEpisodeFor(show: show)
        show.nextEpisodeNumber += show.nextEpisode != nil ? 1 : 0
        show.daysToNextEpisode = show.nextEpisode != nil ? self.daysUntilBroadcastFor(episode: show.nextEpisode!) : 9999
        show.lastWatched = Date.now
    }
    
    func markAllWatchedFor(season: Season) async {
        let lastEpisode = season.episodes.max(by: { $0.episodeNumber < $1.episodeNumber })!
        
        await self.markAllWatchedFor(episode: lastEpisode)
    }
    
    func markAllWatchedFor(episode: Episode) async {
        repeat {
            if self.daysUntilBroadcastFor(episode: episode.season.show.nextEpisode!) == 0 {
                await self.markNextEpisodeAsWatchedFor(show: episode.season.show)
            } else {
                break
            }
        } while episode.season.show.nextEpisode != episode
        
        if self.daysUntilBroadcastFor(episode: episode.season.show.nextEpisode!) == 0 {
            await self.markNextEpisodeAsWatchedFor(show: episode.season.show)
        }
    }
    
    func getTotalUnwatchedEpisodes() -> Int {
        let unwatchedEpisodes = try? modelContext.fetch(FetchDescriptor<Episode>(predicate: #Predicate { episode in
            episode.watched == false
        }))
        
        if let unwatchedEpisodes {
            return unwatchedEpisodes
                .filter({ self.daysUntilBroadcastFor(episode: $0) == 0 })
                .count
        } else {
            return 0
        }
    }

    private func getNextUnwatchedEpisodeFor(show: Show) -> Episode? {
        let firstSeason = show.seasons.first(where: { $0.seasonNumber == 1 })

        return self.getNextUnwatchedEpisodeFor(season: firstSeason)
    }

    private func getNextUnwatchedEpisodeFor(season: Season?) -> Episode? {
        guard ( season != nil ) else { return nil }
        
        let oldestUnwatchedEpisode = season!.episodes
            .filter({ !$0.watched })
            .max(by: { $1.episodeNumber < $0.episodeNumber })

        if oldestUnwatchedEpisode == nil {
            let nextSeason = season!.show.seasons.first(where: { $0.seasonNumber == season!.seasonNumber + 1 })
            return self.getNextUnwatchedEpisodeFor(season: nextSeason)
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
            airDate: season.air_date != nil ? convertDateFrom(dateString: season.air_date!) : Date.distantPast
        )
        
        self.modelContext.insert(newSeason)
        
        return newSeason
    }
    
    private func createNewEpisode(for season: Season, from episode: SeasonEpisodeResponse) -> Episode {
        let newEpisode = Episode(
            season: season,
            episodeNumber: episode.episode_number,
            name: episode.name,
            overview: episode.overview ?? String(),
            airDate: episode.air_date != nil ? convertDateFrom(dateString: episode.air_date!) : Date.distantPast
        )
        
        self.modelContext.insert(newEpisode)
        
        return newEpisode
    }
    
    private func daysUntilBroadcastFor(episode: Episode) -> Int {
        return max(getDaysBetween(from: getNowAtUtcMidnight(), to: episode.airDate), 0)
    }
    
    private func getPosterFrom(path: String?, asBackdrop backdrop: Bool = false) async throws -> Data {
        return path == nil ? Data.init() : try await getImage(imagePath: path!, backdrop: backdrop)
    }
    
    // TODO: to be deleted
    
    func deleteMostRecentSeasson(of show: Show) {
        let mostRecentSeason = show.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })!
        let mostRecentSeasonIndex = show.seasons.firstIndex(of: mostRecentSeason)!

        for _ in 0..<mostRecentSeason.episodes.count {
            let episode = mostRecentSeason.episodes.popLast()!
            self.modelContext.delete(episode)
        }

        show.seasons.remove(at: mostRecentSeasonIndex)

        self.modelContext.delete(mostRecentSeason)
        
        show.seasonCount -= 1
        show.nextEpisode = getNextUnwatchedEpisodeFor(show: show)
    }
    
    func deleteEpisodesWith(count: Int, from show: Show) {
        let mostRecentSeason = show.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })!

        for _ in 0..<count {
            let episode = mostRecentSeason.episodes.max(by: { $0.episodeNumber < $1.episodeNumber })!
            mostRecentSeason.episodes.removeAll(where: { $0.episodeNumber == episode.episodeNumber })
            self.modelContext.delete(episode)
        }
    }
}

