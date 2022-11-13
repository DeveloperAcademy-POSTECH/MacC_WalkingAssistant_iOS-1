//
//  LabelsTableViewCell.swift
//  Oculo
//
//  Created by Jinsan Kim on 2022/11/08.
//  Copyright © 2022 IntelligentATLAS. All rights reserved.
//

import UIKit

class LabelsTableViewCell: UITableViewCell {

    let predictedLabel = UILabel()
    let informationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: "InformationCell")
        setupCell()
        setupLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("Please use this class from code.")
    }

    func setupCell() {

        predictedLabel.translatesAutoresizingMaskIntoConstraints = false
        informationLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(predictedLabel)
        contentView.addSubview(informationLabel)

        predictedLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        predictedLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
        predictedLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor, constant: -20).isActive = true

        informationLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        informationLabel.leadingAnchor.constraint(equalTo: predictedLabel.trailingAnchor, constant: 8).isActive = true
        informationLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
    }

    func setupLabel() {
        predictedLabel.font = UIFont.systemFont(ofSize: 12)
        predictedLabel.textAlignment = .left
        predictedLabel.textColor = .white

        informationLabel.font = UIFont.systemFont(ofSize: 12)
        informationLabel.textAlignment = .left
        informationLabel.textColor = .white
    }

}
