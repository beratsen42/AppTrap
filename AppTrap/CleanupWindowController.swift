import AppKit

final class CleanupWindowController: NSWindowController {
    private let trashedApp: TrashedApp
    private let allFiles: [URL]
    private var selectedFiles: Set<URL>
    private var tableView: NSTableView!
    private var selectAllButton: NSButton!

    var onDismiss: (() -> Void)?

    // MARK: - Init

    init(app: TrashedApp, files: [URL]) {
        self.trashedApp = app
        self.allFiles = files
        self.selectedFiles = Set(files)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "AppClaw"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()

        super.init(window: panel)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI Construction

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let icon = makeIcon()
        let titleLabel = makeLabel("\(trashedApp.name) was moved to Trash.", bold: true, size: 14)
        let subtitleLabel = makeWrappingLabel("The following related files were found. Move them to Trash as well?")

        selectAllButton = NSButton(checkboxWithTitle: "Select All", target: self, action: #selector(selectAllToggled))
        selectAllButton.translatesAutoresizingMaskIntoConstraints = false
        selectAllButton.state = .on

        let scroll = makeScrollableTable()
        let keepBtn = makeButton("Keep", key: "\u{1B}", action: #selector(keepPressed))
        let moveBtn = makeButton("Move to Trash", key: "\r", action: #selector(movePressed))

        let subviews: [NSView] = [icon, titleLabel, subtitleLabel, selectAllButton, scroll, keepBtn, moveBtn]
        for v in subviews {
            content.addSubview(v)
        }

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            icon.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            selectAllButton.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            selectAllButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            scroll.topAnchor.constraint(equalTo: selectAllButton.bottomAnchor, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scroll.bottomAnchor.constraint(equalTo: keepBtn.topAnchor, constant: -16),

            keepBtn.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            keepBtn.trailingAnchor.constraint(equalTo: moveBtn.leadingAnchor, constant: -8),
            keepBtn.widthAnchor.constraint(equalToConstant: 80),

            moveBtn.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            moveBtn.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            moveBtn.widthAnchor.constraint(equalToConstant: 130),
        ])
    }

    private func makeIcon() -> NSImageView {
        let view = NSImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = NSWorkspace.shared.icon(forFile: trashedApp.path.path)
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }

    private func makeLabel(_ text: String, bold: Bool, size: CGFloat) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.translatesAutoresizingMaskIntoConstraints = false
        f.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        return f
    }

    private func makeWrappingLabel(_ text: String) -> NSTextField {
        let f = NSTextField(wrappingLabelWithString: text)
        f.translatesAutoresizingMaskIntoConstraints = false
        f.font = .systemFont(ofSize: 12)
        f.textColor = .secondaryLabelColor
        return f
    }

    private func makeScrollableTable() -> NSScrollView {
        tableView = NSTableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.rowHeight = 22
        tableView.usesAlternatingRowBackgroundColors = true

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("file"))
        col.resizingMask = .autoresizingMask
        tableView.addTableColumn(col)

        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = tableView
        tableView.sizeLastColumnToFit()
        return scroll
    }

    private func makeButton(_ title: String, key: String, action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.bezelStyle = .rounded
        b.keyEquivalent = key
        return b
    }

    // MARK: - Actions

    @objc private func selectAllToggled() {
        selectedFiles = selectAllButton.state == .on ? Set(allFiles) : []
        tableView.reloadData()
    }

    @objc private func keepPressed() {
        dismiss()
    }

    @objc private func movePressed() {
        let toTrash = allFiles.filter { selectedFiles.contains($0) }
        if !toTrash.isEmpty {
            NSWorkspace.shared.recycle(toTrash, completionHandler: nil)
        }
        dismiss()
    }

    private func dismiss() {
        close()
        onDismiss?()
    }

    // MARK: - Show

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }

    // MARK: - Helpers

    private func displayPath(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let path = url.path
        return path.hasPrefix(home) ? "~" + path.dropFirst(home.count) : path
    }

    private func syncSelectAllState() {
        if selectedFiles.isEmpty {
            selectAllButton.state = .off
        } else if selectedFiles.count == allFiles.count {
            selectAllButton.state = .on
        } else {
            selectAllButton.allowsMixedState = true
            selectAllButton.state = .mixed
        }
    }
}

// MARK: - NSTableViewDataSource

extension CleanupWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int { allFiles.count }
}

// MARK: - NSTableViewDelegate

extension CleanupWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let file = allFiles[row]
        let id = NSUserInterfaceItemIdentifier("cell")
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSButton ?? {
            let b = NSButton()
            b.setButtonType(.switch)
            b.identifier = id
            b.target = self
            b.action = #selector(cellCheckboxToggled(_:))
            b.lineBreakMode = .byTruncatingMiddle
            return b
        }()
        cell.title = displayPath(file)
        cell.tag = row
        cell.state = selectedFiles.contains(file) ? .on : .off
        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat { 22 }

    @objc private func cellCheckboxToggled(_ sender: NSButton) {
        let file = allFiles[sender.tag]
        if sender.state == .on {
            selectedFiles.insert(file)
        } else {
            selectedFiles.remove(file)
        }
        syncSelectAllState()
    }
}
