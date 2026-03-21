#if os(macOS)
import Cocoa

open class CascadableNSWindow: NSWindow, CascadableWindow {}

open class CascadableNSWindowController: NSWindowController, WindowControllerWithCascading {
	
	/* ================== WindowControllerWithCascading >> ================== */
	
	open var usesPersistentCascadableWindowFrame: Bool {
		true
	}
	open var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	}
	open var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	}
	open var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	}
	open var cascadableWindowFrameAutosaveName: String {
		"DocumentWindow"
	}
	
	public static var previousTopLeft: NSPoint?
	public var cascadingObserverTokens = [NSObjectProtocol]()
	
	open func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows on subclass
		[]
	}
	
	open func defaultCascadableWindowSize() -> NSSize? {
		if let screen = window?.screen {
			let scale = 0.3
			let screenSize = screen.visibleFrame.size
			let size = NSSize(width: CGFloat(Int(screenSize.width * scale)),
							  height: CGFloat(Int(screenSize.height * scale)))
			
			return size
		}
		return nil
	}
	
	/* ================== << WindowControllerWithCascading ================== */

	/// Tracks whether prepareForWindowRestoring() has been called, to avoid duplicate invocation
	/// when both windowDidLoad() and showWindow(_:) are triggered.
	private var didPrepareForWindowRestoring = false

	deinit {
		removeObserversForCascading()
	}

	open override func windowDidLoad() {
		super.windowDidLoad()

		// WindowControllerWithCascading: Setup window cascading (for NSWindowRestoration)
		prepareForWindowRestoring()
		didPrepareForWindowRestoring = true
	}

	open override func showWindow(_ sender: Any?) {
		// When initialized with init(window:), windowDidLoad() is not called.
		// Ensure prepareForWindowRestoring() runs before the window is shown.
		if !didPrepareForWindowRestoring {
			prepareForWindowRestoring()
			didPrepareForWindowRestoring = true
		}

		super.showWindow(sender)

		// WindowControllerWithCascading: Setup window cascading
		setupWindowCascading()
	}

}

#endif
