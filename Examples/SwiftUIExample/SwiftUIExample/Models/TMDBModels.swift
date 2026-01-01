import Foundation
import AsyncSwiftyNetworking

// MARK: - TMDB Popular Movies Response

struct PopularMoviesResponse: Decodable, HTTPResponseDecodable {
    var statusCode: Int?
    let page: Int?
    let results: [Movie]?
    let totalPages: Int?
    let totalResults: Int?
}

// MARK: - Movie Model (List Item)

struct Movie: Decodable, Identifiable, Sendable {
    let id: Int
    let adult: Bool?
    let backdropPath: String?
    let genreIds: [Int]?
    let originalLanguage: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String?
    let title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(path)")
    }
    
    // MARK: - UI Helpers
    
    var displayTitle: String {
        title ?? originalTitle ?? "Unknown Title"
    }
    
    var displayOverview: String {
         overview ?? "No overview available."
    }
    
    var displayVoteAverage: Double {
        voteAverage ?? 0.0
    }
    
    var displayReleaseDate: String? {
        releaseDate
    }
}

// MARK: - Movie Detail Model

struct MovieDetail: Decodable, HTTPResponseDecodable, Sendable {
    var statusCode: Int?
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let belongsToCollection: MovieCollection?
    let budget: Int
    let genres: [Genre]
    let homepage: String?
    let imdbId: String?
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let productionCompanies: [ProductionCompany]
    let releaseDate: String?
    let revenue: Int
    let runtime: Int?
    let status: String
    let tagline: String?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
    
    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }
    
    var formattedRuntime: String {
        guard let runtime = runtime else { return "N/A" }
        let hours = runtime / 60
        let minutes = runtime % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var formattedBudget: String {
        budget > 0 ? "$\(budget / 1_000_000)M" : "N/A"
    }
    
    var formattedRevenue: String {
        revenue > 0 ? "$\(revenue / 1_000_000)M" : "N/A"
    }
}

// MARK: - Collection

struct MovieCollection: Decodable, Sendable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?
}

// MARK: - Genre

struct Genre: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
}

// MARK: - Production Company

struct ProductionCompany: Decodable, Identifiable, Sendable {
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String
}

// MARK: - Videos Response

struct VideosResponse: Decodable, HTTPResponseDecodable, Sendable {
    var statusCode: Int?
    let id: Int
    let results: [Video]
}

struct Video: Decodable, Identifiable, Sendable {
    let id: String
    let iso6391: String
    let iso31661: String
    let name: String
    let key: String
    let site: String
    let size: Int
    let type: String
    let official: Bool
    let publishedAt: String
    
    var youtubeURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
    
    var thumbnailURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }
    
    
    var isTrailer: Bool {
        type == "Trailer"
    }
}

// MARK: - Genre Utils

struct GenreUtils {
    static let genreMap: [Int: String] = [
        28: "Action",
        12: "Adventure",
        16: "Animation",
        35: "Comedy",
        80: "Crime",
        99: "Documentary",
        18: "Drama",
        10751: "Family",
        14: "Fantasy",
        36: "History",
        27: "Horror",
        10402: "Music",
        9648: "Mystery",
        10749: "Romance",
        878: "Science Fiction",
        10770: "TV Movie",
        53: "Thriller",
        10752: "War",
        37: "Western"
    ]
    
    static func genreName(for id: Int) -> String {
        return genreMap[id] ?? "Other"
    }
}
