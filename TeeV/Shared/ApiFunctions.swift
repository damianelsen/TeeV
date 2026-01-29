//
//  ApiFunctions.swift
//  TeeV
//
//  Created by Damian Elsen on 11/13/25.
//

import Foundation
import SwiftUI

struct ConfigurationResponse: Decodable {
    let images: ImagesResponse
}

struct ImagesResponse: Decodable {
    let secure_base_url: String
    let backdrop_sizes: [String]
    let poster_sizes: [String]
}

func getConfiguration() async throws -> ConfigurationResponse {
    let url = URL(string: TeeVConstants.tmdbConfigurationUrl)!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        TeeVConstants.apiHeaderAuthorization: TeeVConstants.apiHeaderToken,
        TeeVConstants.apiHeaderAccept: TeeVConstants.apiHeaderJson
    ]

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(ConfigurationResponse.self, from: data)

    return decoded
}

struct SearchResponse: Decodable {
    let results: [SearchShowResponse]
}

struct SearchShowResponse: Decodable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let poster_path: String?
}

func getShows(with showName: String) async throws -> [SearchShowResponse] {
    let url = URL(string: "\(TeeVConstants.tmdbSearchUrl)\(showName)")!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        TeeVConstants.apiHeaderAuthorization: TeeVConstants.apiHeaderToken
    ]

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)

    return decoded.results
}

struct ShowResponse: Decodable {
    let id: Int
    let name: String
    let overview: String
    let poster_path: String?
    let backdrop_path: String?
    let number_of_episodes: Int
    let status: String
    let number_of_seasons: Int
    let seasons: [ShowSeasonResponse]
}

struct ShowSeasonResponse: Decodable {
    let id: Int
    let season_number: Int
}

func getShow(with id: Int) async throws -> ShowResponse {
    let url = URL(string: "\(TeeVConstants.tmdbShowUrl)\(String(id))")!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        TeeVConstants.apiHeaderAuthorization: TeeVConstants.apiHeaderToken
    ]

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(ShowResponse.self, from: data)

    return decoded
}

struct SeasonResponse: Decodable {
    let season_number: Int
    let name: String
    let overview: String
    let poster_path: String?
    let air_date: String?
    let episodes: [SeasonEpisodeResponse]
}

struct SeasonEpisodeResponse: Decodable {
    let episode_number: Int
    let name: String
    let overview: String?
    let air_date: String?
    let guest_stars: [SeasonEpisodeGuestStarsResponse]?
}

struct SeasonEpisodeGuestStarsResponse: Decodable {
    let id: Int?
}

func getSeason(forShow showId: Int, with seasonNumber: Int) async throws -> SeasonResponse {
    let url = URL(string: "\(TeeVConstants.tmdbShowUrl)\(String(showId))/season/\(String(seasonNumber))")!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        TeeVConstants.apiHeaderAuthorization: TeeVConstants.apiHeaderToken
    ]

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(SeasonResponse.self, from: data)

    return decoded
}

func getImage(from imagePath: String, asBackdrop: Bool) async throws -> Data {
    @AppStorage(TeeVConstants.appStorageUrlBase) var urlBase = ""
    @AppStorage(TeeVConstants.appStorageBackdropSize) var backdropSize = ""
    @AppStorage(TeeVConstants.appStoragePosterSize) var posterSize = ""

    let size = asBackdrop ? backdropSize : posterSize
    let url = URL(string: "\(urlBase)\(size)\(imagePath)")!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
        TeeVConstants.apiHeaderAuthorization: TeeVConstants.apiHeaderToken
    ]

    let (data, _) = try await URLSession.shared.data(for: request)

    return data
}
