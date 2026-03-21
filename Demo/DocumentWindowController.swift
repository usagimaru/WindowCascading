import Cocoa
import WindowCascading

class DocumentWindowController: CascadableNSWindowController {
	
	static func new() -> DocumentWindowController {
		let window = CascadableNSWindow(contentRect: .init(x: 0, y: 300, width: 400, height: 500),
										styleMask: [.titled, .closable, .miniaturizable, .resizable],
										backing: .buffered,
										defer: false)
		window.isRestorable = true
		// window.isReleasedWhenClosed = true // Do not use this with NSDocument architecture
		
		let textField = NSTextField(string: "Do \"New\" action or press \"Command N\"")
		textField.textColor = .secondaryLabelColor
		textField.isEditable = false
		textField.isSelectable = false
		textField.isBezeled = false
		textField.drawsBackground = false
		textField.alignment = .center
		textField.translatesAutoresizingMaskIntoConstraints = false
		
		let contentView = NSView()
		contentView.addSubview(textField)
		
		NSLayoutConstraint.activate([
			textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
			textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
		])

		window.contentView = contentView
		
		return DocumentWindowController(window: window)
	}
	
	/* ================== WindowControllerWithCascading >> ================== */
	
	override var usesPersistentCascadableWindowFrame: Bool {
		true
	}
	override var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	}
	override var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	}
	override var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	}
	override var cascadableWindowFrameAutosaveName: String {
		"DocumentWindow"
	}
	
	override func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows
		// This line is valid if you are using the NSDocument-based window architecture
		NSDocumentController.shared.cascadableWindows()
	}
	
	/* ================== << WindowControllerWithCascading ================== */

}
