//
//  SessionWebView+Scroll.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import UIKit

extension SessionWebView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginRootDragging(snapshot: scrollSnapshot(from: scrollView))
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !scrollView.isDecelerating else {
            return
        }

        emitRootDraggingIfNeeded(snapshot: scrollSnapshot(from: scrollView))
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        prepareRootDragEnd(
            releaseVelocityY: velocity.y,
            targetOffsetY: targetContentOffset.pointee.y,
            currentOffsetY: scrollView.contentOffset.y
        )
    }

    func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate _: Bool
    ) {
        endRootDragging(snapshot: scrollSnapshot(from: scrollView))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        emitRootScroll(.decelerated(scrollSnapshot(from: scrollView)))
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        emitRootScroll(.externalScroll(scrollSnapshot(from: scrollView)))
    }
}
