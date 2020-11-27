//
//  ScalableImageView.swift
//  ImageCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit


/// UIImageView's own intrinsic size equals to the image size loaded into it. Therefore to resize UIImageView intrinsicContentSize should be overridden. This class does it by specifying `minSize`: this image view will resize itself to the minimum size that entirely contains `minSize` dimensions.

class ScalableImageView: UIImageView {

	var minSize: CGSize = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if minSize != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}

	var scaleFactor: CGFloat { (image?.size.height ?? 0) / intrinsicContentSize.height }

	override var intrinsicContentSize: CGSize {
		guard minSize.width != 0, let image = image, image.size.width != 0 else {
			return super.intrinsicContentSize
		}
		let newHeight = image.size.height * minSize.width / image.size.width
		if newHeight < minSize.height {
			let newWidth = image.size.width * minSize.height / image.size.height
			return CGSize(width: newWidth, height: minSize.height)
		}
		return CGSize(width: minSize.width, height: newHeight)
	}
}
