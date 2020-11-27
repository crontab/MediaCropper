//
//  InvertedRoundMaskView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit


@IBDesignable
class InvertedRoundMaskView: UIView {

	@IBInspectable
	var enableMask: Bool = false {
		didSet { if enableMask != oldValue { setNeedsLayout() } }
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		let path = UIBezierPath(rect: bounds)
		let maskPath = enableMask ? UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width / 2) : path
		path.append(maskPath)
		path.usesEvenOddFillRule = true
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		maskLayer.fillRule = .evenOdd
		layer.mask = maskLayer
	}
}
