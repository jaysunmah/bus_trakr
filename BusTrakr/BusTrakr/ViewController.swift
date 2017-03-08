//
//  ViewController.swift
//  BusTrakr
//
//  Created by Jason Ma on 2/3/17.
//  Copyright © 2017 Jason Ma. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var currentCoordinate: CLLocationCoordinate2D? = nil
    var pinCoordinate: CLLocationCoordinate2D? = nil
    
    var inboundBuses = [AnyObject]()
    var outboundBuses = [AnyObject]()
    var selectedBuses = [AnyObject]()
    var segmentedIndex = 0
    
    var dropPin = MKPointAnnotation()
    var loc1Pin = MKPointAnnotation()
    var loc2Pin = MKPointAnnotation()
    
    var weiPin = MKPinAnnotationView()
    
    var mapViewCoords: CLLocation? = nil
    
    var zoomedIn: Bool = false;
    var isLiveTracking: Bool = false;
    
    var loc1: CLLocationCoordinate2D? = nil
    var loc2: CLLocationCoordinate2D? = nil
    
//    var api1: String = "WQaS9sjHp2qwP2gXBKzwsL2yH"
//    var api2: String = "qKt6zjerWdX5dmg5ZqUpBwhEB"
//    var apiCounter: Int = 0
    
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Timer.scheduledTimer(timeInterval: 10.0,
                             target: self,
                             selector: #selector(self.pingBuses),
                             userInfo: nil,
                             repeats: true)

        Timer.scheduledTimer(timeInterval: 0.5,
                             target: self,
                             selector: #selector(self.liveTrackingBuses),
                             userInfo: nil,
                             repeats: true)

        // Ask for Authorisation from the User.

        self.mapView.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        self.mapView.showsUserLocation = true
    }

    @IBAction func selectBus(_ sender: UISegmentedControl) {

        segmentedIndex = sender.selectedSegmentIndex
        
        if (sender.selectedSegmentIndex == 0) {
            selectedBuses = inboundBuses
        } else {
            selectedBuses = outboundBuses
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedBuses.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        if (indexPath.row == 0) {
            var stopName: String = ""
            if (selectedBuses.count > 0) {
                stopName = selectedBuses[indexPath.row]["stpnm"] as! String
            } else {
                stopName = "Loading Buses..."
            }
            cell.busName.text = ""
            cell.busType.text = stopName
            cell.busTime.text = ""
        } else {
            let destination: String = selectedBuses[indexPath.row - 1]["des"] as! String
            let route: String = selectedBuses[indexPath.row - 1]["rt"] as! String
            var time: Int = selectedBuses[indexPath.row - 1]["est_arrival"] as! Int
            time = time % 1440
            cell.busName.text = destination
            cell.busType.text = route
            cell.busTime.text = String(describing: time)
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapViewCoords = locations.last
        currentCoordinate = manager.location!.coordinate
        
        if (!zoomedIn) {
            zoomedIn = true
            animateReturnToOrigin()
            getBusInfo()
        }
    }
    
    @IBAction func returnToOrigin(_ sender: Any) {
        animateReturnToOrigin()
    }
    
    @IBAction func getBuses(_ sender: Any) {
//        getBusInfo()
    }
    
    @IBAction func dropPin(_ sender: UITapGestureRecognizer) {
        if (!isLiveTracking) {
            let location = sender.location(in: self.mapView)
            let locCoord = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            pinCoordinate = locCoord
            
            dropPin.coordinate = locCoord
            
            mapView.addAnnotation(dropPin)
            
            getBusInfo()
        }
    }
    
    @IBAction func toggleLiveTracking(_ sender: UISwitch) {
        isLiveTracking = sender.isOn
    }
    
    func getBusInfo() {
        let state = UIApplication.shared.applicationState
        if state != .background {
            var latitude = currentCoordinate?.latitude
            var longitude = currentCoordinate?.longitude
            
            
            if (pinCoordinate != nil) {
                latitude = pinCoordinate?.latitude
                longitude = pinCoordinate?.longitude
            }
            
            let requestUrl = "https://sheltered-refuge-14380.herokuapp.com/findstop/" + String(describing: latitude!) + "/" + String(describing: longitude!)
            print(requestUrl)
            
            let url = NSURL(string: requestUrl)
            let request = NSURLRequest(url: url! as URL)
            
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) {(response, data, error) in
                let busData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                let dict = self.convertToDictionary(text: busData! as String)
                
                self.inboundBuses = []
                for value in dict!["INBOUND"] as! [AnyObject] {
                    self.inboundBuses.append(value)
                }
                
                self.outboundBuses = []
                
                for value in dict!["OUTBOUND"] as! [AnyObject] {
                    self.outboundBuses.append(value)
                }
                if (self.segmentedIndex == 0) {
                    self.selectedBuses = self.inboundBuses
                    
                } else {
                    self.selectedBuses = self.outboundBuses
                }
                
                let loc1_lat = dict!["LOC1"]!["lat"]!!
                let loc1_lon = dict!["LOC1"]!["lon"]!!
                
                let loc2_lat = dict!["LOC2"]!["lat"]!!
                let loc2_lon = dict!["LOC2"]!["lon"]!!

                self.loc1 = CLLocationCoordinate2D(latitude: loc1_lat as! CLLocationDegrees, longitude: loc1_lon as! CLLocationDegrees)
                self.loc2 = CLLocationCoordinate2D(latitude: loc2_lat as! CLLocationDegrees, longitude: loc2_lon as! CLLocationDegrees)
                
                self.loc1Pin.coordinate = self.loc1!
//                self.loc1Pin.title = "Location 1"
//                self.loc1Pin.subtitle = ""
                
                self.mapView.addAnnotation(self.loc1Pin)
                
                self.loc2Pin.coordinate = self.loc2!
//                self.loc2Pin.title = "Location 2"
//                self.loc2Pin.subtitle = ""
                
                self.mapView.addAnnotation(self.loc2Pin)
                
                self.tableView.reloadData()
                
            }
        }
    }
    
    func pingBuses() {
        getBusInfo()
    }
    
    func animateReturnToOrigin() {
        let location  = mapViewCoords
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        self.mapView.setRegion(region, animated: true)
    }

    func liveTrackingBuses() {
        if (isLiveTracking) {
            self.mapView.removeAnnotation(dropPin)
            animateReturnToOrigin()
            pinCoordinate = nil
        }
    }
    
    func convertToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    
}
