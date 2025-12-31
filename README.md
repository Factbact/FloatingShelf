# FloatingShelf

A lightweight macOS utility for quick file management. Drag files to a floating shelf, organize them, and drag them out to any app.

---

## Features

### Core
- 🗂️ **Floating Shelf**: Compact window stays on top
- 📁 **Drag & Drop**: Drop files onto menu bar icon or shelf window
- 📋 **Recent Shelves**: Quick access to last 5 shelves
- ✏️ **Auto-naming**: Shelf named after first file
- 💾 **Persistent Storage**: Files saved via Core Data

### Actions
- 🎯 **Action Bar**: Customizable buttons (Share, AirDrop, Copy, Paste, Save, ZIP, Delete, Sort)
- ⌨️ **Keyboard Shortcuts**: Delete (⌫), Open (↵), Select All (⌘A), Quick Look (Space)
- 📦 **ZIP Compression**: Bundle selected files into a ZIP archive
- ✈️ **AirDrop Sharing**: One-click AirDrop for selected files
- 🔗 **URL Support**: Drag URLs from browser to save as bookmarks

### UI & Settings
- 🎨 **Color Customization**: Choose from 10 preset colors
- ⚙️ **Settings**: Auto-hide, default color, ZIP location, launch at login
- 🔘 **Customizable Action Bar**: Show/hide buttons in settings
- ↕️ **Sort Options**: Sort by name (A-Z, Z-A) or date (newest, oldest)

## Installation

### From Source (Xcode)
1. Clone the repository
2. Open `FloatingShelf.xcodeproj` in Xcode
3. Press `⌘+R` to build and run

### Pre-built App
1. Download `FloatingShelf.app` from Releases
2. Move to `/Applications`
3. Right-click → Open (first time only)

## Usage

| Action | How |
|--------|-----|
| Create shelf | Menu bar → New Shelf, or `⌥⌘Space` |
| Add files | Drag to shelf window |
| Select all | `⌘A` |
| Delete files | Select → `⌫` or click 🗑️ |
| Open files | Select → `↵` or double-click |
| Quick Look | Select → `Space` |
| Sort files | Click ↑↓ button |
| Rename shelf | Click name in title bar |
| Change color | Click color dot → Select |

## Requirements

- macOS 12.0+
- Xcode 14+ (for building)

## Changelog

### v1.8.0 (2024-12-31)
- 🐛 **Bug Fix**: Fixed critical drag & drop bug where adding files to non-empty shelf failed
- ✨ **Customizable Action Bar**: Choose which buttons to show in Settings
- ↕️ **Sort**: Sort items by name or date
- ⌨️ **Keyboard Shortcuts**: Delete, Enter, Cmd+A support
- 🚀 **Launch at Login**: Option in Settings
- 🎨 **Improved Settings UI**: Card-based layout with Japanese labels

## License

MIT License

---

# FloatingShelf（日本語）

ファイル管理を効率化するmacOS用軽量ユーティリティ。

---

## 機能

### コア機能
- 🗂️ **フローティングシェルフ**: 常に前面に表示されるコンパクトウィンドウ
- 📁 **ドラッグ＆ドロップ**: シェルフにファイルをドロップ
- 📋 **最近のシェルフ**: 過去5つのシェルフにクイックアクセス
- ✏️ **自動命名**: 最初のファイル名でシェルフを命名
- 💾 **永続ストレージ**: Core Dataでファイルを保存

### アクション
- 🎯 **アクションバー**: カスタマイズ可能なボタン（共有、AirDrop、コピー、ペースト、保存、ZIP、削除、並替）
- ⌨️ **キーボードショートカット**: 削除(⌫)、開く(↵)、全選択(⌘A)、クイックルック(Space)
- 📦 **ZIP圧縮**: 選択ファイルをZIPにまとめる
- ✈️ **AirDrop共有**: ワンクリックでAirDrop
- 🔗 **URL対応**: ブラウザからURLをドラッグして保存

### UI・設定
- 🎨 **カラーカスタマイズ**: 10種のプリセットカラー
- ⚙️ **設定**: 自動非表示、デフォルトカラー、ZIP保存先、ログイン時起動
- 🔘 **アクションバーカスタマイズ**: 設定で表示ボタンを選択
- ↕️ **並べ替え**: 名前順・日付順でソート

## インストール

### ソースから（Xcode）
1. リポジトリをクローン
2. `FloatingShelf.xcodeproj`をXcodeで開く
3. `⌘+R`でビルド＆実行

### ビルド済みアプリ
1. Releasesから`FloatingShelf.app`をダウンロード
2. `/Applications`に移動
3. 右クリック→「開く」（初回のみ）

## 使い方

| アクション | 方法 |
|-----------|------|
| シェルフ作成 | メニューバー→New Shelf、または`⌥⌘Space` |
| ファイル追加 | シェルフにドラッグ |
| 全選択 | `⌘A` |
| ファイル削除 | 選択→`⌫`または🗑️クリック |
| ファイルを開く | 選択→`↵`またはダブルクリック |
| クイックルック | 選択→`Space` |
| 並べ替え | ↑↓ボタンをクリック |

## 動作環境

- macOS 12.0以上
- Xcode 14以上（ビルド時）

## 更新履歴

### v1.8.0 (2024-12-31)
- 🐛 **バグ修正**: 既存ファイルがあるシェルフにファイル追加できない問題を修正
- ✨ **アクションバーカスタマイズ**: 設定で表示ボタンを選択可能に
- ↕️ **並べ替え**: 名前順・日付順でソート
- ⌨️ **キーボードショートカット**: Delete、Enter、Cmd+A対応
- 🚀 **ログイン時起動**: 設定で有効化可能
- 🎨 **設定UI改善**: カード形式のレイアウトに刷新

## ライセンス

MITライセンス
