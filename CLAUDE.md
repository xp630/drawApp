# DrawApp - iPad 儿童画图应用

## 项目概述

- **目标用户**: 9 岁儿童
- **平台**: iPad（独立使用，不发布 App Store）
- **开发方式**: Xcode 真机调试

## 技术栈

- **前端**: SwiftUI
- **项目生成**: XcodeGen
- **数据持久化**: UserDefaults + FileManager

## 项目结构

```
ios/
├── project.yml              # XcodeGen 配置
├── DrawApp.xcodeproj/       # 生成后
└── DrawApp/
    ├── App/DrawAppApp.swift
    ├── Views/
    │   ├── ContentView.swift
    │   ├── CanvasView.swift
    │   ├── ToolbarView.swift
    │   └── DraftBoxView.swift
    ├── Models/
    │   ├── DrawingLine.swift
    │   └── Draft.swift
    └── Services/
        └── DraftStorage.swift
```

## 功能范围（第一阶段）

- 画布绘画（手指触摸）
- 调色盘选择颜色
- 画笔粗细（细/中/粗）
- 橡皮擦
- 清空画布
- 草稿箱（自动保存 + 列表管理）

## 后续功能

- AI 上色
- AI 画布补全
- Python FastAPI 本地服务 + OpenAI API

## 开发命令

```bash
# 安装 XcodeGen（macOS）
brew install xcodegen

# 生成 Xcode 项目
cd ios && xcodegen generate

# 用 Xcode 打开
open DrawApp.xcodeproj
```

## 注意事项

- 本项目仅自己使用，不发布 App Store
- 无需付费 Apple Developer 账号
- 使用 Xcode 免费证书真机调试
