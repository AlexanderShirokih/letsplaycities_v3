import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ru.aleshi.letsplaycities/share",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak controller] call, result in
        guard let controller = controller else {
          result(nil)
          return
        }
        let args = call.arguments as? [String: Any]
        var items: [Any] = []

        switch call.method {
        case "share_text":
          if let text = args?["text"] as? String { items.append(text) }
        case "share_image":
          // The picture goes first, so apps that take one item get the image
          if let path = args?["path"] as? String,
             let image = UIImage(contentsOfFile: path) {
            items.append(image)
          }
          if let text = args?["text"] as? String { items.append(text) }
        default:
          result(FlutterMethodNotImplemented)
          return
        }

        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // iPad shows the sheet as a popover, which needs an anchor
        sheet.popoverPresentationController?.sourceView = controller.view
        sheet.popoverPresentationController?.sourceRect = CGRect(
          x: controller.view.bounds.midX,
          y: controller.view.bounds.midY,
          width: 0,
          height: 0
        )
        controller.present(sheet, animated: true)
        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
