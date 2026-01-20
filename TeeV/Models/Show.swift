//
//  Show.swift
//  TeeV
//
//  Created by Damian Elsen on 12/5/25.
//

import Foundation
import SwiftData

@Model
final class Show {
    var id: Int
    var name: String
    var overview: String
    var poster: Data
    var backdrop: Data
    var status: String
    var seasonCount: Int
    var nextEpisodeNumber: Int
    var daysToNextEpisode: Int
    var lastWatched: Date
    var nextEpisode: Episode?
    @Relationship(deleteRule: .cascade, inverse: \Season.show) var seasons: [Season]

    init(
        id: Int,
        name: String,
        overview: String,
        poster: Data,
        backdrop: Data,
        status: String,
        seasonCount: Int
    ) {
        self.id = id
        self.name = name
        self.poster = poster
        self.backdrop = backdrop
        self.overview = overview
        self.status = status
        self.seasonCount = seasonCount
        self.nextEpisodeNumber = 1
        self.daysToNextEpisode = 0
        self.lastWatched = Date.now
        self.seasons = []
    }
}
