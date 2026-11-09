//
//  PermissionPromptPresenter.swift
//  Reynard
//
//  Created by Minh Ton on 18/6/26.
//

import GeckoView
import UIKit

struct PermissionPromptPresenter: PermissionPromptPresenting {
    @MainActor
    func request(
        title: String,
        message: String?,
        cancelTitle: String,
        for session: GeckoSession
    ) async -> Bool {
        guard let presenter = await findPresenter() else {
            return false
        }

        return await withCheckedContinuation { continuation in
            var allowed = false
            let alert = PromptAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.onDismissed = {
                continuation.resume(returning: allowed)
            }
            alert.setValue(
                NSAttributedString(
                    string: title,
                    attributes: [.font: UIFont.boldSystemFont(ofSize: 17)]
                ),
                forKey: "attributedTitle"
            )
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Allow", comment: ""), style: .default) { _ in
                allowed = true
            })
            presenter.present(alert, animated: true)
        }
    }

    // Claude: find a view controller that can actually present the
    // permission alert. The old code returned "deny" immediately when
    // topViewController() was nil, so a mic/camera request arriving while
    // the app was still launching (or mid-transition, with no
    // foreground-active scene yet) was silently recorded as "blocked" and
    // the user never saw a prompt — e.g. a site ending up in the
    // denied list despite the default being "Ask" (this happened to
    // chatgpt.com at 09:17 on 2026-11-08 in the ChatGPT build).
    // Wait briefly for the scene to become foreground-active, then fall
    // back to any window scene's root view controller. Only deny as a
    // last resort when no presenter attached to a window exists at all
    // (presenting on one without a window would show nothing and the
    // continuation below would never resume).
    @MainActor
    private func findPresenter() async -> UIViewController? {
        // 1. Fast path: a foreground-active scene is already up.
        if let presenter = UIApplication.shared.topViewController(), presenter.view.window != nil {
            return presenter
        }
        // 2. The request may have arrived during launch or a transition:
        // give the scene up to ~3s to become foreground-active.
        for _ in 0..<12 {
            if Task.isCancelled {
                return nil
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            if let presenter = UIApplication.shared.topViewController(), presenter.view.window != nil {
                return presenter
            }
        }
        // 3. Last resort: any window scene, even one not foreground-active yet.
        if let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        {
            let fallback = UIApplication.shared.topViewController(from: rootViewController)
            if fallback.view.window != nil {
                return fallback
            }
        }
        return nil
    }
}
