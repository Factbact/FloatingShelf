//
//  ShelfItemView.swift
//  FloatingShelf
//

import Cocoa

protocol ShelfItemViewDelegate: AnyObject {
    func itemView(_ view: ShelfItemView, didStartDragging item: ShelfItem)
}

class ShelfItemView: NSView {
    
    weak var delegate: ShelfItemViewDelegate?
    
    var item: ShelfItem? {
        didSet {
            updateUI()
        }
    }
    
    var isItemSelected: Bool = false {
        didSet {
            updateSelection()
        }
    }
    
    private let imageView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let selectionOverlay = NSView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Selection overlay
        selectionOverlay.wantsLayer = true
        selectionOverlay.layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.3).cgColor
        selectionOverlay.layer?.cornerRadius = 8
        selectionOverlay.isHidden = true
        selectionOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(selectionOverlay)
        
        // Image view (thumbnail)
        imageView.imageScaling = .scaleProportionallyDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Name label
        nameLabel.font = NSFont.systemFont(ofSize: 11)
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.maximumNumberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            selectionOverlay.topAnchor.constraint(equalTo: topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4)
        ])
        
        // Enable drag
        registerForDraggedTypes([.fileURL, .string])
    }
    
    private func updateUI() {
        guard let item = item else { return }
        
        nameLabel.stringValue = item.displayName
        
        // Set tooltip with file info
        let sizeString = ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file)
        toolTip = "\(item.displayName)\n\(item.kind.displayName) • \(sizeString)"
        
        // Load thumbnail
        if let thumbnailPath = item.thumbnailPath {
            do {
                let thumbDir = try FileManager.default.thumbnailsDirectory()
                let thumbURL = thumbDir.appendingPathComponent(thumbnailPath)
                if let image = NSImage(contentsOf: thumbURL) {
                    imageView.image = image
                    return
                }
            } catch {
                print("Error loading thumbnail: \(error)")
            }
        }
        
        // Fall back to default icon
        imageView.image = NSImage(systemSymbolName: item.kind.iconName, accessibilityDescription: item.kind.displayName)
    }
    
    private func updateSelection() {
        selectionOverlay.isHidden = !isItemSelected
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        // Double-click to open file
        if event.clickCount == 2, let item = item {
            openFile(item)
        }
    }
    
    private func openFile(_ item: ShelfItem) {
        guard let payloadPath = item.payloadPath else { return }
        
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            let fileURL = storageDir.appendingPathComponent(payloadPath)
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                NSWorkspace.shared.open(fileURL)
            }
        } catch {
            print("Error opening file: \(error)")
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let item = item else { return }
        
        // Start drag operation
        let dragSource = DragSource(item: item)
        // Keep reference to source if needed, or rely on system retaining it during drag
        // For simplicity here we recreate it, but in production consider retaining it if delegate callbacks need state
        
        let dragImage = imageView.image ?? NSImage(systemSymbolName: "doc.fill", accessibilityDescription: "File")!
        let draggingItems = dragSource.draggingItems(for: dragImage)
        
        if !draggingItems.isEmpty {
            beginDraggingSession(with: draggingItems, event: event, source: dragSource)
            delegate?.itemView(self, didStartDragging: item)
        }
    }
    
    // MARK: - Context Menu
    
    override func rightMouseDown(with event: NSEvent) {
        guard item != nil else { return }
        
        let menu = NSMenu()
        
        // Open & Preview
        let openItem = NSMenuItem(title: "開く", action: #selector(menuOpenFile), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        
        let quickLookItem = NSMenuItem(title: "クイックルック", action: #selector(menuQuickLook), keyEquivalent: "")
        quickLookItem.target = self
        menu.addItem(quickLookItem)
        
        let showItem = NSMenuItem(title: "Finderで表示", action: #selector(menuShowInFinder), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Copy & Share
        let copyFileItem = NSMenuItem(title: "ファイルをコピー", action: #selector(menuCopyFile), keyEquivalent: "")
        copyFileItem.target = self
        menu.addItem(copyFileItem)
        
        let copyPathItem = NSMenuItem(title: "パスをコピー", action: #selector(menuCopyPath), keyEquivalent: "")
        copyPathItem.target = self
        menu.addItem(copyPathItem)
        
        let shareItem = NSMenuItem(title: "共有...", action: #selector(menuShare), keyEquivalent: "")
        shareItem.target = self
        menu.addItem(shareItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Delete
        let deleteItem = NSMenuItem(title: "削除", action: #selector(menuDelete), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    
    @objc private func menuOpenFile() {
        guard let item = item else { return }
        openFile(item)
    }
    
    @objc private func menuShowInFinder() {
        guard let item = item, let payloadPath = item.payloadPath else { return }
        
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            let fileURL = storageDir.appendingPathComponent(payloadPath)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            print("Error showing in Finder: \(error)")
        }
    }
    
    @objc private func menuCopyPath() {
        guard let item = item, let payloadPath = item.payloadPath else { return }
        
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            let fileURL = storageDir.appendingPathComponent(payloadPath)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fileURL.path, forType: .string)
        } catch {
            print("Error copying path: \(error)")
        }
    }
    
    @objc private func menuQuickLook() {
        guard let item = item else { return }
        NotificationCenter.default.post(name: NSNotification.Name("QuickLookShelfItem"), object: item)
    }
    
    @objc private func menuCopyFile() {
        guard let item = item, let payloadPath = item.payloadPath else { return }
        
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            let fileURL = storageDir.appendingPathComponent(payloadPath)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([fileURL as NSURL])
        } catch {
            print("Error copying file: \(error)")
        }
    }
    
    @objc private func menuShare() {
        guard let item = item, let payloadPath = item.payloadPath else { return }
        
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            let fileURL = storageDir.appendingPathComponent(payloadPath)
            
            let picker = NSSharingServicePicker(items: [fileURL])
            picker.show(relativeTo: bounds, of: self, preferredEdge: .minY)
        } catch {
            print("Error sharing file: \(error)")
        }
    }
    
    @objc private func menuDelete() {
        guard let item = item else { return }
        NotificationCenter.default.post(name: NSNotification.Name("DeleteShelfItem"), object: item)
    }
}
