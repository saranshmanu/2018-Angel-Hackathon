//
//  SecondViewController.swift
//  Avenue
//
//  Created by Saransh Mittal on 05/05/18.
//  Copyright © 2018 Saransh Mittal. All rights reserved.
//

import UIKit
import MapKit
import UserNotifications
import Alamofire

var lat = Double()
var long = Double()

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class SecondViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(diseaseClassification.count)
        if diseaseClassification.count == 0{
            self.hide()
        } else {
            self.show()
        }
        return diseaseClassification.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionEpedemicView.dequeueReusableCell(withReuseIdentifier: "epedemic", for: indexPath) as! EpedemicCollectionViewCell
        cell.contentView.layer.cornerRadius = 5.0
        cell.diseaseName.text = diseaseClassification[indexPath.row].name
        cell.numberOfCases.text = String(diseaseClassification[indexPath.row].caseNumber) + " cases (in the area of 4 km around)"
        return cell
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionEpedemicView: UICollectionView!

    var selectedPin:MKPlacemark? = nil
    var resultSearchController:UISearchController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionEpedemicView.delegate = self
        collectionEpedemicView.dataSource = self
        hide()
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! TableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Enter your Destination"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
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
    
    func getTheEpidemicData(placemark:MKPlacemark){
        Alamofire.request("https://avenue-angelhack.herokuapp.com/doctor/nearbyCases", method: .post, parameters: ["current_lat":String(describing: placemark.coordinate.latitude), "current_long":String(describing: placemark.coordinate.longitude)]).responseJSON { (response) in
            if response.result.isSuccess{
                if response.result.value != nil {
                    let a = response.result.value as! NSDictionary
                    if (a["success"] as! Int) == 1{
                        self.diseaseClassification.removeAll()
                        self.mapPlot.removeAll()
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
                        }
                        print(self.diseaseClassification)
                        print("These are the coodinated for the diseases detected")
                        print(self.mapPlot)
                        self.plotOnTheGraph()
                        self.collectionEpedemicView.reloadData()
                    } else {
                        self.diseaseClassification.removeAll()
                        self.mapPlot.removeAll()
                        print(a)
                        self.collectionEpedemicView.reloadData()
                    }
                }
            }
        }
    }
    
    func show(){
        collectionEpedemicView.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.collectionEpedemicView.alpha = 1.0
        }
    }
    func hide(){
        UIView.animate(withDuration: 0.5) {
            self.collectionEpedemicView.alpha = 0.0
        }
        collectionEpedemicView.isHidden = true
    }
    
    func plotOnTheGraph(){
        for i in mapPlot{
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: i.latitide, longitude: i.longitude)
            annotation.title = i.name
            mapView.addAnnotation(annotation)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class MyPointAnnotation : MKPointAnnotation {
    var pinTintColor: UIColor?
}

extension SecondViewController: HandleMapSearch {
    func addRadiusCircle(location: CLLocation){
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 4000)
        self.mapView.add(circle)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.red
            circle.fillColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.1)
            circle.lineWidth = 1
            return circle
        } else {
            return MKPolylineRenderer()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        if let annotation = annotation as? MyPointAnnotation {
            annotationView?.pinTintColor = annotation.pinTintColor
        }
        return annotationView
    }
    
    func dropPinZoomIn(placemark:MKPlacemark){
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        selectedPin = placemark
        getTheEpidemicData(placemark: placemark)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        annotation.subtitle = "This is the location of your destination"
//        annotation.pinTintColor = .black
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        self.addRadiusCircle(location: CLLocation(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude))
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

extension MKPinAnnotationView {
    class func bluePinColor() -> UIColor {
        return UIColor.blue
    }
}

