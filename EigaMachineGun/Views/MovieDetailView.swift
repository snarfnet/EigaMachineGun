import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Backdrop
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: movie.backdropURL ?? movie.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                                    .clipped()
                            default:
                                Color.gray
                                    .frame(height: 280)
                                    .overlay(ProgressView().tint(.white))
                            }
                        }

                        LinearGradient(
                            colors: [.clear, Color(.systemBackground)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 100)
                    }
                    .frame(height: 280)

                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        Text(movie.trackName)
                            .font(.system(size: 26, weight: .bold))

                        // Director
                        Text(movie.director)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        // Info row
                        HStack(spacing: 16) {
                            Label(movie.year, systemImage: "calendar")
                                .font(.system(size: 14, weight: .medium))

                            Label(movie.genre, systemImage: "film")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)

                            Text(movie.rating)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary, lineWidth: 1))

                            Spacer()

                            Button {
                                withAnimation { viewModel.toggleFavorite(movie) }
                            } label: {
                                Image(systemName: viewModel.isFavorite(movie) ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isFavorite(movie) ? .red : .secondary)
                            }
                        }

                        // Preview trailer button
                        if let previewURL = movie.previewVideoURL {
                            Link(destination: previewURL) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Preview")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red)
                                )
                            }
                        }

                        // iTunes Store link
                        if let storeURL = movie.storeURL {
                            Link(destination: storeURL) {
                                HStack {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("iTunes Store")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red, lineWidth: 1.5)
                                )
                            }
                        }

                        // Synopsis
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Synopsis")
                                .font(.system(size: 18, weight: .bold))

                            Text(movie.overview.isEmpty ? "No synopsis available." : movie.overview)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }

                        // Price
                        if let price = movie.trackPrice, price > 0 {
                            HStack {
                                Image(systemName: "yensign.circle.fill")
                                    .foregroundColor(.green)
                                Text("\u{00A5}\(Int(price))")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.red)
                }
            }
        }
    }
}
