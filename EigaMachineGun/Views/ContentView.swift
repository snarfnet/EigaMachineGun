import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MovieViewModel()
    @State private var showDetail = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading && viewModel.movies.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.movies.isEmpty {
                errorView(error)
            } else if let movie = viewModel.currentMovie {
                movieView(movie)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    viewModel.next()
                                } else if value.translation.width > 50 {
                                    viewModel.previous()
                                }
                                dragOffset = 0
                            }
                    )
                    .onTapGesture {
                        viewModel.stopTimer()
                        showDetail = true
                    }

                VStack {
                    topBar
                    Spacer()
                    bottomControls(movie)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let movie = viewModel.currentMovie {
                MovieDetailView(movie: movie, viewModel: viewModel)
                    .onDisappear {
                        if viewModel.isPlaying {
                            viewModel.startTimer()
                        }
                    }
            }
        }
        .task {
            await viewModel.loadMovies()
        }

            // Banner ad at bottom
            BannerAdView()
                .frame(height: 50)
                .background(Color.black)
        }
    }

    private func movieView(_ movie: Movie) -> some View {
        ZStack {
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Color.gray.overlay(
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                    )
                default:
                    Color.black.overlay(ProgressView().tint(.red))
                }
            }
            .id(movie.id)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .ignoresSafeArea()

            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.85), .black.opacity(0.95)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 350)
            }
            .ignoresSafeArea()
        }
        .offset(x: dragOffset * 0.3)
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.red)
                    Text("MACHINEGUN")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                }

                Spacer()

                // Feed mode picker
                Menu {
                    ForEach(FeedMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            viewModel.selectFeedMode(mode)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.feedMode.rawValue)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            GenreFilterView(
                selectedGenre: viewModel.selectedGenre,
                onSelect: { genre in viewModel.selectGenre(genre) }
            )
        }
    }

    private func bottomControls(_ movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Counter
            HStack {
                Text("\(viewModel.currentIndex + 1) / \(viewModel.movies.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 16)

            // Title + Year
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.trackName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(movie.director)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
                Text(movie.year)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 16)

            // Genre + Rating + Favorite
            HStack(spacing: 12) {
                // Genre badge
                Text(movie.genre)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red.opacity(0.7)))

                // Content rating
                Text(movie.rating)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                // Favorite
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.toggleFavorite(movie)
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite(movie) ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(viewModel.isFavorite(movie) ? .red : .white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)

            // Synopsis
            Text(movie.overview.isEmpty ? "---" : movie.overview)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .padding(.horizontal, 16)

            // Speed control
            SpeedControlView(
                speed: viewModel.speed,
                isPlaying: viewModel.isPlaying,
                onSpeedChange: { viewModel.updateSpeed($0) },
                onTogglePlay: { viewModel.togglePlay() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.7))
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.loadMovies() }
            } label: {
                Text("リトライ")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.red))
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.red)
            Text("Loading...")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
