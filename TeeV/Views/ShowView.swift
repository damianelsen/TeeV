//
//  ShowView.swift
//  TeeV
//
//  Created by Damian Elsen on 12/11/25.
//

import SwiftUI

struct ShowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingConfirmation = false
    
    let show: Show
    
    var body: some View {
        Text(show.name)
            .font(.largeTitle)
            .lineLimit(...1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        HStack {
            Image(uiImage: (UIImage(data: show.poster) ?? UIImage(systemName: "photo.tv"))!)
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 285, alignment: .center)
            ScrollView {
                Text(show.overview == String() ? "No season overview has been provided." : show.overview)
            }
            .frame(width: 190, height: 285, alignment: .top)
        }
        .padding(.horizontal, 8)
        Text("Seasons")
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        List {
            ForEach(show.seasons.sorted(by: { $1.seasonNumber < $0.seasonNumber })) { season in
                NavigationLink {
                    SeasonView(season: season)
                } label: {
                    Text(season.name)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(season.watched ? .green : .white)
                        .frame(alignment: .trailing)
                        .onTapGesture() {
                            showingConfirmation = !season.watched
                        }
                        .confirmationDialog("Mark Season Watched", isPresented: $showingConfirmation) {
                            Button("Yes") {
                                markWatched(for: season)
                            }
                        } message: {
                            Text("Are you sure you want to mark this season as watched? Doing so will also mark all previous seasons as watched.")
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func markWatched(for season: Season) {
        let showController = DataController(modelContext: modelContext)

        showController.markAllWatched(for: season)
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
    show.seasons.append(season)

    return ShowView(show: show)
}
