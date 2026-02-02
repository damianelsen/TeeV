//
//  SeasonView.swift
//  TeeV
//
//  Created by Damian Elsen on 12/17/25.
//

import SwiftUI

struct ListItem: Identifiable, Hashable {
    let id = UUID()
    let episodeNumber: Int
    let overview: String
    let airDate: Date
    let watched: Bool
    var child: [ListItem]?
}

struct SeasonView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingConfirmation = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    let season: Season
    
    var body: some View {
        Text("\(season.show.name)")
            .font(.largeTitle)
            .lineLimit(...1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        Text("\(season.name)")
            .font(.title)
            .lineLimit(...1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        HStack {
            Image(uiImage: (UIImage(data: season.poster) ?? UIImage(systemName: "photo.tv"))!)
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 285, alignment: .center)
            ScrollView {
                Text(season.overview == String() ? "No season overview has been provided." : season.overview)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: 190, height: 285, alignment: .top)
        }
        .padding(.horizontal, 8)
        Text("Episodes")
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        List{
            ForEach(season.episodes.sorted(by: { $1.episodeNumber < $0.episodeNumber })) {episode in
                DisclosureGroup {
                    VStack {
                        Text(episode.overview.isEmpty ? "No episode overview has been provided." : episode.overview)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(getWhenAirs(for: episode))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } label: {
                    Text("\(episode.episodeNumber). \(episode.name)")
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(episode.watched ? .green : .white)
                        .frame(alignment: .trailing)
                        .onTapGesture() {
                            showingConfirmation = !episode.watched
                        }
                        .confirmationDialog("Mark Episode Watched", isPresented: $showingConfirmation) {
                            Button("Yes") {
                                markWatched(for: episode)
                            }
                        } message: {
                            Text("Are you sure you want to mark this episode as watched? Doing so will also mark all previous episodes in all previous seasons as watched.")
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func getWhenAirs(for episode: Episode) -> String {
        guard ( episode.airDate != Date.distantPast ) else {
            return "No air date has been provided."
        }
        
        let daysUntilAiring = getDaysBetween(from: getNowAtUtcMidnight(), to: episode.airDate)
        let airingLiteral = max(daysUntilAiring, 0) == 0 ? "Aired" : "Airs"
        let formattedAirDate = dateFormatter.string(from: episode.airDate)
        
        return "\(airingLiteral) on \(formattedAirDate)"
    }
    
    private func markWatched(for episode: Episode) {
        let showController = DataController(modelContext: modelContext)

        showController.markAllWatched(for: episode)
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
    let episode = Episode(
        season: season,
        episodeNumber: 1,
        name: "Episode One",
        overview: "Sample overview text describing the episode in more than a single line. Sample overview text describing the episode in more than a single line.",
        airDate: Date()
    )
    season.episodes.append(episode)
    
    return SeasonView(season: season)
}

