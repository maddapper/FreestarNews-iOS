//
//  MainViewController.swift
//

import UIKit
import SafariServices
import GoogleMobileAds
import FSAdSDK
import Firebase
import FirebaseDatabase
import AdSupport
import AVFoundation
import SnapKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate, GADBannerViewDelegate, FSRegistrationDelegate {
   
  // MARK: Properties
        
    let PostCellIdentifier = "PostCell"
    let ShowBrowserIdentifier = "ShowBrowser"
    let PullToRefreshString = "Pull to Refresh"
    let FetchErrorMessage = "Could Not Fetch Posts"
    let ErrorMessageLabelTextColor = UIColor.gray
    let ErrorMessageFontSize: CGFloat = 16
    let FirebaseRef = "https://hacker-news.firebaseio.com/v0/"
    let ItemChildRef = "item"
    let StoryTypeChildRefMap = [StoryType.top: "topstories", .new: "newstories", .show: "showstories"]
    let StoryLimit: UInt = 200
    let DefaultStoryType = StoryType.top

    var firebase = FIRDatabase.database().reference()
    var stories: [Story]! = []
    var storyType: StoryType!
    var retrievingStories: Bool!
    var refreshControl: UIRefreshControl!
    var errorMessageLabel: UILabel!
    
    var bannerView1: (UIView & FSBanner)?
    var bannerView2: (UIView & FSBanner)?
    var banners: [(UIView & FSBanner)?]?
    
    var isLoadedBanner_320_50: Bool = false
    var isLoadedBanner_300_250: Bool = false
        
    @IBOutlet weak var tableView: UITableView!

    // MARK: Enums

    enum StoryType {
        case top, new, show
    }

    // MARK: Structs

    struct Story {
        let title: String
        let url: String?
        let by: String
        let score: Int
    }

    // MARK: Initialization

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        firebase = FIRDatabase.database().reference(fromURL: FirebaseRef)
        stories = []
        storyType = DefaultStoryType
        retrievingStories = false
        refreshControl = UIRefreshControl()
    }

    deinit {
        let notification = NotificationCenter.default
        notification.removeObserver(self)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
                        
        configureUI()
        retrieveStories()
        loadBanners()
        loadRequests()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func anchorBanners() {
        anchorBanner(bannerView1, size: CGSize(width: 320, height: 50))
        anchorBanner(bannerView2, size: CGSize(width: 300, height: 250))
    }
        
    func anchorBanner(_ banner: UIView?, size: CGSize) {
        guard ((banner?.superview) != nil) else {
            return
        }

        if (banner == bannerView1) {
            if !isLoadedBanner_320_50 {
                return
            }
        } else if(banner == bannerView2) {
            if !isLoadedBanner_300_250 {
                return
            }
        }
        
        banner!.snp.makeConstraints { (make) in
            make.centerY.centerX.equalTo(banner!.superview!)
            make.size.equalTo(size)
        }
    }

    // MARK: Freestar Banner Init
    func loadBanners() {
        bannerView1 = FSAdProvider.createBanner(withIdentifier: FreestarConstants.placement1, size: kGADAdSizeBanner, adUnitId: FreestarConstants.adUnitID1, registrationDelegate: self, eventHandler: { [weak self]
            (methodName: String!, params: [ String : Any]) in
                        
            if methodName == DFPEventNameBanner.adViewDidReceiveAd.rawValue {
                self?.isLoadedBanner_320_50 = true
            }
            
            let cell: UITableViewCell? = self?.bannerView1?.superview?.superview! as? UITableViewCell;
            self?.updateCellIfNeeded(banner: self?.bannerView1!, cell: cell, methodName: methodName)
        })
        
        bannerView2 = FSAdProvider.createBanner(withIdentifier: FreestarConstants.placement2, size: kGADAdSizeMediumRectangle, adUnitId: FreestarConstants.adUnitID2, registrationDelegate: self, eventHandler: { [weak self]
            (methodName: String!, params: [ String : Any]) in
            
            if methodName == DFPEventNameBanner.adViewDidReceiveAd.rawValue {
                self?.isLoadedBanner_300_250 = true
            }
            
            let cell: UITableViewCell? = self?.bannerView2?.superview?.superview! as? UITableViewCell;
            self?.updateCellIfNeeded(banner: self?.bannerView2!, cell: cell, methodName: methodName)
        })
        
        bannerView1?.rootViewController = self
        bannerView1?.backgroundColor = UIColor.cyan
        bannerView1?.layer.borderWidth = 1
        
        bannerView2?.rootViewController = self
        bannerView2?.backgroundColor = UIColor.cyan
        bannerView2?.layer.borderWidth = 1
        
        banners = [ bannerView1, bannerView2 ]
    }
    
    // MARK: Freestar Banner Loading
    func loadRequests() {
        assert(Thread.current == Thread.main)
        let request = DFPRequest()
        // request.customTargeting = [ "freestarCustomKey" : "freestarCustomValue" ]
        // request.customTargeting = ["test" : "universalsafeframetrue"]
        
        bannerView1?.load(request)
        bannerView2?.load(request)
    }
    
    func updateCellIfNeeded(banner: (UIView & FSBanner)?, cell: UITableViewCell?, methodName: String) {
        guard cell != nil else {
            return
        }
        if (methodName == DFPEventNameBanner.adViewDidReceiveAd.rawValue) {
            anchorBanner(banner, size: banner!.fsAdSize)
        }
    }

    // MARK: Navigation
    @IBAction func unwindToMainViewController(segue: UIStoryboardSegue) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    // MARK: Functions

    func configureUI() {
        refreshControl.addTarget(self, action: #selector(MainViewController.retrieveStories), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: PullToRefreshString)
        tableView.insertSubview(refreshControl, at: 0)

        // Have to initialize this UILabel here because the view does not exist in init() yet.
        errorMessageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        errorMessageLabel.textColor = ErrorMessageLabelTextColor
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.font = UIFont.systemFont(ofSize: ErrorMessageFontSize)
    }

    @objc func retrieveStories() {
        if retrievingStories! {
          return
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        retrievingStories = true
        var storiesMap = [Int:Story]()
        var sortedStories = [Story]()

        DispatchQueue.global(qos: .userInitiated).async {
            let query = self.firebase.child(self.StoryTypeChildRefMap[self.storyType]!).queryLimited(toFirst: self.StoryLimit)
            query.observeSingleEvent(of: .value, with: { snapshot in
                let storyIds = snapshot.value as! [Int]
              
              for storyId in storyIds {
                let query = self.firebase.child(self.ItemChildRef).child(String(storyId))
                query.observeSingleEvent(of: .value, with: { snapshot in
                    storiesMap[storyId] = self.extractStory(snapshot)
                    sortedStories.append(storiesMap[storyId]!)
                    self.stories = sortedStories
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.retrievingStories = false
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                  }, withCancel: self.loadingFailed)
              }
              }, withCancel: self.loadingFailed)
        }
    }
    
    func emptyStory() -> Story {
        let title = "None"
        let url = "https://freestar.io"
        let by = "Nobody"
        let score = 1
        return Story(title: title, url: url, by: by, score: score)
    }

    func extractStory(_ snapshot: FIRDataSnapshot) -> Story {
        if let data = (snapshot.value as? Dictionary<String, Any>) {
            if let title = data["title"] as? String {
    //            let title = data["title"] as! String
                let url = data["url"] as? String
                let by = data["by"] as! String
                let score = data["score"] as! Int
                return Story(title: title, url: url, by: by, score: score)
            } else {
                return emptyStory()
            }
        } else {
            return emptyStory()
        }
    }

    func loadingFailed(_ error: Error?) -> Void {
        DispatchQueue.main.async {
            self.retrievingStories = false
            self.stories.removeAll()
            self.tableView.reloadData()
            self.showErrorMessage(self.FetchErrorMessage)
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }

    func showErrorMessage(_ message: String) {
        errorMessageLabel.text = message
        self.tableView.backgroundView = errorMessageLabel
        self.tableView.separatorStyle = .none
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var story: Story?
        if (indexPath.row >= stories.count) {
            story = emptyStory()
        } else {
            story = stories[indexPath.row]
        }
        if isBannerRow(indexPath.row) {
            let cell: UITableViewCell = UITableViewCell()
            cell.backgroundColor = UIColor.groupTableViewBackground
            guard let bannerView = bannerForIndex(indexPath.row) else {
                return cell
            }
            
            cell.contentView.addSubview(bannerView)
            if (bannerView == bannerView1!) {
                anchorBanner(bannerView, size: CGSize(width: 320, height: 50))
            } else if(bannerView == bannerView2!) {
                anchorBanner(bannerView, size: CGSize(width: 300, height: 250))
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: PostCellIdentifier) as UITableViewCell?
            cell?.textLabel?.text = story?.title
            cell?.detailTextLabel?.text = "\(story!.score) points by \(story!.by)"
            cell?.accessoryView?.isHidden = false
            return cell!
        }
    }

    // determine if row index should be a banner row based on modulo
    func isBannerRow(_ row: Int) -> Bool {
          if (row % FreestarConstants.listViewModulus) == 0 {
            return true
          }
          return false
    }
    
    func bannerForIndex(_ row: Int) -> (UIView & FSBanner)? {
        guard isBannerRow(row) else {
            return nil
        }
        let divisor = row / FreestarConstants.listViewModulus
        let bannerIndex = divisor % FreestarConstants.bannerCount
        guard let banners = banners else {
            return nil
        }
        
        return banners[bannerIndex]
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard isBannerRow(indexPath.row) else {
            let story = stories[indexPath.row]
            if let url = story.url {
                guard #available(iOS 9, *) else { return }
                let webViewController = SFSafariViewController(url: URL(string: url)!)
                webViewController.delegate = self
                present(webViewController, animated: true)
            }
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isBannerRow(indexPath.row) {
          return sizeForBannerIndex(indexPath.row).height
        } else {
          // non-banner row
          return 50.0
        }
    }
    
    func sizeForBannerIndex(_ row: Int) -> CGSize {
      guard isBannerRow(row) else {
        return CGSize.zero
      }
      let divisor = row / FreestarConstants.listViewModulus
      let bannerIndex = divisor % FreestarConstants.bannerCount
      switch bannerIndex {
      case 0:
          return CGSize(width: 320, height: 50)
      case 1:
          return CGSize(width: 300, height: 250)
      default:
        preconditionFailure("Freestar banner index is not being calculated correctly.")
      }
    }

    // MARK: SFSafariViewControllerDelegate

    @available(iOS 9, *)
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
        
    }
   
    @available(iOS 9, *)
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        
    }
    
    // MARK: IBActions
    @IBAction func changeStoryType(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
          storyType = .top
        } else if sender.selectedSegmentIndex == 1 {
          storyType = .new
        } else if sender.selectedSegmentIndex == 2 {
          storyType = .show
        } else {
          print("Bad segment index!")
        }

        retrieveStories()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    }
    
    // MARK: FSRegistrationDelegate methods
    func didRegister(forIdentifier identifier: String) {
        print("didRegister: \(identifier.debugDescription)")
    }

    func didFailToRegister(forIdentifier identifier: String) {
        print("didFailToRegister: \(identifier.debugDescription)")
    }
    
}
