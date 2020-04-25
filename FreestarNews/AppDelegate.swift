//
//  AppDelegate.swift
//

import UIKit
import PrebidMobileFS
import FSAdSDK
import FSCommon
import Firebase
import FirebaseDatabase
import AVFoundation
import CoreLocation
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
  public var didLoadAds = false
  // MARK: Properties
  let GlobalTintColorInitial = UIColor.lightGray
  let GlobalTintColorError = UIColor.red
  let GlobalTintColorDefault = UIColor(red: 0.0, green: 0.73, blue: 0.5, alpha: 1.0)
  
  var window: UIWindow?
  var locationManager: CLLocationManager = CLLocationManager()
  var registrationStatus: FSRegistrationStatus? = FSRegistrationStatus.initial
  var registeredAdUnitsCount: Int = 0
  
  // MARK: UIApplicationDelegate
  
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    self.window?.tintColor = GlobalTintColorInitial
    
    FIRApp.configure()
    FIRDatabase.database().persistenceEnabled = true

//    PBLogManager.setPBLogLevel(PBLogLevel.debug)
    FSAdSDK.overrideBundleIdentifier("com.stocktwits.StockTwits")

    setupLocationManager()
    applyTargeting()
    
    // FSAdSDK    
//    FSRegistration.register()
        
    FSRegistration.register { (status, adUnits) in
      // optional for first ad load
      if (status == .success) {
        // status or informational
        self.registeredAdUnitsCount = (adUnits?.count)!
        self.applyTint()
        for adUnit in adUnits! {
          print("\(adUnit.identifier!) | \(adUnit.adSizes!)")
        }
      } else {
        self.applyTint()
      }

      self.registrationStatus = status
    }

    return true
  }
  
  // MARK: Window tint
  
  func applyTint() {
    UIView.animate(withDuration: 0.5, delay: 0.3, options: [ .curveEaseOut ], animations: {
        self.window?.tintColor = FSRegistration.isRegistered() ? self.GlobalTintColorDefault : self.GlobalTintColorError
    }, completion: nil)
  }
  
  // MARK: DFP targeting
  func applyTargeting() {
    PBTargetingParams.sharedInstance().age = 24;
    PBTargetingParams.sharedInstance().gender = PBTargetingParamsGender.female;
    PBTargetingParams.sharedInstance().itunesID = "456805313"
  }
  
  // MARK: DFP targeting
  func setupLocationManager() {
    guard #available(iOS 8, *) else {
        return
    }
    
    locationManager.delegate = self
    locationManager.distanceFilter = kCLDistanceFilterNone
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    PBTargetingParams.sharedInstance().location = locations.last
  }
}
