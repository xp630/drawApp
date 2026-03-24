# DrawApp - iPad 儿童画图应用

专为 9 岁儿童设计的 iPad 绘画应用。

## 功能

- **自由绘画** - 手指在画布上自由创作
- **调色盘** - 丰富的颜色选择
- **画笔粗细** - 细/中/粗三档可选
- **橡皮擦** - 修正错误线条
- **草稿箱** - 自动保存作品，随时恢复继续编辑
- **清空画布** - 一键重置

## 技术栈

- **框架**: SwiftUI
- **最低 iOS 版本**: iOS 16.0
- **目标设备**: iPad

## 开发

### 环境准备

1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

2. 克隆项目

```bash
git clone https://github.com/xp630/drawApp.git
cd drawApp
```

3. 生成 Xcode 项目

```bash
cd ios && xcodegen generate
```

4. 用 Xcode 打开

```bash
open DrawApp.xcodeproj
```

5. 选择 iPad 模拟器，按 **Cmd + R** 运行

### 项目结构

```
drawApp/
├── ios/
│   ├── project.yml              # XcodeGen 配置
│   └── DrawApp/
│       ├── App/                 # 应用入口
│       ├── Views/               # UI 视图
│       ├── Models/              # 数据模型
│       └── Services/             # 服务层
└── docs/                        # 设计文档和计划
```

## 后续功能

- AI 智能上色
- AI 画布补全

## 开发者

使用 Claude Code AI 助手开发
