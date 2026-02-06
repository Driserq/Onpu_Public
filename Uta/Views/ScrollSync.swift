import SwiftUI
import UIKit
import Combine

final class ScrollSyncGroup: ObservableObject {
    enum Pane {
        case jp
        case en
    }

    private weak var jpScrollView: UIScrollView?
    private weak var enScrollView: UIScrollView?
    private var isSyncing = false
    private var clearSyncWorkItem: DispatchWorkItem?

    func register(_ pane: Pane, scrollView: UIScrollView) {
        switch pane {
        case .jp:
            jpScrollView = scrollView
        case .en:
            enScrollView = scrollView
        }
    }

    func userDidScroll(_ pane: Pane) {
        guard !isSyncing else { return }

        guard let source = (pane == .jp ? jpScrollView : enScrollView),
              let target = (pane == .jp ? enScrollView : jpScrollView)
        else { return }

        let sourceScrollable = source.contentSize.height - source.bounds.height
        guard sourceScrollable > 0 else { return }

        let ratio = max(0, min(1, source.contentOffset.y / sourceScrollable))

        let targetScrollable = target.contentSize.height - target.bounds.height
        guard targetScrollable > 0 else { return }

        let targetY = max(0, min(targetScrollable, ratio * targetScrollable))

        isSyncing = true
        target.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)

        clearSyncWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.isSyncing = false }
        clearSyncWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10, execute: work)
    }
}

struct ScrollViewIntrospector: UIViewRepresentable {
    let pane: ScrollSyncGroup.Pane
    @ObservedObject var group: ScrollSyncGroup

    func makeCoordinator() -> Coordinator {
        Coordinator(pane: pane, group: group)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.attach(to: uiView)
    }

    final class Coordinator {
        let pane: ScrollSyncGroup.Pane
        let group: ScrollSyncGroup
        private weak var scrollView: UIScrollView?
        private var contentOffsetObs: NSKeyValueObservation?

        init(pane: ScrollSyncGroup.Pane, group: ScrollSyncGroup) {
            self.pane = pane
            self.group = group
        }

        func attach(to view: UIView) {
            guard scrollView == nil else { return }
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                guard let sv = self.findScrollView(from: view) else { return }
                self.scrollView = sv
                self.group.register(self.pane, scrollView: sv)
                self.contentOffsetObs = sv.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                    guard let self else { return }
                    self.group.userDidScroll(self.pane)
                }
            }
        }

        private func findScrollView(from view: UIView) -> UIScrollView? {
            var current: UIView? = view
            while let c = current {
                if let sv = c as? UIScrollView { return sv }
                current = c.superview
            }
            return nil
        }
    }
}
