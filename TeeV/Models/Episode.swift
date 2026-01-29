//
//  Episode.swift
//  TeeV
//
//  Created by Damian Elsen on 12/5/25.
//

import Foundation
import SwiftData

@Model
final class Episode: Equatable {
    var season: Season
    var episodeNumber: Int
    var name: String
    var overview: String
    var airDate: Date
    var hostId: Int?
    var watched: Bool = false
    var notificationId: String?
    
    init(
        season: Season,
        episodeNumber: Int,
        name: String,
        overview: String,
        airDate: Date,
        hostId: Int
    ) {
        self.season = season
        self.episodeNumber = episodeNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.hostId = hostId
    }
    
    public static func == (lhs: Episode, rhs: Episode) -> Bool {
        return
            lhs.name == rhs.name &&
            lhs.overview == rhs.overview &&
            lhs.airDate == rhs.airDate
    }
}
