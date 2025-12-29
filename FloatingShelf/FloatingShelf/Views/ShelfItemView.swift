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
}
