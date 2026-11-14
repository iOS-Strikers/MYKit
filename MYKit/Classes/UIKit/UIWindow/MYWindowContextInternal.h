#import <UIKit/UIKit.h>

// UIKit callers must run on the main thread. Ambiguous foreground scenes have no
// process-wide current window; callers with a view should use that view's window.
static inline UIWindow *MYWindowForApplication(NSSet<UIScene *> *scenes, id<UIApplicationDelegate> delegate) {
    UIWindow *candidate = nil;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (!window.isKeyWindow || window.hidden || window.alpha <= 0 || window.windowLevel != UIWindowLevelNormal) continue;
            if (candidate && candidate != window) return nil;
            candidate = window;
        }
    }
    if (scenes.count == 0 && [delegate respondsToSelector:@selector(window)]) return delegate.window;
    return candidate;
}

static inline UIWindow *MYCurrentApplicationWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    return MYWindowForApplication(application.connectedScenes, application.delegate);
}
