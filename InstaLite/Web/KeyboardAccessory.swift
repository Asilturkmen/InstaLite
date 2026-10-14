import ObjectiveC
import UIKit
import WebKit

extension WKWebView {
    /// Klavyenin üstündeki web'e özgü "önceki / sonraki / bitti" çubuğunu kaldırır.
    /// WebKit bunun için API sunmuyor; içerik görünümünün sınıfı, `inputAccessoryView`'ı nil
    /// dönen bir alt sınıfla değiştirilir.
    func removeInputAccessoryView() {
        guard let contentView = scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }), let baseClass = object_getClass(contentView) else { return }

        let name = "\(NSStringFromClass(baseClass))_InstaLiteNoAccessory"
        var subclass: AnyClass? = NSClassFromString(name)
        if subclass == nil, let newClass = objc_allocateClassPair(baseClass, name, 0) {
            let selector = #selector(getter: UIResponder.inputAccessoryView)
            let noAccessory: @convention(block) (AnyObject) -> UIView? = { _ in nil }
            if let method = class_getInstanceMethod(UIResponder.self, selector) {
                class_addMethod(newClass, selector, imp_implementationWithBlock(noAccessory), method_getTypeEncoding(method))
            }
            objc_registerClassPair(newClass)
            subclass = newClass
        }
        if let subclass {
            object_setClass(contentView, subclass)
        }
    }
}
