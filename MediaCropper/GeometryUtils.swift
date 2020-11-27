//
//  GeometryUtils.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit


extension CGRect {

	func scaled(by: CGFloat) -> CGRect {
		var r = self
		r.origin.x *= by
		r.origin.y *= by
		r.size.width *= by
		r.size.height *= by
		return r
	}

	func offset(by: CGPoint) -> CGRect {
		var r = self
		r.origin.x += by.x
		r.origin.y += by.y
		return r
	}
}


extension CGSize {

	var absed: CGSize { .init(width: abs(width), height: abs(height)) }

	func circumscribed(on rect: CGSize) -> CGSize {
		let newHeight = height * rect.width / width
		if newHeight < rect.height {
			let newWidth = width * rect.height / height
			return CGSize(width: newWidth, height: rect.height)
		}
		return CGSize(width: rect.width, height: newHeight)
	}
}


extension UIImage {

	func cropped(at cropFrame: CGRect) -> UIImage? {
		guard cropFrame.size.width > 0, cropFrame.size.height > 0 else {
			return nil
		}
		UIGraphicsBeginImageContextWithOptions(cropFrame.size, true, 1);
		draw(in: CGRect(x: -cropFrame.origin.x, y: -cropFrame.origin.y, width: size.width, height: size.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
}
