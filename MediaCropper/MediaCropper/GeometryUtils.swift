//
//  GeometryUtils.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit



protocol ScalableViewProtocol: UIView {

	var screenCropRect: CGRect { get }
	var naturalSize: CGSize? { get }
}



extension ScalableViewProtocol {

	var scaleFactor: CGFloat {
		guard intrinsicContentSize.height > 0 else {
			return 1
		}
		return (naturalSize?.height ?? 0) / intrinsicContentSize.height
	}

	func effectiveCropFrame(with scrollView: UIScrollView) -> CGRect {
		screenCropRect.offset(by: scrollView.contentOffset).scaled(by: scaleFactor / scrollView.zoomScale)
	}

	var intrinsicSizeForCropping: CGSize? {
		guard let naturalSize = naturalSize, naturalSize.width > 0, naturalSize.height > 0 else {
			return nil
		}
		return naturalSize.circumscribed(on: screenCropRect.size)
	}
}



private extension CGRect {

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



private extension CGSize {

	func circumscribed(on rect: CGSize) -> CGSize {
		let newHeight = height * rect.width / width
		if newHeight < rect.height {
			let newWidth = width * rect.height / height
			return CGSize(width: newWidth, height: rect.height)
		}
		return CGSize(width: rect.width, height: newHeight)
	}
}
