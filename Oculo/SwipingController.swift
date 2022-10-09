//
//  SwipingController.swift
//  Oculo
//
//  Created by Kim, Raymond on 2022/10/09.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import UIKit

class SwipingController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.register(FunctionCells.self, forCellWithReuseIdentifier: "CellID")
    }
}
