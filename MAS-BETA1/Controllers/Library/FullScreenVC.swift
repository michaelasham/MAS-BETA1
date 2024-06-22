//
//  FullScreenViewController.swift
//  MAS-BETA1
//
//  Created by Michael Asham on 19/06/2024.
//

import UIKit
class FullScreenViewController: UIViewController, UIScrollViewDelegate {
    var images: [UIImage]
    var initialIndex: Int
    var scrollView: UIScrollView!
    var pageControl: UILabel!
    var closeButton: UIButton!

    init(images: [UIImage], initialIndex: Int) {
        self.images = images
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollView()
        setupPageControl()
        setupCloseButton()
        setupImages()
        
        scrollView.setContentOffset(CGPoint(x: CGFloat(initialIndex) * view.bounds.width, y: 0), animated: false)
        updatePageControl()
    }
    
    func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        view.addSubview(scrollView)
    }
    
    func setupPageControl() {
        pageControl = UILabel()
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.textColor = .white
        pageControl.textAlignment = .center
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func setupImages() {
        for (index, image) in images.enumerated() {
            let singleScrollView = UIScrollView(frame: CGRect(x: CGFloat(index) * view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height))
            singleScrollView.delegate = self
            singleScrollView.minimumZoomScale = 1.0
            singleScrollView.maximumZoomScale = 6.0
            singleScrollView.showsHorizontalScrollIndicator = false
            singleScrollView.showsVerticalScrollIndicator = false
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true

            // Set imageView frame to fit within the bounds of the singleScrollView
            let widthScale = view.bounds.width / image.size.width
            let heightScale = view.bounds.height / image.size.height
            let minScale = min(widthScale, heightScale)
            let imageViewWidth = image.size.width * minScale
            let imageViewHeight = image.size.height * minScale
            imageView.frame = CGRect(x: (view.bounds.width - imageViewWidth) / 2, y: (view.bounds.height - imageViewHeight) / 2, width: imageViewWidth, height: imageViewHeight)

            singleScrollView.addSubview(imageView)
            singleScrollView.contentSize = imageView.bounds.size
            
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTapRecognizer.numberOfTapsRequired = 2
            singleScrollView.addGestureRecognizer(doubleTapRecognizer)
            
            scrollView.addSubview(singleScrollView)
        }
        scrollView.contentSize = CGSize(width: CGFloat(images.count) * view.bounds.width, height: view.bounds.height)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView != self.scrollView {
            return scrollView.subviews.first
        }
        return nil
    }
    
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if let scrollView = recognizer.view as? UIScrollView {
            let pointInView = recognizer.location(in: scrollView)
            let currentZoomScale = scrollView.zoomScale
            let newZoomScale = currentZoomScale == 1 ? scrollView.maximumZoomScale : 1
            
            let scrollViewWidth = scrollView.bounds.width
            let scrollViewHeight = scrollView.bounds.height
            let width = scrollViewWidth / newZoomScale
            let height = scrollViewHeight / newZoomScale
            let x = pointInView.x - (width / 2.0)
            let y = pointInView.y - (height / 2.0)
            
            let zoomRect = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            updatePageControl()
        }
    }
    
    func updatePageControl() {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.text = "\(pageIndex + 1)/\(images.count)"
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
