//
//  BorderButton.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//


import UIKit


@IBDesignable
class BorderButton: UIButton {
    
    override func prepareForInterfaceBuilder() {
        setupBtn()
    }
    
    override func awakeFromNib() {
        setupBtn()
    }
    
    func setupBtn() {
        self.layer.cornerRadius = 15
//        self.layer.borderColor = self.titleColor(for: .normal)?.cgColor
//        self.layer.borderWidth = 2
    }

}
@IBDesignable
class CircleButton: UIButton {
    
    override func prepareForInterfaceBuilder() {
        setupBtn()
    }
    
    override func awakeFromNib() {
        setupBtn()
    }
    
    func setupBtn() {
        self.layer.cornerRadius = self.frame.width / 2
//        self.layer.borderColor = self.titleColor(for: .normal)?.cgColor
//        self.layer.borderWidth = 2
    }

}

@IBDesignable
class CircleView: UIView {
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
    }
}

@IBDesignable
class BorderView: UIView {
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = 15
    }
}
@IBDesignable
class BorderImageView: UIImageView {
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = 15
    }
}
@IBDesignable
class CircleImageView: UIImageView {
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.height / 2
    }
}
