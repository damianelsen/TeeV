//
//  Season.swift
//  TeeV
//
//  Created by Damian Elsen on 12/5/25.
//

import Foundation
import SwiftData

@Model
final class Season {
    var show: Show
    var seasonNumber: Int
    var name: String
    var overview: String
    var poster: Data
    var airDate: Date
    var watched: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \Episode.season) var episodes: [Episode]

    init(
        show: Show,
        seasonNumber: Int,
        name: String,
        overview: String,
        poster: Data,
        airDate: Date
    ) {
        self.show = show
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.poster = poster
        self.airDate = airDate
        self.episodes = []
    }
}
