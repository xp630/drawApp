import SwiftUI

struct DraftBoxView: View {
    @EnvironmentObject var draftStorage: DraftStorage
    @Binding var isPresented: Bool
    var onSelectDraft: (Draft) -> Void
    var onNewCanvas: () -> Void

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(draftStorage.drafts) { draft in
                        DraftThumbnailView(draft: draft)
                            .onTapGesture {
                                onSelectDraft(draft)
                                isPresented = false
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    draftStorage.deleteDraft(draft)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("草稿箱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onNewCanvas()
                        isPresented = false
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct DraftThumbnailView: View {
    let draft: Draft

    var body: some View {
        VStack {
            if let url = try? DraftStorage.shared.getThumbnailURL(for: draft),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }

            Text(draft.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
