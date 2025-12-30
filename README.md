# FloatingShelf

A lightweight macOS utility for quick file management. Drag files to a floating shelf, organize them, and drag them out to any app.

---

## Features

- 🗂️ **Floating Shelf**: Compact 200×200 window stays on top
- 📁 **Drag & Drop**: Drop files onto menu bar icon or shelf window
- 📋 **Recent Shelves**: Quick access to last 5 shelves (left-click menu bar)
- ✏️ **Auto-naming**: Shelf named after first file
- 🎯 **Quick Actions**: Share, AirDrop, Copy, Save, Delete with one click
- 💾 **Persistent Storage**: Files saved via Core Data
- 🎨 **Color Customization**: Choose from 10 preset colors for each shelf
- 🪟 **Cascading Windows**: New shelves appear offset from existing ones
- ✈️ **AirDrop Sharing**: One-click AirDrop for selected files
- ⚙️ **Auto-hide Settings**: Configure auto-hide delay in Settings

## Installation

### From Source (Xcode)
1. Clone the repository
2. Open `FloatingShelf.xcodeproj` in Xcode
3. Press `⌘+R` to build and run

### Pre-built App
1. Download `FloatingShelf.app` from Releases
2. Move to `/Applications`
3. Right-click → Open (first time only, to bypass Gatekeeper)

## Usage

| Action | How |
|--------|-----|
| Create shelf | Click menu bar icon → New Shelf, or press `⌥⌘Space` |
| Add files | Drag to menu bar icon or shelf window |
| Remove files | Select → Click 🗑️ |
| Rename shelf | Click name in title bar |
| Change color | Click color dot → Select from menu |
| Close shelf | Click ✕ button |

## Requirements

- macOS 12.0+
- Xcode 14+ (for building)

## License

MIT License

---

# FloatingShelf（日本語）

ファイル管理を効率化するmacOS用軽量ユーティリティ。ファイルをフローティングシェルフにドラッグして整理し、任意のアプリにドラッグアウトできます。

---

## 機能

- 🗂️ **フローティングシェルフ**: 200×200のコンパクトウィンドウが常に前面に
- 📁 **ドラッグ＆ドロップ**: メニューバーアイコンまたはシェルフウィンドウにドロップ
- 📋 **最近のシェルフ**: 過去5つのシェルフにクイックアクセス
- ✏️ **自動命名**: 最初のファイル名でシェルフを命名
- 🎯 **クイックアクション**: 共有、AirDrop、コピー、保存、削除をワンクリック
- 💾 **永続ストレージ**: Core Dataでファイルを保存
- 🎨 **Dropover風UI**: モダンな角丸、ミニマルなタイトルバー、ホバーアクションバー
- ✈️ **AirDrop共有**: 選択ファイルをワンクリックでAirDrop
- ⚙️ **自動非表示設定**: 設定で自動非表示の遅延時間を変更可能

## インストール

### ソースから（Xcode）
1. リポジトリをクローン
2. `FloatingShelf.xcodeproj`をXcodeで開く
3. `⌘+R`でビルド＆実行

### ビルド済みアプリ
1. Releasesから`FloatingShelf.app`をダウンロード
2. `/Applications`に移動
3. 右クリック→「開く」（初回のみ、Gatekeeperバイパスのため）

## 使い方

| アクション | 方法 |
|-----------|------|
| シェルフ作成 | メニューバー→New Shelf、または`⌥⌘Space` |
| ファイル追加 | メニューバーまたはシェルフにドラッグ |
| ファイル削除 | 選択→🗑️クリック |
| シェルフ名変更 | タイトルバーの名前をクリック |
| シェルフを閉じる | 赤い●ボタンをクリック |

## 動作環境

- macOS 12.0以上
- Xcode 14以上（ビルド時）

## ライセンス

MITライセンス
