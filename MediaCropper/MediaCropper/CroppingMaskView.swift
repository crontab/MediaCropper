//
//  CroppingMaskView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit


@IBDesignable
class CroppingMaskView: UIView {

	@IBInspectable
	var isOval: Bool = false {
		didSet { if isOval != oldValue { setNeedsLayout() } }
	}

	@IBInspectable
	var borderWidth: CGFloat = 0 {
		didSet { if borderWidth != oldValue { setNeedsLayout() } }
	}

	@IBInspectable
	var borderDash: CGFloat = 0 {
		didSet { if borderDash != oldValue { setNeedsLayout() } }
	}

	@IBInspectable
	var cornerMarkerWidth: CGFloat = 0 {
		didSet { if cornerMarkerWidth != oldValue { setNeedsLayout() } }
	}


	private let cornerMarkerLength: CGFloat = 12


	override func layoutSubviews() {
		super.layoutSubviews()

		let path = UIBezierPath(rect: bounds)
		path.append(maskPath(insetBy: 0))
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		maskLayer.fillRule = .evenOdd
		maskLayer.fillColor = backgroundColor?.cgColor

		layer.backgroundColor = nil
		layer.sublayers = []
		layer.addSublayer(maskLayer)

		if borderWidth > 0 {
			let layer = CAShapeLayer()
			layer.path = maskPath(insetBy: borderWidth / 2).cgPath
			layer.strokeColor = tintColor?.cgColor
			layer.fillColor = nil
			layer.lineWidth = borderWidth
			if borderDash > 0 {
				layer.lineDashPattern = [borderDash as NSNumber, borderDash as NSNumber]
			}
			self.layer.addSublayer(layer)
		}

		if cornerMarkerWidth > 0 {
			let rect = bounds.inset(by: cornerMarkerWidth / 2)
			let layer = CAShapeLayer()
			layer.strokeColor = tintColor?.cgColor
			layer.fillColor = nil
			layer.lineWidth = cornerMarkerWidth

			let path = UIBezierPath()
			let w = cornerMarkerLength

			// Top left
			path.moveTo(x: rect.minX, y: rect.minY + w)
			path.lineTo(x: rect.minX, y: rect.minY)
			path.lineTo(x: rect.minX + w, y: rect.minY)

			// Top right
			path.moveTo(x: rect.maxX - w, y: rect.minY)
			path.lineTo(x: rect.maxX, y: rect.minY)
			path.lineTo(x: rect.maxX, y: rect.minY + w)

			// Bottom right
			path.moveTo(x: rect.maxX, y: rect.maxY - w)
			path.lineTo(x: rect.maxX, y: rect.maxY)
			path.lineTo(x: rect.maxX - w, y: rect.maxY)

			// Bottom left
			path.moveTo(x: rect.minX + w, y: rect.maxY)
			path.lineTo(x: rect.minX, y: rect.maxY)
			path.lineTo(x: rect.minX, y: rect.maxY - w)

			layer.path = path.cgPath
			self.layer.addSublayer(layer)
		}
	}


	private func maskPath(insetBy: CGFloat) -> UIBezierPath {
		isOval ? UIBezierPath(roundedRect: bounds.inset(by: insetBy), cornerRadius: bounds.width / 2) : UIBezierPath(rect: bounds.inset(by: insetBy))
	}
}


private extension CGRect {

	func inset(by: CGFloat) -> Self {
		inset(by: UIEdgeInsets(top: by, left: by, bottom: by, right: by))
	}
}


private extension UIBezierPath {

	func moveTo(x: CGFloat, y: CGFloat) { move(to: CGPoint(x: x, y: y)) }
	func lineTo(x: CGFloat, y: CGFloat) { addLine(to: CGPoint(x: x, y: y)) }
}
