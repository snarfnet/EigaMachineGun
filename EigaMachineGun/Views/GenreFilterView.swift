import SwiftUI

struct GenreFilterView: View {
    let selectedGenre: Genre
    let onSelect: (Genre) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allGenres) { genre in
                    Button {
                        onSelect(genre)
                    } label: {
                        HStack(spacing: 4) {
                            Text(genre.emoji)
                                .font(.system(size: 12))
                            Text(genre.name)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedGenre.id == genre.id
                                      ? Color.red
                                      : Color.white.opacity(0.1))
                        )
                        .foregroundColor(selectedGenre.id == genre.id ? .white : .white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
