# 🍐 课表  

[![Flutter](https://img.shields.io/badge/Flutter-3.21+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/Rust-1.75+-000000?logo=rust&logoColor=white)](https://www.rust-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> 一款轻盈、优雅且高性能的跨平台课表应用。

**🍐课表** 致力于提供极致的课表管理体验。通过 Flutter 提供华丽的 Material 3 交互界面，配合 Rust 驱动的高性能核心引擎，实现了秒级的自动课表抓取与验证码 OCR 识别。

---

## ✨ 特性亮点

### 🚀 极致性能
- **Rust 驱动核心**：采用 `flutter_rust_bridge` 将复杂的抓取逻辑与 OCR 引擎下沉至 Rust 层，确保应用响应如丝般顺滑。
- **高精度 OCR**：内置基于 Burn 深度学习框架优化的 OCR 引擎，本地识别验证码，无需联网。

### 🎨 现代美学
- **Material 3 设计**：全面接入 Material You 指导原则。
- **动态取色**：支持根据系统壁纸动态调整 UI 配色方案（支持 Android 12+）。
- **FlexColorScheme**：精心调教的色彩搭配，提供深浅色模式下的高级视觉质感。

### 🔐 隐私至上
- **本地化存储**：所有账户信息与课表数据均存储在本地。
- **安全加密**：敏感信息通过 `flutter_secure_storage` 进行硬件级加密保护。

### 🌐 真正全平台
- **桌面端友好**：深度优化 Windows/macOS/Linux 的窗口管理与布局。
- **Web 端支持**：通过跨进程本地网关（Local Native Proxy）完美解决 Web 环境下的跨域抓取难题。

---

## 🛠️ 技术栈

- **Frontend**: Flutter / Dart
- **Logic Engine**: Rust
- **State Management**: Riverpod (AsyncNotifier)
- **Theming**: FlexColorScheme / Dynamic Color
- **OCR Engine**: Burn (Rust Deep Learning Framework)
- **Persistance**: Secure Storage / JSON

---

## 🚀 开发上手

### 1. 环境准备

- **Flutter SDK**: 3.24+
- **Rust**: 1.77+ (wasm 支持建议使用 nightly)
- **Codegen 工具**:
  ```bash
  cargo install flutter_rust_bridge_codegen@2.12.0
  ```

### 2. 依赖安装

```bash
# 获取 Flutter 依赖
flutter pub get
```

### 3. 代码生成 (FRB)

每当修改完 `rust/` 目录下的接口定义后，运行：
```bash
flutter_rust_bridge_codegen generate
```

### 4. 运行应用

```bash
# 运行移动端/桌面端
flutter run

# 运行 Web 端 (发布模式建议先构建 Web 编译后的 JS)
flutter run -d chrome
```

---

## 📂 项目结构

```text
.
├── lib/
│   ├── app/                # 应用全局配置与路由
│   ├── core/               # 核心工具类与通用逻辑
│   ├── features/           # 按功能划分的模块
│   │   ├── timetable/      # 课表展示与计算
│   │   ├── crawler/        # 课表抓取逻辑
│   │   └── settings/       # 用户设置
│   └── main.dart           # 入口文件
├── rust/
│   ├── src/
│   │   ├── crawler/        # 基于 Reqwest 的抓取引擎
│   │   ├── ocr/            # 基于 Burn 的识别引擎
│   │   └── api.rs          # 暴露给 Flutter 的接口
│   └── Cargo.toml          # Rust 依赖配置
└── distribute_options.yaml # CI/CD 分发配置
```

---

## ☘️ 参与贡献

我们欢迎任何形式的贡献！无论是提交 Issue 还是 Pull Request。

> 愿这张课表，帮你把每一天都安排得从容好看。 🍐
