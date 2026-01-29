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

        // TODO: are all of the trailing/leading values correct?
        return HStack {
            VStack(alignment: .leading) {
                Text(show.name)
                    .font(.title3)
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 56, leading: 15, bottom: 0, trailing: 0))
                Text(nextEpisodeDetails(for: show))
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 14, trailing: 0))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            VStack(alignment: .trailing) {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 15))
                Text(nextEpisodeAvailability)
                    .font(.title)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 15))
                Text("\(show.nextEpisodeNumber) / \(episodeCount(for: show))")
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 14, trailing: 15))
            }
            .frame(maxHeight: .infinity, alignment: .trailing)
        }
        .background(backgroundImage)
        .swipeActions(edge: .leading) {
            if nextEpisodeAvailability == "Today" {
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
        return if show.nextEpisode == nil && show.status == "Returning Series" {
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

    return ShowListItemView(show: show)
}

