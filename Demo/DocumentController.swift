import Cocoa

class DocumentController: NSDocumentController {
	
	func allDocumentWindowControllers() -> [DocumentWindowController] {
		documents.map {
			$0.windowControllers.filter {
				$0 is DocumentWindowController
			} as? [DocumentWindowController]
		}.compactMap{ $0 }.flatMap { $0 }
	}
	
	func allDocumentWindows() -> [DocumentWindow] {
		allDocumentWindowControllers().map {
			$0.window as? DocumentWindow
		}.compactMap { $0 }
	}
	
}
