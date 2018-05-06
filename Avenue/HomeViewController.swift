//
//  HomeViewController.swift
//  Avenue
//
//  Created by Saransh Mittal on 05/05/18.
//  Copyright © 2018 Saransh Mittal. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire

let GREY = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.3)

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    let locationManager = CLLocationManager()
    var monitoredRegions: Dictionary<String, Date> = [:]

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }

    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var birth: UILabel!
    @IBOutlet weak var name: UILabel!
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Alert that did enter the area")
        showAlert("We find traces of dengue near your location!")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("You are in a safe zone now!")
        showAlert("exit \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Update location")
        long = (locations.last?.coordinate.longitude)!
        lat = (locations.last?.coordinate.latitude)!
        print(lat, long)
    }
    
    func plotOnTheGraph(){
        for i in mapPlot{
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: i.latitide, longitude: i.longitude)
            annotation.title = i.name
            mapView.addAnnotation(annotation)
        }
    }

    func setupData() {
        // check if can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // region data
            let title = "A lot of traces about Dengue detected in this area! Be careful!"
            let coordinate = CLLocationCoordinate2DMake(28.489579, (77.079393))
            let regionRadius = 100.0
            // setup region
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: regionRadius, identifier: title)
            locationManager.startMonitoring(for: region)
            // setup annotation
            let restaurantAnnotation = MKPointAnnotation()
            restaurantAnnotation.coordinate = coordinate;
            restaurantAnnotation.title = "\(title)";
            mapView.addAnnotation(restaurantAnnotation)
            // setup circle
            let circle = MKCircle(center: coordinate, radius: regionRadius)
            mapView.add(circle)
        }
        else {
            print("System can't track regions")
        }
    }
    
    var diseaseClassification = [DISEASE]()
    var mapPlot = [DISEASE]()
    
    struct DISEASE {
        var name:String = ""
        var uid:String = ""
        var description:String = ""
        var caseNumber:Int = 1
        var latitide:Double = 0.0
        var longitude:Double = 0.0
    }
    var totalCases = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        // authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            showAlert("Location services were previously denied. Please enable location services for this app in Settings.")
        }
        // we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        print(["current_lat":String(describing: lat), "current_long":String(describing: long)])
        Alamofire.request("https://avenue-angelhack.herokuapp.com/doctor/nearbyCases", method: .post, parameters: ["current_lat":String(describing: lat), "current_long":String(describing: long)]).responseJSON { (response) in
            if response.result.isSuccess{
                if response.result.value != nil {
                    let a = response.result.value as! NSDictionary
                    if (a["success"] as! Int) == 1{
                        self.diseaseClassification.removeAll()
                        self.mapPlot.removeAll()
                        self.totalCases = 0
                        let b = a["cases"] as! [NSDictionary]
                        for i in b{
                            var z = DISEASE()
                            let diseaseInformation = i["current_disease"] as! NSDictionary
                            z.name = diseaseInformation["name"] as! String
                            z.description = diseaseInformation["description"] as! String
                            z.uid = diseaseInformation["_id"] as! String
                            if self.diseaseClassification.count == 0{
                                self.diseaseClassification.append(z)
                            } else {
                                var flag = 0
                                for j in 0...(self.diseaseClassification.count-1){
                                    if String(self.diseaseClassification[j].uid) == String(z.uid){
                                        self.diseaseClassification[j].caseNumber = self.diseaseClassification[j].caseNumber + 1
                                        flag = 1
                                        break
                                    } else {
                                        flag = 0
                                    }
                                }
                                if flag == 0{
                                    self.diseaseClassification.append(z)
                                }
                            }
                            var x = DISEASE()
                            x.latitide = i["lat"] as! Double
                            x.longitude = i["long"] as! Double
                            x.name = z.name
                            x.uid = z.uid
                            x.description = z.description
                            self.mapPlot.append(x)
                            self.totalCases = self.totalCases + 1
                        }
                        print(self.diseaseClassification)
                        print("These are the coodinated for the diseases detected")
                        print(self.mapPlot)
                        self.cardsCollectionView.reloadData()
                        self.plotOnTheGraph()
                    } else {
                        print(a)
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var mapView: MKMapView!
            
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2 + diseaseClassification.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0{
            let cell = cardsCollectionView.dequeueReusableCell(withReuseIdentifier: "location", for: indexPath) as! LocationCollectionViewCell
            cell.contentView.layer.cornerRadius = 5.0
            return cell
        } else if indexPath.row == 1{
            let cell = cardsCollectionView.dequeueReusableCell(withReuseIdentifier: "cases", for: indexPath) as! CasesCollectionViewCell
            cell.contentView.layer.cornerRadius = 5.0
            cell.casesNumber.text = String(totalCases) + " Cases"
            return cell
        } else {
            let cell = cardsCollectionView.dequeueReusableCell(withReuseIdentifier: "disease", for: indexPath) as! DiseaseCollectionViewCell
            cell.contentView.layer.cornerRadius = 5.0
            cell.diseaseName.text = diseaseClassification[indexPath.row - 2].name
            cell.casesNumber.text = String(diseaseClassification[indexPath.row - 2].caseNumber) + " People Infected"
            return cell
        }
    }
        
    @IBOutlet weak var cardsCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        name.text = NAME
        address.text = ADDRESS
        birth.text = String(AGE) + " yrs (" + BIRTHDATE + ")"
        cardsCollectionView.delegate = self
        cardsCollectionView.dataSource = self
//        titleView.layer.masksToBounds = false
//        titleView.layer.shadowColor = UIColor.black.cgColor
//        titleView.layer.shadowOpacity = 0.5
//        titleView.layer.shadowOffset = CGSize(width: -1, height: 2)
//        titleView.layer.shadowRadius = 1
//        titleView.layer.shadowPath = UIBezierPath(rect: titleView.bounds).cgPath
//        userView.layer.shouldRasterize = true
//        userView.layer.masksToBounds = false
//        userView.layer.shadowColor = UIColor.black.cgColor
//        userView.layer.shadowOpacity = 0.5
//        userView.layer.shadowOffset = CGSize(width: -1, height: 2)
//        userView.layer.shadowRadius = 1
//        userView.layer.shadowPath = UIBezierPath(rect: titleView.bounds).cgPath
//        userView.layer.shouldRasterize = true
        // setup locationManager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyBest;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.startUpdatingLocation()
        // setup mapView
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        // setup test data
        setupData()
        self.locationManager.requestAlwaysAuthorization()
        // Your coordinates go here (lat, lon)
        let geofenceRegionCenter = CLLocationCoordinate2D(
            latitude: 28.489579,
            longitude: 77.079393
        )
        let geofenceRegion = CLCircularRegion(
            center: geofenceRegionCenter,
            radius: 100,
            identifier: "UniqueIdentifier"
        )
        geofenceRegion.notifyOnEntry = true
        geofenceRegion.notifyOnExit = true
        self.locationManager.startMonitoring(for: geofenceRegion)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAlert(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
}
