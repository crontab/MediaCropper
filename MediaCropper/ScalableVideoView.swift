//
//  ScalableVideoView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit
import AVFoundation


/// This view plays a video in a loop. The `screenCropRect` instructs the view to resize itself (along with the video layer) to the minimal size that fills the crop size, so that it can be positioned by the user on screen. When cropping the actual video, `scaleFactor` can be used to determine how the screen cropping rectangle should be scaled before applying to the video.

class ScalableVideoView: UIView, ScalableViewProtocol {

	var videoURL: URL? {
		get { (queuePlayer.currentItem?.asset as? AVURLAsset)?.url }
		set { setVideoURL(newValue) }
	}


	func play() {
		if queuePlayer.currentItem != nil {
			queuePlayer.play()
		}
	}


	func pause() {
		queuePlayer.pause()
	}


	var isPlaying: Bool {
		queuePlayer.currentItem != nil && queuePlayer.rate > 0
	}


	var screenCropRect: CGRect = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if screenCropRect != oldValue {
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


	private var videoLayer = AVPlayerLayer(player: AVQueuePlayer())
	private var queuePlayer: AVQueuePlayer { videoLayer.player as! AVQueuePlayer }
	private var looper: AVPlayerLooper?


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
			looper = nil
			queuePlayer.removeAllItems()
			if let url = newValue {
				queuePlayer.insert(AVPlayerItem(url: url), after: nil)
				looper = AVPlayerLooper(player: queuePlayer, templateItem: queuePlayer.currentItem!)
			}
			invalidateIntrinsicContentSize()
		}
	}


	var naturalSize: CGSize? {
		guard let track = queuePlayer.currentItem?.asset.tracks(withMediaType: .video).first else {
			return nil
		}
		let result = track.naturalSize.applying(track.preferredTransform)
		return .init(width: abs(result.width), height: abs(result.height))
	}


	override var intrinsicContentSize: CGSize {
		intrinsicSizeForCropping ?? super.intrinsicContentSize
	}


	private func setup() {
		videoLayer.frame = bounds
		videoLayer.videoGravity = .resizeAspectFill
		videoLayer.masksToBounds = true
		clipsToBounds = true
		layer.addSublayer(videoLayer)
	}
}
