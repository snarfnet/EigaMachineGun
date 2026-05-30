import Foundation

class MovieService {
    // iTunes Search API - no API key needed
    static let searchURL = "https://itunes.apple.com/search"
    static let rssBaseURL = "https://rss.applemarketingtools.com/api/v2"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
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

    // Hard-coded offline movies shown when all network calls fail
    static let offlineMovies: [Movie] = [
        Movie(trackId: 1, trackName: "君の名は。", artistName: "新海誠",
              artworkUrl100: nil, longDescription: "彗星が降ってくる前の日本。東京に住む少年と山奥の田舎町に住む少女の、夢の中での不思議な入れ替わりを描く。",
              shortDescription: nil, releaseDate: "2016-08-26", primaryGenreName: "アニメ",
              contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 2, trackName: "千と千尋の神隠し", artistName: "宮崎駿",
              artworkUrl100: nil, longDescription: "不思議の町に迷い込んだ少女・千尋が、両親を助けるために働きながら成長する物語。",
              shortDescription: nil, releaseDate: "2001-07-20", primaryGenreName: "アニメ",
              contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 3, trackName: "となりのトトロ", artistName: "宮崎駿",
              artworkUrl100: nil, longDescription: "1950年代の日本の農村を舞台に、姉妹が出会う森の精霊トトロとの交流を描いた作品。",
              shortDescription: nil, releaseDate: "1988-04-16", primaryGenreName: "アニメ",
              contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 4, trackName: "もののけ姫", artistName: "宮崎駿",
              artworkUrl100: nil, longDescription: "室町時代の日本を舞台に、人間と自然の対立を壮大なスケールで描くアクション冒険劇。",
              shortDescription: nil, releaseDate: "1997-07-12", primaryGenreName: "アニメ",
              contentAdvisoryRating: "PG-12", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 5, trackName: "インターステラー", artistName: "クリストファー・ノーラン",
              artworkUrl100: nil, longDescription: "地球の環境悪化で人類滅亡の危機が迫る中、宇宙飛行士が新たな居住可能惑星を探す旅に出る。",
              shortDescription: nil, releaseDate: "2014-11-22", primaryGenreName: "SF",
              contentAdvisoryRating: "PG-12", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 6, trackName: "アバター", artistName: "ジェームズ・キャメロン",
              artworkUrl100: nil, longDescription: "22世紀の未来、資源採掘のためパンドラに降り立った人間と先住民族ナヴィの戦いを描く。",
              shortDescription: nil, releaseDate: "2009-12-23", primaryGenreName: "SF",
              contentAdvisoryRating: "PG-12", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 7, trackName: "鬼滅の刃 無限列車編", artistName: "外崎春雄",
              artworkUrl100: nil, longDescription: "炭治郎たちが煉獄杏寿郎と共に無限列車で鬼と戦う。日本歴代興行収入1位を記録した大ヒット作。",
              shortDescription: nil, releaseDate: "2020-10-16", primaryGenreName: "アニメ",
              contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
        Movie(trackId: 8, trackName: "THE FIRST SLAM DUNK", artistName: "井上雄彦",
              artworkUrl100: nil, longDescription: "不良少年・桜木花道が天才バスケットプレイヤーへと成長する姿を描いたバスケットボール漫画の映画化。",
              shortDescription: nil, releaseDate: "2022-12-03", primaryGenreName: "アニメ",
              contentAdvisoryRating: "G", trackPrice: nil, previewUrl: nil, trackViewUrl: nil),
    ]

    // Fallback search terms when primary feed fails
    static let fallbackSearchTerms = [
        "アクション映画", "恋愛映画", "アニメ映画", "コメディ映画",
        "SF映画", "ホラー映画", "ドラマ映画", "ファンタジー映画",
        "action movie", "comedy movie", "anime", "drama film"
    ]

    // Try multiple search terms to get movies when primary methods fail
    static func fetchFallbackMovies() async -> [Movie] {
        var allMovies: [Movie] = []
        var seenIds: Set<Int> = []
        for term in fallbackSearchTerms {
            if allMovies.count >= 30 { break }
            do {
                let results = try await searchMovies(term: term, limit: 20)
                for movie in results where movie.artworkUrl100 != nil {
                    if !seenIds.contains(movie.id) {
                        seenIds.insert(movie.id)
                        allMovies.append(movie)
                    }
                }
            } catch {
                continue
            }
        }
        return allMovies.shuffled()
    }

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
