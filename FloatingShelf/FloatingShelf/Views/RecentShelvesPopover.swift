//
//  RecentShelvesPopover.swift
//  FloatingShelf
//

import Cocoa

class RecentShelvesPopover: NSViewController {
    
    weak var appDelegate: AppDelegate?
    private var shelves: [Shelf] = []
    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 300))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadShelves()
    }
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // Title
        let titleLabel = NSTextField(labelWithString: "Recent Shelves")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Stack view for shelf items
        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Scroll view
        scrollView.documentView = stackView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Footer
        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)
        
        let footerStack = NSStackView()
        footerStack.orientation = .horizontal
        footerStack.distribution = .equalSpacing
        footerStack.spacing = 16
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(footerStack)
        
        // Footer buttons
        let newShelfButton = createButton(icon: "plus", tooltip: "New Shelf", action: #selector(newShelfAction))
        let settingsButton = createButton(icon: "gearshape", tooltip: "Settings", action: #selector(settingsAction))
        let quitButton = createButton(icon: "power", tooltip: "Quit", action: #selector(quitAction))
        
        footerStack.addArrangedSubview(newShelfButton)
        footerStack.addArrangedSubview(settingsButton)
        footerStack.addArrangedSubview(quitButton)
        
        // Layout constraints - FIXED: proper constraint chain
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor), // FIXED!
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            footerStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 8),
            footerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            footerStack.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func createButton(icon: String, tooltip: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.image = NSImage(systemSymbolName: icon, accessibilityDescription: tooltip)
        button.target = self
        button.action = action
        button.bezelStyle = .texturedRounded
        button.isBordered = false
        button.toolTip = tooltip
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        return button
    }
    
    // MARK: - Actions
    
    @objc private func newShelfAction() {
        appDelegate?.createNewShelf()
        dismiss(nil)
    }
    
    @objc private func settingsAction() {
        SettingsWindowController.shared.show()
        dismiss(nil)
    }
    
    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    
    private func loadShelves() {
        shelves = ItemStore.shared.fetchAllShelves()
        
        // Clear existing items
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if shelves.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "No recent shelves")
            emptyLabel.textColor = .secondaryLabelColor
            emptyLabel.alignment = .center
            stackView.addArrangedSubview(emptyLabel)
        } else {
            for shelf in shelves.prefix(5) {
                let itemView = createShelfItemView(shelf)
                stackView.addArrangedSubview(itemView)
            }
        }
    }
    
    private func createShelfItemView(_ shelf: Shelf) -> NSView {
        let container = ShelfItemContainer()
        container.wantsLayer = true
        container.shelfId = shelf.id
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Thumbnail stack (horizontal, shows up to 3 items)
        let thumbnailStack = NSStackView()
        thumbnailStack.orientation = .horizontal
        thumbnailStack.spacing = 4
        thumbnailStack.translatesAutoresizingMaskIntoConstraints = false
        
        let items = ItemStore.shared.fetchItems(for: shelf.id)
        let displayItems = items.prefix(3)
        
        for item in displayItems {
            let imageView = NSImageView()
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = 4
            imageView.layer?.masksToBounds = true
            imageView.imageScaling = .scaleProportionallyUpOrDown
            
            if let thumbnailPath = item.thumbnailPath,
               let thumbnailDir = try? FileManager.default.thumbnailsDirectory() {
                let thumbnailURL = thumbnailDir.appendingPathComponent(thumbnailPath)
                imageView.image = NSImage(contentsOf: thumbnailURL)
            } else {
                imageView.image = NSWorkspace.shared.icon(for: .item)
            }
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 40),
                imageView.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            thumbnailStack.addArrangedSubview(imageView)
        }
        
        // Placeholder for empty shelf
        if displayItems.isEmpty {
            let placeholder = NSImageView()
            placeholder.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Empty")
            placeholder.contentTintColor = .secondaryLabelColor
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                placeholder.widthAnchor.constraint(equalToConstant: 40),
                placeholder.heightAnchor.constraint(equalToConstant: 40)
            ])
            thumbnailStack.addArrangedSubview(placeholder)
        }
        
        // Name and count label
        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = NSTextField(labelWithString: shelf.name)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        
        let countLabel = NSTextField(labelWithString: "\(items.count) items")
        countLabel.font = NSFont.systemFont(ofSize: 11)
        countLabel.textColor = .secondaryLabelColor
        
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(countLabel)
        
        container.addSubview(thumbnailStack)
        container.addSubview(textStack)
        
        // Click gesture
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(shelfItemClicked(_:)))
        container.addGestureRecognizer(clickGesture)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 56),
            
            thumbnailStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            thumbnailStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            textStack.leadingAnchor.constraint(equalTo: thumbnailStack.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    @objc private func shelfItemClicked(_ gesture: NSClickGestureRecognizer) {
        guard let container = gesture.view as? ShelfItemContainer,
              let shelfId = container.shelfId else { return }
        
        appDelegate?.openShelf(shelfId)
        dismiss(nil)
    }
}

// Custom view for hover effect
class ShelfItemContainer: NSView {
    var shelfId: UUID?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        ))
    }
    
    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.2).cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = .clear
    }
}
