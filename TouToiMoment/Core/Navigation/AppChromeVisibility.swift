import Foundation

enum AppChromeVisibility {
    static func shouldShowBottomTabBar(
        navigationHidesBottomTabBar: Bool,
        isKeyboardVisible: Bool
    ) -> Bool {
        !navigationHidesBottomTabBar && !isKeyboardVisible
    }
}
