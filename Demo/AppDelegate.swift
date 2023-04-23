import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
	
	private(set) var documentController: DocumentController!
	
	class var shared: AppDelegate {
		NSApp.delegate as! AppDelegate
	}
	
	class var sharedDocumentController: DocumentController {
		AppDelegate.shared.documentController
	}
	
	func applicationWillFinishLaunching(_ notification: Notification) {
		self.documentController = DocumentController()
	}

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

}

