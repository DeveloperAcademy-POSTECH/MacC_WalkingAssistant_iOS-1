//
//  FunctionCells.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/10/09.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import UIKit

class FunctionCells: UICollectionViewCell {
    let functionDescriptionTextView: UITextView = {
        let textView = UITextView()

        //        let attributedText = NSMutableAttributedString(
        //            string: "Function Description",
        //            attributes: [NSAttributedStringkey.font: UIFont.boldSystemFont(ofSize: 18)]
        //        )

        return textView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        functionViewsLayout()
    }


    private func functionViewsLayout() {
        let buttonContainerView = UIView()
        addSubview(buttonContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
