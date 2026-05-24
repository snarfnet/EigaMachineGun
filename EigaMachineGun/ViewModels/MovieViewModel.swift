import SwiftUI
import Combine

enum FeedMode: String, CaseIterable {
    case top = "Top"
    case search = "Search"
    case variety = "Mix"
}

@MainActor
class MovieViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = true
    @Published var speed: Double = 3.0
    @Published var selectedGenre: Genre = allGenres[0]
    @Published var feedMode: FeedMode = .top
    @Published var isLoading: Bool = false
    @Published var favorites: Set<Int> = []

    private var timer: Timer?
    private let favoritesKey = "favoriteMovieIds"

    var currentMovie: Movie? {
        guard !movies.isEmpty, currentIndex < movies.count else { return nil }
        return movies[currentIndex]
    }

    init() {
        loadFavorites()
    }

    func loadMovies() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            switch feedMode {
            case .top:
                movies = try await MovieService.fetchTopMovies()
            case .search:
                movies = try await MovieService.searchMovies(term: selectedGenre.searchTerm, limit: 200)
            case .variety:
                movies = try await MovieService.fetchVariety(genre: selectedGenre)
            }

            // Filter out movies without artwork
            movies = movies.filter { $0.artworkUrl100 != nil }
            currentIndex = 0
            startTimer()
        } catch {
            print("Failed to load movies: \(error)")
        }

        isLoading = false
    }

    func next() {
        guard !movies.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentIndex = (currentIndex + 1) % movies.count
        }
    }

    func previous() {
        guard !movies.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            currentIndex = currentIndex > 0 ? currentIndex - 1 : movies.count - 1
        }
    }

    func startTimer() {
        stopTimer()
        guard isPlaying else { return }
        timer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.next()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            stopTimer()
        }
    }

    func updateSpeed(_ newSpeed: Double) {
        speed = newSpeed
        if isPlaying {
            startTimer()
        }
    }

    func selectGenre(_ genre: Genre) {
        selectedGenre = genre
        Task { await loadMovies() }
    }

    func selectFeedMode(_ mode: FeedMode) {
        feedMode = mode
        Task { await loadMovies() }
    }

    func toggleFavorite(_ movie: Movie) {
        if favorites.contains(movie.id) {
            favorites.remove(movie.id)
        } else {
            favorites.insert(movie.id)
        }
        saveFavorites()
    }

    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains(movie.id)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    private func loadFavorites() {
        let ids = UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? []
        favorites = Set(ids)
    }
}
