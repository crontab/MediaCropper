//
//  ScalableVideoView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit
import AVFoundation


class ScalableVideoView: UIView {

	var videoURL: URL? {
		get { (player?.currentItem?.asset as? AVURLAsset)?.url }
		set { setVideoURL(newValue) }
	}


	private(set) var player: AVPlayer? {
		get { videoLayer.player }
		set { videoLayer.player = newValue }
	}


	var cropSize: CGSize = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if cropSize != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}


	// MARK: - internal

	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}


	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}


	private var videoLayer = AVPlayerLayer()


	open override func layoutSubviews() {
		super.layoutSubviews()
		if bounds != videoLayer.frame {
			CATransaction.begin()
			CATransaction.setValue(true, forKey: kCATransactionDisableActions)
			videoLayer.frame = bounds
			CATransaction.commit()
		}
	}


	private func setVideoURL(_ newValue: URL?) {
		if newValue != videoURL {
			player?.pause()
			player = nil
			if let url = newValue {
				player = AVPlayer(url: url)
			}
			invalidateIntrinsicContentSize()
		}
	}


	private var naturalSize: CGSize? {
		guard let track = player?.currentItem?.asset.tracks(withMediaType: .video).first else {
			return nil
		}
		return track.naturalSize.applying(track.preferredTransform).absed
	}


	override var intrinsicContentSize: CGSize {
		guard let naturalSize = naturalSize else {
			return super.intrinsicContentSize
		}
		return naturalSize.circumscribed(on: cropSize)
	}


	private func setup() {
		videoLayer.frame = bounds
		videoLayer.videoGravity = .resizeAspectFill
		videoLayer.masksToBounds = true
		clipsToBounds = true
		layer.addSublayer(videoLayer)
	}
}
