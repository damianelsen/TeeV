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
        let nextEpisodeAvailability = nextUnwatchedEpisodeAvailabilityFor(show: show)
        
        HStack {
            VStack(alignment: .leading) {
                Text(show.name)
                    .font(.title3)
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 56, leading: 15, bottom: 0, trailing: 0))
                Text(nextEpisodeDetailsFor(show: show))
                    .lineLimit(...1)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 14, trailing: 0))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                    .background(.red)
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
//                    .background(.yellow)
        }
        .background(
            Image(uiImage: (UIImage(data: show.backdrop) ?? UIImage(systemName: "photo.tv"))!)
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 110)
                .clipped()
        )
        .swipeActions(edge: .leading) {
            if nextEpisodeAvailability == "Today" {
                Button {
                    Task {
                        await markEpisodeAsWatched(for: show)
                    }
                } label: {
                    Label("Watched", systemImage: "eye")
                }
                .tint(.green)
            }
//            Button {
//                deleteMostRecentSeasson(of: show)
//            } label: {
//                Label("Remove Last Season", systemImage: "xmark.bin")
//            }
//            .tint(.red)
//            Button {
//                deleteMostRecentEpisodes(of: show)
//            } label: {
//                Label("Remove Last 3 Episodes", systemImage: "xmark.bin")
//            }
//            .tint(.red)
        }
    }
    
    private func nextUnwatchedEpisodeAvailabilityFor(show: Show) -> String {
        return if show.nextEpisode == nil && show.status == "Returning Series" {
            "TBA"
        } else if show.nextEpisode == nil {
            show.status
        } else {
            switch show.daysToNextEpisode {
                case 0: "Today"
                case 1: "Tomorrow"
                default: "\(show.daysToNextEpisode) days"
            }
        }
    }
    
    private func nextEpisodeDetailsFor(show: Show) -> String {
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
    
    private func markEpisodeAsWatched(for show: Show) async {
        let showController = DataController(modelContext: modelContext)

        await showController.markNextEpisodeAsWatchedFor(show: show)
    }
    
    // TODO: to be deleted
    
//    private func deleteMostRecentSeasson(of show: Show) {
//        let showController = ShowController(modelContext: modelContext)
//        
//        showController.deleteMostRecentSeasson(of: show)
//    }
//    
//    private func deleteMostRecentEpisodes(of show: Show) {
//        let showController = ShowController(modelContext: modelContext)
//        
//        showController.deleteEpisodesWith(count: 3, from: show)
//    }
}

// TODO: fix this
//#Preview {
//    ShowListItemView(show: nil)
//}
