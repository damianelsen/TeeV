//
//  ShowListItemView.swift
//  TeeV
//
//  Created by Damian Elsen on 12/12/25.
//

import SwiftUI

struct ShowListItemView: View {
    @Environment(\.modelContext) private var modelContext

    let show: Show
    
    var body: some View {
        let nextEpisodeAvailability = nextUnwatchedEpisodeAvailability(for: show)
        let backgroundImage: some View = Group {
            if let uiImage = UIImage(data: show.backdrop) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 400, height: 110)
        .clipped()
        var backgroundColor: Color = .black
        if let uiImage = UIImage(data: show.backdrop) {
            backgroundColor = Color(uiImage.dominantColor()!)
        }

        return HStack {
            VStack(alignment: .leading) {
                Text(show.name)
                    .font(.title3)
                    .setContrast(using: backgroundColor)
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 58, leading: 15, bottom: 0, trailing: 0))
                Text(nextEpisodeDetails(for: show))
                    .setContrast(using: backgroundColor)
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 12, trailing: 0))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing) {
                Image(systemName: "clock")
                    .setContrast(using: backgroundColor)
                    .font(.subheadline)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 15))
                Text(nextEpisodeAvailability)
                    .font(.title)
                    .setContrast(using: backgroundColor)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 15))
                Text("\(show.nextEpisodeNumber) / \(episodeCount(for: show))")
                    .setContrast(using: backgroundColor)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 15))
            }
        }
        .background(backgroundImage)
        .swipeActions(edge: .leading) {
            if nextEpisodeAvailability == "Not Started" || nextEpisodeAvailability == "Today" {
                Button {
                    markEpisodeAsWatched(for: show)
                } label: {
                    Label("Watched", systemImage: "eye")
                }
                .tint(.green)
            }
        }
    }
    
    private func nextUnwatchedEpisodeAvailability(for show: Show) -> String {
        return if !show.started {
            "Not Started"
        } else if show.nextEpisode == nil && show.status == "Returning Series" {
            "TBA"
        } else if show.nextEpisode == nil {
            show.status
        } else if show.nextEpisode!.airDate == Date.distantPast {
            "TBA"
        } else {
            switch show.daysToNextEpisode {
                case 0: "Today"
                case 1: "Tomorrow"
                default: "\(show.daysToNextEpisode) days"
            }
        }
    }
    
    private func nextEpisodeDetails(for show: Show) -> String {
        guard show.nextEpisode != nil else {
            return String()
        }
        
        let seasonNumber = show.nextEpisode!.season.seasonNumber
        let episodeNumber = show.nextEpisode!.episodeNumber
        let episodeName = show.nextEpisode!.name
        
        return "S\(seasonNumber) E\(episodeNumber) \(episodeName)"
    }
    
    private func episodeCount(for show: Show) -> Int {
        return show.seasons.reduce(0) { count, season in
            count + season.episodes.count
        }
    }
    
    private func markEpisodeAsWatched(for show: Show) {
        let showController = DataController(modelContext: modelContext)

        showController.markNextEpisodeAsWatched(for: show)
    }
}

#Preview {
    let show = Show(
        id: 1,
        name: "Show Name",
        overview: "Sample overview text describing the show in more than a single line. Sample overview text describing the show in more than a single line. Sample overview text describing the show in more than a single line. Sample overview text describing the show in more than a single line. Sample overview text describing the show in more than a single line.",
        poster: Data(),
        backdrop: Data(),
        status: "Returning Series",
        seasonCount: 1
    )
    let season = Season(
        show: show,
        seasonNumber: 1,
        name: "Season One",
        overview: "Sample overview text describing the season in more than a single line. Sample overview text describing the season in more than a single line. Sample overview text describing the season in more than a single line. Sample overview text describing the season in more than a single line. Sample overview text describing the season in more than a single line.",
        poster: Data(),
        airDate: Date()
    )
    show.seasons.append(season)
    let episode = Episode(
        season: season,
        episodeNumber: 1,
        name: "Episode One",
        overview: "Sample overview text describing the episode in more than a single line. Sample overview text describing the episode in more than a single line.",
        airDate: Date()
    )
    season.episodes.append(episode)
    show.nextEpisode = episode

    return ShowListItemView(show: show)
}

