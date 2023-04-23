#if os(macOS)
import Cocoa

public protocol DocumentWindowCascading: NSWindow {}

public protocol DocumentWindowControllerWithCascading: NSWindowController {
	
	/// Window Frameの自動保存の有効化/無効化
	public var windowFrameSavingAllowed: Bool {get set}
	/// 最後のウインドウを閉じる際に、保存した Window Frame を削除するか
	public var discardWindowFrameAutosaveWhenLastWindowClosed: Bool {get set}
	/// 最初のウインドウが開く際に、位置を画面中央に配置するか（Window Frameの座標を復元しない）
	public var centerWindowPositionWhenFirstWindowOpening: Bool {get set}
	/// Autosave Name
	public var windowFrameAutosaveName_alt: String {get}
	
	open static var previousTopLeft: NSPoint? {get set}
	
	/// DocumentControllerを返す
	public func documentController() -> NSDocumentController
	
	/// 初回ウインドウサイズを設定する
	public func initialWindowSize() -> NSSize?
	
	/*
	 ## WindowController の実装に以下をコピペするか、カスタマイズする:
	 
	 var windowFrameSavingAllowed: Bool = true
	 var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
	 var centerWindowPositionWhenFirstWindowOpening: Bool = true
	 var windowFrameAutosaveName_alt: String = "Document"
	 
	 static var previousTopLeft: NSPoint?
	 
	 func documentController() -> NSDocumentController {
		NSDocumentController.shared
	 }
	 
	 
	 ## 使い方:
	 - ドキュメントウインドウ (NSWindow) のサブクラスを `DocumentWindowCascading` に準拠させる
	 - NSWindowController のサブクラスを `DocumentWindowControllerWithCascading` に準拠させる
	 - windowDidLoad() で `setupWindowCascading()` をコールする
	 + 必要なら `documentController()` を実装する
	 + 必要なら `initialWindowSize()` を実装する
	 
	 
	 ## Note 1:
	 `self.shouldCascadeWindows = true` は windowDidLoad() でコールするのでは遅すぎるらしい：
	 https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191#43726191
	 
	 ただしデフォルトで true なので、カスケーディングするならば特に触れなくても良い。
	 
	 
	 ## Note 2:
	 - AutosaveName に "window" を含めていると、カスケーディングがおかしくなるらしい
	 - そもそも NSWindowController.windowFrameAutosaveName を使うとウインドウの位置がずれるっぽい？
	 
	 NSWindowController.windowFrameAutosaveName を使わずにカスケーディングとフレーム保存を実現する方針をとる。
	 "NSWindow Frame HOGE" をキーとするUserDefaultsを直接読み書きして対処する。
	 
	 */
}

public extension DocumentWindowControllerWithCascading {
	
	func setupWindowCascading() {
		setObserversForCascading()
		resetWindowFrame()
		self.windowFrameSavingAllowed = true
	}
	
	private var persistentWindowFrameInfoKey: String {
		"NSWindow Frame \(self.windowFrameAutosaveName_alt)"
	}
	
	private func _initialWindowSize(_ screen: NSScreen) -> NSSize {
		let screenSize = screen.visibleFrame.size
		let size = NSSize(width: CGFloat(Int(screenSize.width * 0.75)),
						  height: CGFloat(Int(screenSize.height * 0.75)))
		return size
	}
	
	/// 保存した Window Frame を文字列形式で復元
	private func persistableWindowFrameDescriptor() -> NSWindow.PersistableFrameDescriptor? {
		// 参考：https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
		UserDefaults.standard.string(forKey: self.persistentWindowFrameInfoKey)
	}
	
	func clearPersistentWindowFrameInfo() {
		UserDefaults.standard.removeObject(forKey: self.persistentWindowFrameInfoKey)
	}
	
	func documentController() -> NSDocumentController {
		NSDocumentController.shared
	}
	
	var documentWindowCascading: DocumentWindowCascading? {
		self.window as? DocumentWindowCascading
	}
	
	func resetWindowFrame() {
		// NSWindowController.windowFrameAutosaveName を使わずにカスケーディングとフレーム保存を実現する
		// 参考：https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
		
		if let window = self.documentWindowCascading,
		   let screen = window.screen {
			if documentController().allDocumentWindowCascading().count == 0 {
				// [1つ目のウインドウ]
				
				if let windowFrameDesc = persistableWindowFrameDescriptor() {
					// 保存済みフレームがあればそれを復元し、画面中央に表示
					window.setFrame(from: windowFrameDesc)
					
					if self.centerWindowPositionWhenFirstWindowOpening {
						window.center()
					}
				}
				else {
					// ウインドウの初期サイズを設定し、画面中央に表示
					let initialWindowSize = initialWindowSize() ?? _initialWindowSize(screen)
					window.setContentSize(initialWindowSize)
					window.center()
				}
				
				Self.previousTopLeft = window.topLeft
			}
			else {
				// [2つ目以降のウインドウ]
				
				// 保存済みフレームがあればそれを復元
				window.setFrameUsingName(self.windowFrameAutosaveName_alt)
				
				// カスケードした位置を設定
				let topLeft = window.topLeft
				let nextTopLeft = window.cascadeTopLeft(from: Self.previousTopLeft ?? topLeft)
				
				if nextTopLeft.equalTo(topLeft) {
					window.setFrameTopLeftPoint(nextTopLeft)
				}
				else {
					window.setFrameTopLeftPoint(nextTopLeft)
				}
				
				Self.previousTopLeft = nextTopLeft
			}
		}
	}
	
	func removeObserversForCascading() {
		func removeObserver(_ name: NSNotification.Name) {
			NotificationCenter.default.removeObserver(self,
													  name: name,
													  object: self.documentWindowCascading)
		}
		
		removeObserver(NSWindow.didBecomeMainNotification)
		removeObserver(NSWindow.didBecomeKeyNotification)
		removeObserver(NSWindow.didResizeNotification)
		removeObserver(NSWindow.didMoveNotification)
		removeObserver(NSWindow.willCloseNotification)
	}
	
	func setObserversForCascading() {
		removeObserversForCascading()
		
		func observe(_ name: Notification.Name, handler: @escaping (_ notification: Notification) -> Void) {
			NotificationCenter.default.addObserver(forName: name,
												   object: self.documentWindowCascading,
												   queue: .main,
												   using: handler)
		}
		
		observe(NSWindow.didBecomeMainNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
		}
		
		observe(NSWindow.didBecomeKeyNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didResizeNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didMoveNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  window.isKeyWindow,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
			
			if window.isMainWindow {
				Self.previousTopLeft = window.topLeft
			}
		}
		
		observe(NSWindow.willCloseNotification) { notification in
			// 最後のウインドウが閉じる際に、保存したウインドウフレームを削除する
			if self.discardWindowFrameAutosaveWhenLastWindowClosed,
			   (notification.object as? DocumentWindowCascading) === self.documentWindowCascading,
			   self.documentController().allDocumentWindowCascading().count == 1 {
				NSWindow.removeFrame(usingName: self.windowFrameAutosaveName_alt)
			}
		}
	}
	
}

open extension DocumentWindowCascading {
	
	var topLeft: NSPoint {
		NSPoint(x: frame.minX, y: frame.maxY)
	}
	
}

open extension NSDocumentController {
	
	func allDocumentWindowCascading() -> [DocumentWindowCascading] {
		self.documents.map {
			$0.windowControllers.map { wc in
				wc.window as? DocumentWindowCascading
			}
		}.flatMap { $0 }.compactMap { $0 }
	}
	
}

#endif
