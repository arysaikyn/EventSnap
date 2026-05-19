import UIKit

/// ShareExtension principal class required by NSExtensionPointIdentifier.
/// Receives shared content before SwiftUI app launches.
@objc(ShareExtensionViewController)
final class ShareExtensionViewController: UIViewController {
    /// Called when the extension is activated via the share sheet.
    @objc func viewDidLoad() {
        super.viewDidLoad()
        // SwiftUI App handles the rest via @main EventSnapShareExtensionApp
    }
}