import SwiftUI

struct DraftBoxView: View {
    @EnvironmentObject var draftStorage: DraftStorage
    @Binding var isPresented: Bool
    @Binding var autoSaveEnabled: Bool
    var onSelectDraft: (Draft) -> Void
    var onNewCanvas: () -> Void

    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 自动保存开关
                Toggle(isOn: $autoSaveEnabled) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                        Text("自动保存草稿")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(draftStorage.drafts) { draft in
                            DraftThumbnailView(draft: draft, onDelete: {
                                draftStorage.deleteDraft(draft)
                            })
                                .onTapGesture {
                                    onSelectDraft(draft)
                                    isPresented = false
                                }
                        }
                    }
                    .padding()
                }
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
    var onDelete: (() -> Void)?

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
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

                // 删除按钮
                if let onDelete = onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                            .background(Circle().fill(Color.white))
                    }
                    .padding(6)
                }
            }

            Text(draft.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
