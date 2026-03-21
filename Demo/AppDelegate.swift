import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// After window restoration completes, ensure at least one document is open.
		// This notification fires after all restorable windows have been restored.
		NotificationCenter.default.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification,
											   object: NSApp,
											   queue: .main) { [weak self] _ in
			self?.openUntitledDocumentIfNeeded()
		}
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

	/// Opens a new untitled document if no documents are currently open.
	private func openUntitledDocumentIfNeeded() {
		let documentController = NSDocumentController.shared
		guard documentController.documents.isEmpty else { return }

		let _ = try? documentController.openUntitledDocumentAndDisplay(true)
	}

}

