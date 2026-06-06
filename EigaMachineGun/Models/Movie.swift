import Foundation

// iTunes Search API response
struct iTunesResponse: Codable {
    let resultCount: Int
    let results: [Movie]
}

struct Movie: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String // director
    let artworkUrl100: String?
    let longDescription: String?
    let shortDescription: String?
    let releaseDate: String?
    let primaryGenreName: String?
    let contentAdvisoryRating: String?
    let trackPrice: Double?
    let previewUrl: String? // trailer preview
    let trackViewUrl: String? // iTunes store link

    var id: Int { trackId }

    var posterURL: URL? {
        guard let url = artworkUrl100 else { return nil }
        // Replace any NxN size pattern with 600x600 for high-res
        let hiRes = url.replacingOccurrences(
            of: #"\d+x\d+(bb|cc|sr)"#,
            with: "600x600$1",
            options: .regularExpression
        )
        // If regex didn't match, try the common patterns
        if hiRes == url {
            let fallback = url
                .replacingOccurrences(of: "100x100", with: "600x600")
                .replacingOccurrences(of: "200x200", with: "600x600")
            return URL(string: fallback)
        }
        return URL(string: hiRes)
    }

    var backdropURL: URL? {
        guard let url = artworkUrl100 else { return nil }
        let hiRes = url.replacingOccurrences(
            of: #"\d+x\d+(bb|cc|sr)"#,
            with: "1200x1200$1",
            options: .regularExpression
        )
        if hiRes == url {
            let fallback = url
                .replacingOccurrences(of: "100x100", with: "1200x1200")
                .replacingOccurrences(of: "200x200", with: "1200x1200")
            return URL(string: fallback)
        }
        return URL(string: hiRes)
    }

    var overview: String {
        longDescription ?? shortDescription ?? ""
    }

    var year: String {
        guard let date = releaseDate, date.count >= 4 else { return "---" }
        return String(date.prefix(4))
    }

    var genre: String {
        primaryGenreName ?? "---"
    }

    var rating: String {
        contentAdvisoryRating ?? "---"
    }

    var director: String {
        artistName
    }

    var previewVideoURL: URL? {
        guard let url = previewUrl else { return nil }
        return URL(string: url)
    }

    var storeURL: URL? {
        guard let url = trackViewUrl else { return nil }
        return URL(string: url)
    }
}

// Genre definitions with search terms
struct Genre: Identifiable {
    let id: Int
    let name: String
    let emoji: String
    let searchTerm: String
}

let allGenres: [Genre] = [
    Genre(id: 0,  name: "ALL",       emoji: "\u{1F3AC}", searchTerm: "movie"),
    Genre(id: 1,  name: "Action",    emoji: "\u{1F4A5}", searchTerm: "action movie"),
    Genre(id: 2,  name: "Comedy",    emoji: "\u{1F923}", searchTerm: "comedy movie"),
    Genre(id: 3,  name: "Horror",    emoji: "\u{1F47B}", searchTerm: "horror movie"),
    Genre(id: 4,  name: "SF",        emoji: "\u{1F680}", searchTerm: "sci-fi movie"),
    Genre(id: 5,  name: "Romance",   emoji: "\u{2764}\u{FE0F}", searchTerm: "romance movie"),
    Genre(id: 6,  name: "Thriller",  emoji: "\u{1F525}", searchTerm: "thriller movie"),
    Genre(id: 7,  name: "Animation", emoji: "\u{1F3A8}", searchTerm: "animation movie"),
    Genre(id: 8,  name: "Drama",     emoji: "\u{1F3AD}", searchTerm: "drama movie"),
    Genre(id: 9,  name: "Crime",     emoji: "\u{1F52A}", searchTerm: "crime movie"),
    Genre(id: 10, name: "Fantasy",   emoji: "\u{1FA84}", searchTerm: "fantasy movie"),
    Genre(id: 11, name: "War",       emoji: "\u{2694}\u{FE0F}", searchTerm: "war movie"),
]

// RSS Feed response for top movies
struct RSSFeedResponse: Codable {
    let feed: RSSFeed
}

struct RSSFeed: Codable {
    let results: [RSSMovie]
}

struct RSSMovie: Codable {
    let id: String
    let name: String
    let artistName: String?
    let artworkUrl100: String?
    let url: String?
}
