# WindowCascading

NSWindowController に Cascade windows の機能を簡単に追加できるプロトコルです。これはいくつかのAppKitに存在するバグを回避します。

<img src="./screenshot.jpg" width=1246>


## First Step

以下のコードを NSWindowController のサブクラスにコピペします。

```swift
var windowFrameSavingAllowed: Bool = true
var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
var centerWindowPositionWhenFirstWindowOpening: Bool = true
var windowFrameAutosaveName_alt: String = "Document"

static var previousTopLeft: NSPoint?

func documentController() -> NSDocumentController {
	NSDocumentController.shared
}

func initialWindowSize() -> NSSize? {
	nil
}

```

## Usage

- \- ドキュメントウインドウ (NSWindow) のサブクラスを `DocumentWindowCascading` に準拠させる
- \- NSWindowController のサブクラスを `DocumentWindowControllerWithCascading` に準拠させる
- \- NSWindowController.windowDidLoad() で `setupWindowCascading()` をコールする
- \+ 必要なら `documentController()` を実装する
- \+ 必要なら `initialWindowSize()` を実装する


## Customize

- `windowFrameSavingAllowed: Bool`
	- カスケーディング後のウインドウ座標をUserDefaultsに保存するかを指定します
- `windowFrameAutosaveName_alt: String`
	- AutosaveName を指定します（AppKitのバグが発現するため、"window" の文字列を含めないでください）
- `documentController() -> NSDocumentController`
	- 任意の NSDocumentController を指定します
- `initialWindowSize() -> NSSize`
	- ウインドウの初回表示の際のサイズを指定します
- `discardWindowFrameAutosaveWhenLastWindowClosed: Bool`
	- 最後のウインドウを閉じる際に、保存した Window Frame を削除するかを指定します
- `centerWindowPositionWhenFirstWindowOpening: Bool`
	- 最初のウインドウが開く際に、位置を画面中央に配置するか（Window Frameの座標を復元しない）を指定します

## AppKitのバグについて

AutosaveNameに"window"が含まれていると、カスケーディング処理がおかしくなるようです。

`NSWindowController.windowFrameAutosaveName` を使用すると、ウインドウの位置がずれたりするようです。

この実装では、`NSWindowController.windowFrameAutosaveName` を使わずにカスケーディングとフレーム保存を実現する方針をとります。"NSWindow Frame HOGE" をキーとするUserDefaultsを直接読み書きしてこれに対処します。

参考:

- https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
- https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m

