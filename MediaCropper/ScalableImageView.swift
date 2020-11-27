//
//  ScalableImageView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit


/// UIImageView's own intrinsic size equals to the image size loaded into it. Therefore to resize UIImageView intrinsicContentSize should be overridden. This class does it by specifying `cropSize`: this image view will resize itself to the minimum size that entirely contains `cropSize` dimensions.

class ScalableImageView: UIImageView {

	var cropSize: CGSize = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if cropSize != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}

	var scaleFactor: CGFloat { (image?.size.height ?? 0) / intrinsicContentSize.height }

	override var intrinsicContentSize: CGSize {
		guard cropSize.width != 0, let image = image, image.size.width != 0 else {
			return super.intrinsicContentSize
		}
		return image.size.circumscribed(on: cropSize)
	}
}
