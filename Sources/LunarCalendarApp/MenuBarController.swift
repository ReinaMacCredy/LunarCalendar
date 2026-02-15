import AppKit
import Observation
import SwiftUI

@MainActor
enum AppContainer {
    static let sharedState = AppState()
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusPopoverController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = StatusPopoverController(model: AppContainer.sharedState)
    }
}

@MainActor
enum SettingsWindowPresenter {
    private static var windowController: NSWindowController?

    static func show(model: AppState) {
        let settingsView = AppSettingsView(model: model)

        if let hosting = windowController?.contentViewController as? NSHostingController<AppSettingsView> {
            hosting.rootView = settingsView
        } else {
            let hosting = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hosting)
            window.title = "Cài đặt"
            window.setContentSize(NSSize(width: 620, height: 480))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            windowController = NSWindowController(window: window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}

@MainActor
final class StatusPopoverController: NSObject {
    private let model: AppState
    private let popover = NSPopover()
    private let statusItem: NSStatusItem
    private let hostingController: NSHostingController<CalendarPopoverView>
    private let statusMenu = NSMenu()

    init(model: AppState) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        hostingController = NSHostingController(rootView: CalendarPopoverView(model: model))
        super.init()

        configurePopover()
        configureStatusItem()
        trackMenuBarTitle()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 536, height: 660)
        popover.contentViewController = hostingController
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.action = #selector(handleStatusItemClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        button.title = model.menuBarTitle

        let settingsItem = NSMenuItem(title: "Cài đặt", action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        statusMenu.addItem(settingsItem)
        statusMenu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Thoát LunarCalendar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    @objc
    private func handleStatusItemClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showStatusMenu()
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showStatusMenu() {
        if popover.isShown {
            popover.performClose(nil)
        }
        guard let button = statusItem.button else {
            return
        }
        statusItem.menu = statusMenu
        button.performClick(nil)
        statusItem.menu = nil
    }

    @objc
    private func openSettingsWindow() {
        SettingsWindowPresenter.show(model: model)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func trackMenuBarTitle() {
        withObservationTracking {
            _ = model.menuBarTitle
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateMenuBarTitle()
                self?.trackMenuBarTitle()
            }
        }

        updateMenuBarTitle()
    }

    private func updateMenuBarTitle() {
        statusItem.button?.title = model.menuBarTitle
    }
}
