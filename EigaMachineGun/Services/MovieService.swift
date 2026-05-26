import Foundation

class MovieService {
    // iTunes Search API - no API key needed
    static let searchURL = "https://itunes.apple.com/search"
    static let rssBaseURL = "https://rss.applemarketingtools.com/api/v2"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    // Search movies via iTunes Search API
    static func searchMovies(term: String, country: String = "jp", limit: Int = 100, offset: Int = 0) async throws -> [Movie] {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let urlString = "\(searchURL)?term=\(encoded)&media=movie&country=\(country)&limit=\(limit)&offset=\(offset)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(iTunesResponse.self, from: data)
        return response.results
    }

    // Fetch top movies via Apple RSS feed
    static func fetchTopMovies(country: String = "jp", limit: Int = 100) async throws -> [Movie] {
        let urlString = "\(rssBaseURL)/\(country)/movies/top-movies/\(limit)/movies.json"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await session.data(from: url)
        let rssResponse = try JSONDecoder().decode(RSSFeedResponse.self, from: data)

        // Convert RSS movies to full Movie objects by searching each
        var movies: [Movie] = []
        // Batch lookup via iTunes lookup API
        let ids = rssResponse.feed.results.compactMap { $0.id }
        if !ids.isEmpty {
            let batchSize = 50
            for i in stride(from: 0, to: ids.count, by: batchSize) {
                let batch = Array(ids[i..<min(i + batchSize, ids.count)])
                let idString = batch.joined(separator: ",")
                let lookupURL = "https://itunes.apple.com/lookup?id=\(idString)&country=jp&media=movie"
                if let url = URL(string: lookupURL) {
                    do {
                        let (lookupData, _) = try await session.data(from: url)
                        let lookupResponse = try JSONDecoder().decode(iTunesResponse.self, from: lookupData)
                        movies.append(contentsOf: lookupResponse.results)
                    } catch {
                        print("Batch lookup failed: \(error)")
                    }
                }
            }
        }

        return movies
    }

    // Built-in sample movies as ultimate fallback when API is unavailable
    static let sampleMovies: [Movie] = [
        Movie(trackId: 1, trackName: "Sample Movie", artistName: "Director", artworkUrl100: "https://is1-ssl.mzstatic.com/image/thumb/Video126/v4/a0/a0/a0/a0a0a0a0-0000-0000-0000-000000000000/100x100bb.jpg", longDescription: "映画マシンガンへようこそ。ネットワーク接続を確認して、最新の映画情報を読み込んでください。画面を左右にスワイプして映画を切り替えられます。", shortDescription: nil, releaseDate: "2026-01-01T00:00:00Z", primaryGenreName: "Drama", contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
    ]

    // Search with multiple terms for variety
    static func fetchVariety(genre: Genre, offset: Int = 0) async throws -> [Movie] {
        let terms = [
            genre.searchTerm,
            "\(genre.searchTerm) 2024",
            "\(genre.searchTerm) 2025",
            "best \(genre.searchTerm)",
        ]

        var allMovies: [Movie] = []
        var seenIds: Set<Int> = []

        for term in terms {
            do {
                let movies = try await searchMovies(term: term, limit: 50, offset: offset)
                for movie in movies {
                    if !seenIds.contains(movie.id) {
                        seenIds.insert(movie.id)
                        allMovies.append(movie)
                    }
                }
            } catch {
                print("Search failed for \(term): \(error)")
            }
        }

        return allMovies.shuffled()
    }
}
