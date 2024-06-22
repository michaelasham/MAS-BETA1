//
//  MaterialVC.swift
//  MAS-BETA
//
//  Created by Michael Asham on 17/06/2024.
//

import UIKit
import FirebaseStorage
import AVKit

class MaterialVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionViewFrame: UIView!
    @IBOutlet weak var likesView: BorderView!
    @IBOutlet weak var dislikeLbl: UILabel!
    @IBOutlet weak var likeLbl: UILabel!
    @IBOutlet weak var dislikeBtn: UIButton!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var mediaLbl: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var descView: UITextView!
    @IBOutlet weak var titleLbl: UILabel!
    var collectionView: UICollectionView!
    
    let storage = Storage.storage()
    let storageRef = Storage.storage().reference()
    
    var images: [UIImage] = [] // Your images
    var videoURL = URL(string: "")
    var material = MaterialService.instance.selectedMaterial
    var storedVideo: AVPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let video = AdminService.instance.findVideo(id: material.id!, ext: "mp4") {
            storedVideo = video
        }
        setupCollectionView()
        fetchImagesFromFirebase()
        titleLbl.text = material.name
        descView.text = material.desc
        setupVideoStatus()
        setupLikeView()
    }
    @IBAction func onLikeClick(_ sender: Any) {
        print("onLikeClick trig")
        var alreadyLiked = false
        for liker in material.likes {
            if liker == UserDataService.instance.user.id {
                // we like this
                alreadyLiked = true
                likeBtn.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .normal)
                dislikeBtn.setImage(UIImage(systemName: "hand.thumbsdown"), for: .normal)
            }
        }
        if alreadyLiked {
            MaterialService.instance.likeActivity(like: "")
        } else {
            MaterialService.instance.likeActivity(like: "like")
        }
        MaterialService.instance.pullMaterials { Success in
            self.material = MaterialService.instance.queryMaterial(id: self.material.id)
            self.setupLikeView()
        }
    }
    
    @IBAction func onDislikeClick(_ sender: Any) {
        print("onDislikeClick trig")
        var alreadyDisliked = false
        for liker in material.dislikes {
            if liker == UserDataService.instance.user.id {
                // we like this
                alreadyDisliked = true
                likeBtn.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
                dislikeBtn.setImage(UIImage(systemName: "hand.thumbsdown.fill"), for: .normal)
            }
        }
        if alreadyDisliked {
            MaterialService.instance.likeActivity(like: "")
        } else {
            MaterialService.instance.likeActivity(like: "dislike")
        }
        MaterialService.instance.pullMaterials { Success in
            self.material = MaterialService.instance.queryMaterial(id: self.material.id)
            self.setupLikeView()
        }
    }
    
    func setupLikeView() {
        likeLbl.text = "\(material.likes.count)"
        dislikeLbl.text = "\(material.dislikes.count)"
        likeBtn.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        dislikeBtn.setImage(UIImage(systemName: "hand.thumbsdown"), for: .normal)

        for liker in material.likes {
            if liker == UserDataService.instance.user.id {
                // we like this
                likeBtn.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .normal)
                dislikeBtn.setImage(UIImage(systemName: "hand.thumbsdown"), for: .normal)
            }
        }
        for disliker in material.dislikes {
            if disliker == UserDataService.instance.user.id {
                // we like this
                likeBtn.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
                dislikeBtn.setImage(UIImage(systemName: "hand.thumbsdown.fill"), for: .normal)
            }
        }
    }
    
    func setupVideoStatus() {
        playBtn.isHidden = false
        if videoURL != URL(string: "") || storedVideo != nil {
            print("has video stored")
            playBtn.setImage(UIImage(systemName: "play"), for: .normal)

        } else {
            print("brand new video")
            checkVideoExistenceInFirebaseStorage(reference: "materials/\(material.id!).mp4") { success in
                if success {
                    self.playBtn.setImage(UIImage(systemName: "arrow.down"), for: .normal)
                } else {
                    self.playBtn.isHidden = true
                    if self.images.count == 0 {
                        self.mediaLbl.isHidden = true
                        self.collectionView.isHidden = true
                    }
                }
            }
        }

    }
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: view.bounds.width, height: view.bounds.height * 1/3)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        collectionViewFrame.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: collectionViewFrame.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: collectionViewFrame.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: collectionViewFrame.bottomAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionViewFrame.heightAnchor, multiplier: 1)
        ])
    }
    
    func fetchImagesFromFirebase() {
        let storageRef = Storage.storage().reference().child("materials/")
        
        for index in 0...2 {
            let image = AdminService.instance.findImage(id: "\(material.id!)\(index)", ext: "jpg")
            if image.size.width == 0 {
                let imageRef = storageRef.child("\(material.id!)\(index).jpg")
                
                imageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if let error = error {
                        print("Error downloading image: \(error)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        AdminService.instance.saveImage(id: "\(self.material.id!)\(index)", image: data, ext: "jpg")
                        self.images.append(image)
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                        }
                    }
                }
            } else {
                self.images.append(image)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.imageView.image = images[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fullScreenVC = FullScreenViewController(images: images, initialIndex: indexPath.item)
        present(fullScreenVC, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
    @IBAction func onPlayClick(_ sender: Any) {
        if videoURL == URL(string: "") && storedVideo == nil {
            playBtn.isHidden = true
            pullVideo()
        } else {
            // Create the URL for the video
            if let videoURL = videoURL {
                // Instantiate AVPlayerViewController
                let player = AVPlayer(url: videoURL)
                // Present AVPlayerViewController
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                present(playerViewController, animated: true) {
                    player.play()
                }
                

            } else {
                let player = AVPlayer(playerItem: storedVideo)
                // Present AVPlayerViewController
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                present(playerViewController, animated: true) {
                    player.play()
                }
            }

            

        }
    }
    
    func checkVideoExistenceInFirebaseStorage(reference: String, completion: @escaping (Bool) -> Void) {
        let storage = Storage.storage()
        let storageReference = storage.reference(withPath: reference)
        
        // Check if the file exists
        storageReference.getMetadata { (metadata, error) in
            if let error = error {
                print("Error fetching metadata: \(error)")
                completion(false)
            } else {
                // File exists if metadata is successfully fetched
                completion(true)
            }
        }
    }
    
    func pullVideo() {
        let video = AdminService.instance.findImage(id: material.id!, ext: "mp4")
        if video.size == CGSize(width: 0, height: 0) {
            let videoRef = storageRef.child("materials/\(material.id!).mp4")
            let downloadTask = videoRef.getData(maxSize: 180 * 1024 * 1024) { data, error in
                if error != nil {
                    //no video
                    
                } else {
                    //video available
                    AdminService.instance.saveImage(id: self.material.id!, image: data!, ext: "mp4")
                    self.playBtn.isHidden = false
                    self.progressBar.isHidden = false
                    videoRef.downloadURL { videoURL, error in
                        if error == nil {
                            self.mediaLbl.text = "Media"
                            self.playBtn.isHidden = false
                            self.progressBar.isHidden = true
                            self.videoURL = videoURL
                            self.setupVideoStatus()
                            self.playBtn.setImage(UIImage(systemName: "play"), for: .normal)
                        }
                    }
                }

            }
            self.progressBar.isHidden = false
            downloadTask.observe(.progress) { snapshot in
                
                if let progress = snapshot.progress {
                    if progress.totalUnitCount > 0 {
                        let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount) * 100.0
                        let formattedPercentage = String(format: "%.1f", percentage)
                        print("\(progress.completedUnitCount) out of \(progress.totalUnitCount) - \(formattedPercentage)%")
                        self.mediaLbl.text = "Media (\(formattedPercentage)%)"
                        self.progressBar.progress = Float(percentage) / 100.0
                    } else {
                        print("Total unit count is zero.")
                    }
                } else {
                    print("Snapshot or progress is nil.")
                }
            }
        }
    }

}

class ImageCell: UICollectionViewCell {
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
