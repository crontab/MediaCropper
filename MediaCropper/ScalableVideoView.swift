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


	private var naturalSize: CGSize? {
		guard let track = queuePlayer.currentItem?.asset.tracks(withMediaType: .video).first else {
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
