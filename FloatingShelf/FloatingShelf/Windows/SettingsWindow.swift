//
//  SettingsWindow.swift
//  FloatingShelf
//

import Cocoa

class SettingsWindowController: NSWindowController {
    
    static let shared = SettingsWindowController()
    private var buttonCheckboxes: [NSButton] = []
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "設定"
        window.center()
        
        super.init(window: window)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Scroll view for content
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        contentView.addSubview(scrollView)
        
        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        var yOffset: CGFloat = 20
        
        // === Auto-Hide Section ===
        yOffset = addSectionCard(to: documentView, at: yOffset, title: "自動非表示", content: { cardView in
            var innerY: CGFloat = 10
            
            let checkbox = NSButton(checkboxWithTitle: "空のシェルフを自動非表示", target: self, action: #selector(toggleAutoHide(_:)))
            checkbox.state = SettingsManager.shared.autoHideEnabled ? .on : .off
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.topAnchor.constraint(equalTo: cardView.topAnchor, constant: innerY),
                checkbox.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15)
            ])
            innerY += 30
            
            let delayStack = NSStackView()
            delayStack.orientation = .horizontal
            delayStack.spacing = 8
            delayStack.translatesAutoresizingMaskIntoConstraints = false
            
            let delayLabel = NSTextField(labelWithString: "閉じるまで:")
            let delayField = NSTextField()
            delayField.stringValue = String(Int(SettingsManager.shared.autoHideDelay))
            delayField.isEditable = true
            delayField.target = self
            delayField.action = #selector(delayChanged(_:))
            delayField.widthAnchor.constraint(equalToConstant: 40).isActive = true
            let secondsLabel = NSTextField(labelWithString: "秒")
            
            delayStack.addArrangedSubview(delayLabel)
            delayStack.addArrangedSubview(delayField)
            delayStack.addArrangedSubview(secondsLabel)
            cardView.addSubview(delayStack)
            NSLayoutConstraint.activate([
                delayStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: innerY),
                delayStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15)
            ])
            
            return 70
        })
        
        // === Appearance Section ===
        yOffset = addSectionCard(to: documentView, at: yOffset, title: "外観", content: { cardView in
            let colorStack = NSStackView()
            colorStack.orientation = .horizontal
            colorStack.spacing = 8
            colorStack.translatesAutoresizingMaskIntoConstraints = false
            
            let colorLabel = NSTextField(labelWithString: "デフォルトカラー:")
            let colorPopup = NSPopUpButton()
            let colors = ["#4A90D9", "#5C6BC0", "#7E57C2", "#EC407A", "#EF5350", "#FF7043", "#FFCA28", "#66BB6A", "#26A69A", "#78909C"]
            let colorNames = ["ブルー", "インディゴ", "パープル", "ピンク", "レッド", "オレンジ", "イエロー", "グリーン", "ティール", "グレー"]
            for (index, name) in colorNames.enumerated() {
                colorPopup.addItem(withTitle: name)
                if colors[index] == SettingsManager.shared.defaultShelfColor {
                    colorPopup.selectItem(at: index)
                }
            }
            colorPopup.target = self
            colorPopup.action = #selector(colorPopupChanged(_:))
            colorPopup.tag = 200
            
            colorStack.addArrangedSubview(colorLabel)
            colorStack.addArrangedSubview(colorPopup)
            cardView.addSubview(colorStack)
            NSLayoutConstraint.activate([
                colorStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
                colorStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15)
            ])
            
            return 50
        })
        
        // === ZIP Section ===
        yOffset = addSectionCard(to: documentView, at: yOffset, title: "ZIP圧縮", content: { cardView in
            let zipStack = NSStackView()
            zipStack.orientation = .horizontal
            zipStack.spacing = 8
            zipStack.translatesAutoresizingMaskIntoConstraints = false
            
            let zipLabel = NSTextField(labelWithString: "保存先:")
            let zipPopup = NSPopUpButton()
            zipPopup.addItems(withTitles: ["ダウンロード", "デスクトップ", "毎回確認"])
            let locations = ["downloads", "desktop", "ask"]
            if let index = locations.firstIndex(of: SettingsManager.shared.zipSaveLocation) {
                zipPopup.selectItem(at: index)
            }
            zipPopup.target = self
            zipPopup.action = #selector(zipLocationChanged(_:))
            zipPopup.tag = 300
            
            zipStack.addArrangedSubview(zipLabel)
            zipStack.addArrangedSubview(zipPopup)
            cardView.addSubview(zipStack)
            NSLayoutConstraint.activate([
                zipStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
                zipStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15)
            ])
            
            return 50
        })
        
        // === Startup Section ===
        yOffset = addSectionCard(to: documentView, at: yOffset, title: "起動", content: { cardView in
            let checkbox = NSButton(checkboxWithTitle: "ログイン時に起動", target: self, action: #selector(toggleLaunchAtLogin(_:)))
            checkbox.state = SettingsManager.shared.isLaunchAtLoginEnabled ? .on : .off
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(checkbox)
            NSLayoutConstraint.activate([
                checkbox.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
                checkbox.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 15)
            ])
            
            return 45
        })
        
        // === Action Bar Section ===
        yOffset = addSectionCard(to: documentView, at: yOffset, title: "アクションバー", content: { cardView in
            let buttonLabels = ["全選択", "並替", "共有", "AirDrop", "コピー", "ペースト", "保存", "ZIP", "削除"]
            let buttonIds = SettingsManager.allButtonIds
            let visibleButtons = SettingsManager.shared.visibleActionButtons
            
            var checkboxes: [NSButton] = []
            for (index, label) in buttonLabels.enumerated() {
                let checkbox = NSButton(checkboxWithTitle: label, target: self, action: #selector(toggleActionButton(_:)))
                checkbox.state = visibleButtons.contains(buttonIds[index]) ? .on : .off
                checkbox.tag = 500 + index
                checkbox.translatesAutoresizingMaskIntoConstraints = false
                cardView.addSubview(checkbox)
                
                let row = index / 3
                let col = index % 3
                NSLayoutConstraint.activate([
                    checkbox.topAnchor.constraint(equalTo: cardView.topAnchor, constant: CGFloat(10 + row * 26)),
                    checkbox.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: CGFloat(15 + col * 115))
                ])
                checkboxes.append(checkbox)
            }
            self.buttonCheckboxes = checkboxes
            
            return 90
        })
        
        // Set document view height
        documentView.frame = NSRect(x: 0, y: 0, width: 380, height: yOffset + 20)
        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalToConstant: 380)
        ])
    }
    
    private func addSectionCard(to parent: NSView, at yOffset: CGFloat, title: String, content: (NSView) -> CGFloat) -> CGFloat {
        let cardView = NSView()
        cardView.wantsLayer = true
        cardView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        cardView.layer?.cornerRadius = 10
        cardView.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(cardView)
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: parent.topAnchor, constant: yOffset),
            titleLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20)
        ])
        
        let contentHeight = content(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: parent.topAnchor, constant: yOffset + 22),
            cardView.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 15),
            cardView.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -15),
            cardView.heightAnchor.constraint(equalToConstant: contentHeight)
        ])
        
        return yOffset + 22 + contentHeight + 15
    }
    
    // MARK: - Actions
    
    @objc private func toggleActionButton(_ sender: NSButton) {
        let buttonIds = SettingsManager.allButtonIds
        let index = sender.tag - 500
        guard index >= 0 && index < buttonIds.count else { return }
        
        var visible = SettingsManager.shared.visibleActionButtons
        let buttonId = buttonIds[index]
        
        if sender.state == .on {
            if !visible.contains(buttonId) {
                visible.append(buttonId)
            }
        } else {
            visible.removeAll { $0 == buttonId }
        }
        
        SettingsManager.shared.visibleActionButtons = visible
    }
    
    @objc private func toggleAutoHide(_ sender: NSButton) {
        SettingsManager.shared.autoHideEnabled = sender.state == .on
    }
    
    @objc private func delayChanged(_ sender: NSTextField) {
        if let value = Double(sender.stringValue), value >= 1 && value <= 60 {
            SettingsManager.shared.autoHideDelay = value
        }
    }
    
    @objc private func colorPopupChanged(_ sender: NSPopUpButton) {
        let colors = ["#4A90D9", "#5C6BC0", "#7E57C2", "#EC407A", "#EF5350", "#FF7043", "#FFCA28", "#66BB6A", "#26A69A", "#78909C"]
        let index = sender.indexOfSelectedItem
        if index >= 0 && index < colors.count {
            SettingsManager.shared.defaultShelfColor = colors[index]
        }
    }
    
    @objc private func zipLocationChanged(_ sender: NSPopUpButton) {
        let locations = ["downloads", "desktop", "ask"]
        let index = sender.indexOfSelectedItem
        if index >= 0 && index < locations.count {
            SettingsManager.shared.zipSaveLocation = locations[index]
        }
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        SettingsManager.shared.launchAtLogin = sender.state == .on
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
