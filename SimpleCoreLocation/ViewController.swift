//
//  ViewController.swift
//  SimpleCoreLocation
//
//  Created by Arkadijs Makarenko on 26/04/2017.
//  Copyright © 2017 ArchieApps. All rights reserved.
//
import UIKit
import CoreLocation
import MapKit
class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    let locationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        locationManager.startUpdatingLocation()
        textView.text = "started!"
    }
    func appendMessage(message : String){
        textView.text = textView.text! + "\n" + message
    }
    func getPlace(location: CLLocation){
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error != nil{
                self.appendMessage(message: "GeoCode Error\(error?.localizedDescription)")
                return
            }
            guard let places = placemarks
                else{return}
            if let place = places.first{
                var address = ""
                if let name = place.name{
                    address += name + " "
                }
                if let local = place.locality{
                    address += local + " "
                }
                if let sublocal = place.subLocality{
                    address += sublocal
                }
                self.appendMessage(message: "Location near me is:\(address)")
                self.searchStore(placemark: place)
            }
        }
    }
    func searchStore(placemark : CLPlacemark){
        guard let coord = placemark.location?.coordinate else {
            return
        }
        let request = MKLocalSearchRequest()
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        request.region = MKCoordinateRegion(center: coord, span: span)
        request.naturalLanguageQuery = "Pizza"
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil{
                self.appendMessage(message: "Local search error\(error?.localizedDescription)")
                return
            }
            guard let response = response else{ self.appendMessage(message: "local Search No resualt")
                return}
            if let mapItem = response.mapItems.first{
                self.appendMessage(message: "Item Found : \(mapItem.name ?? "None")")
                let source = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                self.getRoute(from: source, to : mapItem)
            }
        }
    }
    
    func getRoute(from source : MKMapItem, to destination: MKMapItem){
        
        let request = MKDirectionsRequest()
        
        request.source = source
        request.destination = destination
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            if let err = error{
                self.appendMessage(message: "Direction error: \(err.localizedDescription)")
            }
            guard let response = response
                else{
                    self.appendMessage(message: "Direction: No RouteFound")
                    return
            }
            if let route = response.routes.first{
                self.appendMessage(message: "Route to: \(route.name) \(route.distance) \(route.expectedTravelTime)")
                for (index, step) in route.steps.enumerated(){
                    self.appendMessage(message: "\(index + 1): \(step.instructions)")
                }
            }
        }
        
    }
    
}

extension ViewController :CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        appendMessage(message: "Updating Location")
        if let location = locations.first{
            appendMessage(message: "Acurancy : \(location.horizontalAccuracy)")
            if location.horizontalAccuracy < 100 && location.verticalAccuracy < 100{
                manager.stopUpdatingLocation()
                appendMessage(message: "Found You @ \(location.coordinate)")
                getPlace(location:location)
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        appendMessage(message: "error: \(error.localizedDescription)")
    }
}

