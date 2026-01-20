//
//  Episode.swift
//  TeeV
//
//  Created by Damian Elsen on 12/5/25.
//

import Foundation
import SwiftData

@Model
final class Episode {
    var season: Season
    var episodeNumber: Int
    var name: String
    var overview: String
    var airDate: Date
    var watched: Bool = false
    var notificationId: String?

    init(
        season: Season,
        episodeNumber: Int,
        name: String,
        overview: String,
        airDate: Date
    ) {
        self.season = season
        self.episodeNumber = episodeNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
    }
}
