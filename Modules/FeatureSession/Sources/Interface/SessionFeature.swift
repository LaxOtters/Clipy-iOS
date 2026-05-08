//
//  SessionFeature.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import UIKit

public enum SessionFeature {
    public static func makeViewController(
        context: SessionLaunchContext
    ) -> UIViewController {
        SessionViewController(viewModel: SessionViewModel(context: context))
    }
}
