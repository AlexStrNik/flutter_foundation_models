import Flutter
import UIKit

public class FlutterFoundationModelsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        LanguageModelSessionApi.register(with: registrar)
    }
}
