# iPad 儿童画图 app 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 iPad 儿童绘画 app，包含基础画布、手指绘画、调色盘、画笔粗细、橡皮擦、草稿箱功能

**Architecture:** SwiftUI 单页面应用，Canvas View 处理触摸绘制，本地 FileManager 存储草稿图片，UserDefaults 存储草稿元数据

**Tech Stack:** SwiftUI, XcodeGen, iOS 16+

---

## 文件结构

```
drawApp/
└── ios/
    ├── project.yml              # XcodeGen 配置
    ├── DrawApp/
    │   ├── App/
    │   │   └── DrawAppApp.swift
    │   ├── Views/
    │   │   ├── ContentView.swift      # 主容器：工具栏 + 画布
    │   │   ├── CanvasView.swift       # 画布：触摸绘画
    │   │   ├── ToolbarView.swift       # 工具栏：颜色/粗细/橡皮/清空/草稿箱/关闭
    │   │   └── DraftBoxView.swift     # 草稿箱：列表弹窗
    │   ├── Models/
    │   │   ├── DrawingLine.swift       # 绘制线条模型
    │   │   └── Draft.swift            # 草稿模型
    │   ├── Services/
    │   │   └── DraftStorage.swift     # 草稿存储服务
    │   └── Assets.xcassets/
    └── Podfile                    # 依赖管理（未来 AI 功能）
```

---

## 环境准备

### Task 0: 安装 XcodeGen

- [ ] **Step 1: 检查/安装 XcodeGen**

Run: `brew install xcodegen` (macOS)
或从 https://github.com/yonaskolb/XcodeGen/releases 下载

Expected: `xcodegen version 2.x.x`

---

## 项目初始化

### Task 1: 创建 XcodeGen 配置

**Files:**
- Create: `ios/project.yml`

```yaml
name: DrawApp
options:
  bundleIdPrefix: com.drawapp
  deploymentTarget:
    iOS: "16.0"
  developmentLanguage: zh-Hans

settings:
  base:
    TARGETED_DEVICE_FAMILY: "2"
    SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD: false
    SWIFT_VERSION: "5.9"

targets:
  DrawApp:
    type: application
    platform: iOS
    sources:
      - path: DrawApp
        type: group
    settings:
      base:
        INFOPLIST_FILE: DrawApp/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.drawapp.ipad
        TARGETED_DEVICE_FAMILY: "2"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        DEVELOPMENT_TEAM: ""
        CODE_SIGN_STYLE: Automatic
        CODE_SIGN_IDENTITY: "-"
```

- [ ] **Step 1: 创建 `ios/project.yml`**

- [ ] **Step 2: 创建 `ios/DrawApp/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: 生成 Xcode 项目**

Run: `cd ios && xcodegen generate`
Expected: `generated: DrawApp.xcodeproj`

- [ ] **Step 4: 提交**

```bash
git add ios/project.yml ios/DrawApp/Info.plist
git commit -m "chore: add XcodeGen project config"
```

---

## 数据模型

### Task 2: DrawingLine 模型

**Files:**
- Create: `ios/DrawApp/Models/DrawingLine.swift`

```swift
import SwiftUI

struct DrawingLine: Identifiable, Equatable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool = false

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 3, isEraser: Bool = false) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.isEraser = isEraser
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Models/DrawingLine.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Models/DrawingLine.swift
git commit -m "feat: add DrawingLine model"
```

---

### Task 3: Draft 草稿模型

**Files:**
- Create: `ios/DrawApp/Models/Draft.swift`

```swift
import Foundation

struct Draft: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var thumbnailFileName: String
    var drawingDataFileName: String

    init(id: UUID = UUID(), createdAt: Date = Date(), updatedAt: Date = Date(), thumbnailFileName: String = "", drawingDataFileName: String = "") {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailFileName = thumbnailFileName
        self.drawingDataFileName = drawingDataFileName
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Models/Draft.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Models/Draft.swift
git commit -m "feat: add Draft model"
```

---

## 草稿存储服务

### Task 4: DraftStorage 草稿存储服务

**Files:**
- Create: `ios/DrawApp/Services/DraftStorage.swift`

```swift
import SwiftUI
import Combine

class DraftStorage: ObservableObject {
    static let shared = DraftStorage()

    @Published var drafts: [Draft] = []

    private let fileManager = FileManager.default
    private var draftsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let drafts = documents.appendingPathComponent("Drafts", isDirectory: true)
        if !fileManager.fileExists(atPath: drafts.path) {
            try? fileManager.createDirectory(at: drafts, withIntermediateDirectories: true)
        }
        return drafts
    }

    private let userDefaultsKey = "com.drawapp.drafts"

    init() {
        loadDrafts()
    }

    func loadDrafts() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([Draft].self, from: data) else {
            drafts = []
            return
        }
        drafts = saved.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveDrafts() {
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    func saveDraft(lines: [DrawingLine], thumbnail: UIImage) -> Draft {
        let draft = Draft()

        let thumbnailURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_thumb.png")
        let drawingDataURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_data.json")

        if let thumbData = thumbnail.pngData() {
            try? thumbData.write(to: thumbnailURL)
        }

        let drawingData = DrawingData(lines: lines)
        if let jsonData = try? JSONEncoder().encode(drawingData) {
            try? jsonData.write(to: drawingDataURL)
        }

        var savedDraft = draft
        savedDraft.thumbnailFileName = thumbnailURL.lastPathComponent
        savedDraft.drawingDataFileName = drawingDataURL.lastPathComponent

        drafts.insert(savedDraft, at: 0)
        saveDrafts()

        return savedDraft
    }

    func loadDrawingData(for draft: Draft) -> [DrawingLine] {
        let drawingDataURL = draftsDirectory.appendingPathComponent(draft.drawingDataFileName)
        guard let data = try? Data(contentsOf: drawingDataURL),
              let drawingData = try? JSONDecoder().decode(DrawingData.self, from: data) else {
            return []
        }
        return drawingData.lines
    }

    func deleteDraft(_ draft: Draft) {
        let thumbnailURL = draftsDirectory.appendingPathComponent(draft.thumbnailFileName)
        let drawingDataURL = draftsDirectory.appendingPathComponent(draft.drawingDataFileName)

        try? fileManager.removeItem(at: thumbnailURL)
        try? fileManager.removeItem(at: drawingDataURL)

        drafts.removeAll { $0.id == draft.id }
        saveDrafts()
    }

    func getThumbnailURL(for draft: Draft) -> URL {
        return draftsDirectory.appendingPathComponent(draft.thumbnailFileName)
    }
}

struct DrawingData: Codable {
    var lines: [DrawingLine]
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Services/DraftStorage.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Services/DraftStorage.swift
git commit -m "feat: add DraftStorage service"
```

---

## 视图层

### Task 5: CanvasView 画布视图

**Files:**
- Create: `ios/DrawApp/Views/CanvasView.swift`

```swift
import SwiftUI

struct CanvasView: View {
    @Binding var lines: [DrawingLine]
    @Binding var currentColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool

    var onSaveThumbnail: ((UIImage) -> Void)?

    var body: some View {
        Canvas { context, size in
            for line in lines {
                var path = Path()
                if let firstPoint = line.points.first {
                    path.move(to: firstPoint)
                    for point in line.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                context.stroke(
                    path,
                    with: .color(line.isEraser ? .white : line.color),
                    style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    if let lastLine = lines.last, lastLine.id == lines.last?.id {
                        var newLines = lines
                        if newLines[newLines.count - 1].points.last == point {
                            return
                        }
                        newLines[newLines.count - 1].points.append(point)
                        lines = newLines
                    } else {
                        let newLine = DrawingLine(
                            points: [point],
                            color: currentColor,
                            lineWidth: lineWidth,
                            isEraser: isEraser
                        )
                        lines.append(newLine)
                    }
                }
        )
        .background(Color.white)
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Views/CanvasView.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Views/CanvasView.swift
git commit -m "feat: add CanvasView with touch drawing"
```

---

### Task 6: ToolbarView 工具栏视图

**Files:**
- Create: `ios/DrawApp/Views/ToolbarView.swift`

```swift
import SwiftUI

struct ToolbarView: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var showDraftBox: Bool
    @Binding var showColorPicker: Bool
    @Binding var isToolbarVisible: Bool

    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
                    .font(.caption)
                    .foregroundColor(.gray)

                Button {
                    showColorPicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedColor)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // 画笔粗细
            VStack(alignment: .leading, spacing: 8) {
                Text("画笔")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    BrushSizeButton(width: 3, selectedWidth: $lineWidth)
                    BrushSizeButton(width: 8, selectedWidth: $lineWidth)
                    BrushSizeButton(width: 15, selectedWidth: $lineWidth)
                }
            }

            // 橡皮擦
            Button {
                isEraser.toggle()
            } label: {
                VStack {
                    Image(systemName: isEraser ? "eraser.fill" : "eraser")
                        .font(.title2)
                    Text("橡皮")
                        .font(.caption)
                }
                .foregroundColor(isEraser ? .blue : .primary)
                .frame(width: 60, height: 60)
                .background(isEraser ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }

            // 清空
            Button {
                onClear()
            } label: {
                VStack {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("清空")
                        .font(.caption)
                }
                .foregroundColor(.red)
                .frame(width: 60, height: 60)
            }

            // 草稿箱
            Button {
                showDraftBox = true
            } label: {
                VStack {
                    Image(systemName: "folder")
                        .font(.title2)
                    Text("草稿箱")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
            }

            Spacer()

            // 关闭工具栏
            Button {
                isToolbarVisible = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(UIColor.systemGray6))
    }
}

struct BrushSizeButton: View {
    let width: CGFloat
    @Binding var selectedWidth: CGFloat

    var isSelected: Bool {
        selectedWidth == width
    }

    var body: some View {
        Button {
            selectedWidth = width
        } label: {
            Circle()
                .fill(isSelected ? Color.blue : Color.gray)
                .frame(width: min(width * 2, 30), height: min(width * 2, 30))
        }
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Views/ToolbarView.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Views/ToolbarView.swift
git commit -m "feat: add ToolbarView with color, brush size, eraser"
```

---

### Task 7: DraftBoxView 草稿箱视图

**Files:**
- Create: `ios/DrawApp/Views/DraftBoxView.swift`

```swift
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
```

- [ ] **Step 1: 创建 `ios/DrawApp/Views/DraftBoxView.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Views/DraftBoxView.swift
git commit -m "feat: add DraftBoxView with draft list"
```

---

### Task 8: ContentView 主容器视图

**Files:**
- Create: `ios/DrawApp/Views/ContentView.swift`

```swift
import SwiftUI

struct ContentView: View {
    @State private var lines: [DrawingLine] = []
    @State private var currentColor: Color = .black
    @State private var lineWidth: CGFloat = 3
    @State private var isEraser: Bool = false
    @State private var isToolbarVisible: Bool = true
    @State private var showDraftBox: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showClearConfirm: Bool = false
    @StateObject private var draftStorage = DraftStorage.shared

    private let autoSaveInterval: TimeInterval = 30

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 画布区域
                CanvasView(
                    lines: $lines,
                    currentColor: $currentColor,
                    lineWidth: $lineWidth,
                    isEraser: $isEraser,
                    onSaveThumbnail: { image in
                        _ = draftStorage.saveDraft(lines: lines, thumbnail: image)
                    }
                )

                // 工具栏
                if isToolbarVisible {
                    HStack(spacing: 0) {
                        ToolbarView(
                            selectedColor: $currentColor,
                            lineWidth: $lineWidth,
                            isEraser: $isEraser,
                            showDraftBox: $showDraftBox,
                            showColorPicker: $showColorPicker,
                            isToolbarVisible: $isToolbarVisible,
                            onClear: {
                                showClearConfirm = true
                            }
                        )

                        Spacer()
                    }
                }

                // 打开工具栏按钮
                if !isToolbarVisible {
                    VStack {
                        HStack {
                            Button {
                                isToolbarVisible = true
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showDraftBox) {
            DraftBoxView(
                isPresented: $showDraftBox,
                onSelectDraft: { draft in
                    lines = draftStorage.loadDrawingData(for: draft)
                },
                onNewCanvas: {
                    lines = []
                }
            )
            .environmentObject(draftStorage)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $currentColor, isPresented: $showColorPicker)
        }
        .alert("清空画布", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                lines = []
            }
        } message: {
            Text("确定要清空画布吗？此操作无法撤销。")
        }
        .onAppear {
            startAutoSave()
        }
    }

    private func startAutoSave() {
        Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            saveThumbnail()
        }
    }

    private func saveThumbnail() {
        guard !lines.isEmpty else { return }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))

            for line in lines {
                let path = UIBezierPath()
                if let firstPoint = line.points.first {
                    path.move(to: firstPoint)
                    for point in line.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                path.lineWidth = line.lineWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                (line.isEraser ? UIColor.white : UIColor(line.color)).setStroke()
                path.stroke()
            }
        }
        _ = draftStorage.saveDraft(lines: lines, thumbnail: image)
    }
}

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                ColorPicker("选择颜色", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(2)
                    .padding()

                Spacer()
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/Views/ContentView.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Views/ContentView.swift
git commit -m "feat: add ContentView as main container"
```

---

## 应用入口

### Task 9: DrawAppApp 应用入口

**Files:**
- Create: `ios/DrawApp/App/DrawAppApp.swift`

```swift
import SwiftUI

@main
struct DrawAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Step 1: 创建 `ios/DrawApp/App/DrawAppApp.swift`**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/App/DrawAppApp.swift
git commit -m "feat: add DrawAppApp entry point"
```

---

## 资源文件

### Task 10: Assets.xcassets 资源目录

**Files:**
- Create: `ios/DrawApp/Assets.xcassets/Contents.json`

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- Create: `ios/DrawApp/Assets.xcassets/AppIcon.appiconset/Contents.json`

```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 1: 创建 Assets.xcassets 目录结构**

- [ ] **Step 2: 提交**

```bash
git add ios/DrawApp/Assets.xcassets/
git commit -m "chore: add Assets.xcassets"
```

---

## 构建验证

### Task 11: 生成项目并验证构建

- [ ] **Step 1: 重新生成 Xcode 项目**

Run: `cd ios && xcodegen generate`

- [ ] **Step 2: 在 Xcode 中打开项目**

Run: `open ios/DrawApp.xcodeproj`

- [ ] **Step 3: 选择 iPad 模拟器并构建**

在 Xcode 中: Product → Build (Cmd + B)
Expected: Build Succeeded

- [ ] **Step 4: 最终提交**

```bash
git add .
git commit -m "feat: complete iPad drawing app v1.0"
```

---

## 运行步骤总结

1. `brew install xcodegen` — 安装 XcodeGen
2. `cd ios && xcodegen generate` — 生成 Xcode 项目
3. `open ios/DrawApp.xcodeproj` — 用 Xcode 打开
4. 选择 iPad 模拟器 → Cmd + R 运行

---

## 后续功能（不在本计划范围内）

- AI 上色功能
- AI 画布补全
- 更多画笔工具
- 撤销/重做
- 导出功能
