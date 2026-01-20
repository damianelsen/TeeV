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
        VStack {
            Text(show.name)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            HStack {
                Image(uiImage: (UIImage(data: show.poster) ?? UIImage(systemName: "photo.tv"))!)
                    .frame(maxHeight: .infinity, alignment: .top)
                Text(show.overview)
                    .lineLimit(...15)
                    .frame(maxHeight: .infinity, alignment: .top)
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
                                    markWatchedFor(season: season)
                                }
                            } message: {
                                Text("Are you sure you want to mark this season as watched? Doing so will also mark all previous seasons as watched.")
                            }
                    }
                }
            }
        }
    }
    
    private func markWatchedFor(season: Season) {
        Task {
            let showController = DataController(modelContext: modelContext)

            await showController.markAllWatchedFor(season: season)
        }
    }
}

// TODO: fix this
//#Preview {
//    ShowView(show: Show())
//}
