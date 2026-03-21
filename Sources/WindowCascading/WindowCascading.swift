#if os(macOS)
import Cocoa

public protocol CascadableWindow: NSWindow {}

public protocol WindowControllerWithCascading: NSWindowController {
	
	/// If true then, save the window frame to UserDefaults. (true is recommended)
	var usesPersistentCascadableWindowFrame: Bool { get }
	/// If true then, discard the last window frame info from the UserDefaults when all managed windows are closed. (false is recommended)
	var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool { get }
	/// If true then, auto reset the window frame when run the NSWindowRestoration by the system. (true is recommended)
	var resetsFrameWhenCascadableWindowRestored: Bool { get }
	/// If true then, set the first window position to center of the screen.
	var centerCascadableWindowPositionWhenFirstOpening: Bool { get }
	
	/// Alternative AutosaveName (do not include the word "window" because to work around a bug in AppKit)
	var cascadableWindowFrameAutosaveName: String { get }
	
	static var previousTopLeft: NSPoint? { get set }
	
	/// Tokens for notification observers (used for proper unregistration)
	var cascadingObserverTokens: [NSObjectProtocol] { get set }
	
	/// Return your managing/loaded windows
	func targetCascadableWindows() -> [CascadableWindow]
	
	/// Returns the initial window size
	func defaultCascadableWindowSize() -> NSSize?
	
	/*
	 ## Paste the following code into your WindowController implementation or subclassing from CascadableNSWindowController:
	 
	 import WindowCascading
	 
	 var usesPersistentCascadableWindowFrame: Bool {
		true
	 }
	 var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	 }
	 var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	 }
	 var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	 }
	 var cascadableWindowFrameAutosaveName: String {
		"DocumentWindow"
	 }
	 
	 static var previousTopLeft: NSPoint?
	 var cascadingObserverTokens = [NSObjectProtocol]()

	 func targetCascadableWindows() -> [CascadableWindow] {
		 // You must manage target windows
		 // This line is valid if you are using the NSDocument-based window architecture
		 NSDocumentController.shared.cascadableWindows()
	 }
	 
	 func defaultCascadableWindowSize() -> NSSize? {
		// Return the default window size if necessary
		nil
	 }
	 
	 override func windowDidLoad() {
		super.windowDidLoad()
	 
		// Setup window cascading (for NSWindowRestoration)
		prepareForWindowRestoring()
	 }
	 
	 override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
	 
		// Setup window cascading
		setupWindowCascading()
	 }
	 
	 ------------------------------------------------------
	 
	 ## Usage:
	 - Make your subclass of NSWindow to conform to `CascadableWindow` protocol.
	 - Make your subclass of NSWindowController to conform to `WindowControllerWithCascading` protocol or subclassing it from `CascadableNSWindowController`.
	 - Implement `targetCascadableWindows()` in your WindowController.
	 - Call `prepareForWindowRestoring()` method in `windowDidLoad()` of your WindowController implementation.
	 - Call `setupWindowCascading()` method in `showWindow(_:)` of your WindowController implementation.
	 + Implement `defaultCascadableWindowSize()` in your WindowController if necessary.
	 	 
	 
	 ## Note 1:
	 It seems that calling `self.shouldCascadeWindows = true` with windowDidLoad() is too late:
	 https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191
	 
	 However, this is true by default, so there is no need to mention it if you are cascading.
	 
	 
	 ## Note 2:
	 - It seems that cascading does not work properly when "window" is included in AutosaveName text. Probably a bug in AppKit.
	 - To begin with, it seems that using NSWindowController.windowFrameAutosaveName causes the window to be out of position?
	 
	 So, based on the reference information, I decided to adopt a policy to achieve cascading and frame saving without using NSWindowController.windowFrameAutosaveName.
	 This is handled by directly reading and writing UserDefaults with "NSWindow Frame FOOBAR" as the key.
	 
	 */
}

public extension CascadableWindow {
	
	/// Get window’s top-left coordinate
	var topLeft: NSPoint {
		NSPoint(x: frame.minX, y: frame.maxY)
	}
	
	func frame(with topLeft: NSPoint, size: NSSize) -> NSRect {
		NSRect(x: topLeft.x,
			   y: topLeft.y - size.height,
			   width: size.width,
			   height: size.height)
	}
	
	/// Window cascading method with modified logic
	func cascade(from topLeftPoint: NSPoint) -> NSPoint {
		validatedTopLeft(cascadeTopLeft(from: topLeftPoint), resetsToLeadingEdge: true)
	}
	
	/// Validate and adjust the top-left point so that the window fits within the visible screen area.
	/// - Parameter resetsToLeadingEdge: If true, resets X to the leading edge of the screen (with offset) when the window exceeds the trailing edge. This is used for cascading wrap-around behavior.
	internal func validatedTopLeft(_ topLeftPoint: NSPoint, resetsToLeadingEdge: Bool) -> NSPoint {
		let windowFrame = frame
		
		// Tentatively calculated top-left coordinates and window frame
		let tempFrame = frame(with: topLeftPoint, size: windowFrame.size)
		
		guard let screenFrame = screen?.visibleFrame
		else { return topLeftPoint }
		
		if screenFrame.contains(tempFrame) && tempFrame.width != screenFrame.width {
			return topLeftPoint
		}
		
		var newTopLeft = topLeftPoint
		
		// If window extends beyond bottom of screen, set Y to top of the screen
		if tempFrame.minY < screenFrame.minY {
			newTopLeft.y = screenFrame.maxY
		}
		
		// If window extends beyond left of screen, set X to minX of the screen frame
		if tempFrame.minX < screenFrame.minX {
			newTopLeft.x = screenFrame.minX
		}
		
		// If window extends beyond right of screen
		if tempFrame.maxX > screenFrame.maxX {
			if resetsToLeadingEdge {
				// Reset X toward the leading edge with the overflow as offset (cascade wrap-around)
				let diff = tempFrame.maxX - screenFrame.maxX
				newTopLeft.x = screenFrame.minX + diff
			}
			else {
				// Fit the window to the trailing edge
				newTopLeft.x = screenFrame.maxX - windowFrame.size.width
			}
		}
		
		// Snap the window origin to the screen edge when the window spans the full screen dimension
		if tempFrame.width == screenFrame.width {
			// Window fills the screen horizontally — align its left edge to the screen's leading edge
			newTopLeft.x = screenFrame.minX
		}
		else if tempFrame.height == screenFrame.height {
			// Window fills the screen vertically — align its top edge to the screen's top edge
			newTopLeft.y = screenFrame.maxY
		}
		
		return newTopLeft
	}
	
}

public extension WindowControllerWithCascading {
	
	/// Start point for NSWindowRestoration, call this in NSWindowController.windowDidLoad() after super's called.
	func prepareForWindowRestoring() {
		if resetsFrameWhenCascadableWindowRestored {
			// When restoring a window does not call showWindow(_:) and makeKeyAndOrderFront(_:) by the system. Instead, it detects with `NSApplication.didFinishRestoringWindowsNotification` notification.
			// This observer is stored in cascadingObserverTokens and will be cleaned up either:
			// - When the notification fires and setupObserversForCascading() is called (which clears all tokens first), or
			// - When showWindow() calls setupObserversForCascading() in the normal (non-restoration) flow.
			let token = NotificationCenter.default.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification, object: NSApp, queue: .main) { [weak self] notif in
				guard let self else { return }
				self.setupObserversForCascading()
				self.resetCascadableWindowFrame()
			}
			cascadingObserverTokens.append(token)
		}
	}
	
	/// Start point for standard window displaying, call this in NSWindowController.showWindow() after super’s called.
	func setupWindowCascading() {
		setupObserversForCascading()
		resetCascadableWindowFrame()
	}
	
	
	// MARK: -
	
	var cascadableWindow: CascadableWindow? {
		window as? CascadableWindow
	}
	
	
	// MARK: - Autosave
	
	private func cascadableWindowFrameAutosaveName_() -> String {
		// Not certain if this process is effective.
		cascadableWindowFrameAutosaveName.replacingOccurrences(of: "window", with: "w.i.n.d.o.w", options: .caseInsensitive)
	}
	
	/// Raw key string for `windowFrameAutosaveName`
	var persistentWindowFrameInfoKey: String {
		"NSWindow Frame \(cascadableWindowFrameAutosaveName_())"
	}
	
	/// Restore the saved window frame in string format
	func persistableWindowFrameDescriptor() -> NSWindow.PersistableFrameDescriptor? {
		// Ref: https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
		UserDefaults.standard.string(forKey: persistentWindowFrameInfoKey)
	}
	
	func clearPersistentWindowFrameInfo() {
		UserDefaults.standard.removeObject(forKey: persistentWindowFrameInfoKey)
	}
	
	func saveWindowFrame() {
		guard isWindowLoaded,
			  let cascadableWindow
		else { return }
		cascadableWindow.saveFrame(usingName: cascadableWindowFrameAutosaveName_())
	}
	
	
	// MARK: -
	
	/// Set window frame
	func resetCascadableWindowFrame() {
		// Cascading and frame saving without NSWindowController.windowFrameAutosaveName
		// Ref: https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
		
		guard let cascadableWindow,
			  let screen = cascadableWindow.screen
		else { return }
		
		if targetCascadableWindows().count == 1 {
			// [First window]
			
			if let windowFrameDesc = persistableWindowFrameDescriptor() {
				// Restore window frame if auto saved
				cascadableWindow.setFrame(from: windowFrameDesc)
				
				if centerCascadableWindowPositionWhenFirstOpening {
					cascadableWindow.center()
				}
				else {
					let topLeft = cascadableWindow.validatedTopLeft(cascadableWindow.topLeft, resetsToLeadingEdge: false)
					cascadableWindow.setFrameTopLeftPoint(topLeft)
				}
			}
			else {
				// Set initial window size and centering
				let defaultCascadableWindowSize = defaultCascadableWindowSize() ?? _defaultCascadableWindowSize(screen)
				cascadableWindow.setContentSize(defaultCascadableWindowSize)
				cascadableWindow.center()
			}
			
			Self.previousTopLeft = cascadableWindow.topLeft
		}
		else {
			// [Other windows]
			
			// Restore window frame
			cascadableWindow.setFrameUsingName(cascadableWindowFrameAutosaveName_())
			
			// Cascade and set position
			let topLeft = cascadableWindow.topLeft
			let nextTopLeft = cascadableWindow.cascade(from: Self.previousTopLeft ?? topLeft)
			
			cascadableWindow.setFrameTopLeftPoint(nextTopLeft)
			
			Self.previousTopLeft = nextTopLeft
		}
	}
	
	/// Setup event triggers
	func setupObserversForCascading() {
		removeObserversForCascading()

		func observe(_ name: Notification.Name, handler: @escaping (_ notification: Notification) -> Void) {
			let token = NotificationCenter.default.addObserver(forName: name,
															   object: cascadableWindow,
															   queue: .main,
															   using: handler)
			cascadingObserverTokens.append(token)
		}

		observe(NSWindow.didBecomeMainNotification) { [weak self] notification in
			guard let self,
				  self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }

			self.saveWindowFrame()
		}

		observe(NSWindow.didBecomeKeyNotification) { [weak self] notification in
			guard let self,
				  self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }

			Self.previousTopLeft = window.topLeft
		}

		observe(NSWindow.didResizeNotification) { [weak self] notification in
			guard let self,
				  self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }

			self.saveWindowFrame()
			Self.previousTopLeft = window.topLeft
		}

		observe(NSWindow.didMoveNotification) { [weak self] notification in
			guard let self,
				  self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  window.isKeyWindow,
				  self.usesPersistentCascadableWindowFrame else
			{ return }

			self.saveWindowFrame()

			if window.isMainWindow {
				Self.previousTopLeft = window.topLeft
			}
		}

		observe(NSWindow.willCloseNotification) { [weak self] notification in
			guard let self else { return }
			// Discard window size cache if target window count would be zero
			if let window = self.cascadableWindow, (notification.object as? CascadableWindow) === window {
				if self.discardsPersistentCascadableWindowFrameWhenLastClosed && self.targetCascadableWindows().count == 1 {
					Self.previousTopLeft = window.topLeft
					self.clearPersistentWindowFrameInfo()
				}
				self.removeObserversForCascading()
			}
		}
	}
	
	/// Remove event triggers
	func removeObserversForCascading() {
		for token in cascadingObserverTokens {
			NotificationCenter.default.removeObserver(token)
		}
		cascadingObserverTokens.removeAll()
	}
	
	/// Default imp of `defaultCascadableWindowSize()`
	private func _defaultCascadableWindowSize(_ screen: NSScreen) -> NSSize {
		let screenSize = screen.visibleFrame.size
		let size = NSSize(width: CGFloat(Int(screenSize.width * 0.75)),
						  height: CGFloat(Int(screenSize.height * 0.75)))
		return size
	}
	
}

public extension NSDocumentController {
	
	/// Get the array of cascadable windows if you are using the NSDocument-based window architecture
	func cascadableWindows() -> [CascadableWindow] {
		documents.compactMap { doc in
			doc.windowControllers.compactMap { wc in
				wc.window as? CascadableWindow
			}
		}.flatMap { $0 }
	}
	
}

#endif
