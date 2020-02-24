//
//  ViewController.swift
//  makitDemo
//
//  Created by Margiett Gil on 2/24/20.
//  Copyright © 2020 Margiett Gil. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    private let locationSession = CoreLocationSession()
    private var isShowingNewAnnotations = false
    private var annotations = [MKPointAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    
    private var userTrackingButton: MKUserTrackingButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // let's attempt to show the user's location
        mapView.showsUserLocation = true 
        searchTextField.delegate = self
        
        userTrackingButton = MKUserTrackingButton(frame: CGRect(x: 20, y: 20, width: 40, height: 40))
        mapView.addSubview(userTrackingButton)
        userTrackingButton.mapView = mapView
        // add annotations to map view
        loadMaps()
        
        // set map view delagate to this view controller
        mapView.delegate = self
    }
    private func loadMaps(){
        let annotations = makeAnnotations()
        mapView.addAnnotations(annotations)
    }
    private func makeAnnotations() -> [MKPointAnnotation]{
        var annotations = [MKPointAnnotation]()
        for location in Location.getLocations() {
            let annotation = MKPointAnnotation()
            annotation.title = location.title
            annotation.coordinate = location.coordinate
            annotations.append(annotation)
            
        }
        
        isShowingNewAnnotations = true
        self.annotations = annotations
        return annotations
    }
    
    private func convertPlaceNameToCoordinate(_ placeName: String) {
        locationSession.convertPlaceNameToCoordinate(addressString: placeName) { (result) in
            switch result {
            case .failure(let error):
                print("geocoding error \(error)")
            case .success(let coordinate):
                print("coordinate: \(coordinate)")
                //MARK: set map view at given coordinate
                //MARK: moves  map to the given coordinate 
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1600, longitudinalMeters: 1600)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
}

extension MapViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let searchText = textField.text,
            !searchText.isEmpty else {
                return true 
        }
        convertPlaceNameToCoordinate(searchText)
        
        return true
    }
}
extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("\(view.annotation?.title) was selected")
        
        guard let annotation = view.annotation else
        { return }
        
        guard let location = (Location.getLocations().filter { $0.title == annotation.title }).first else { return }
        
        
        guard let detailVC = storyboard?.instantiateViewController(identifier: "LocationDetailController", creator: { coder in
            return LocationDetailController(coder: coder, location: location)
        }) else {
            fatalError("could not downcast to LocationDetailController")
        }
        detailVC.modalPresentationStyle = .overCurrentContext
        detailVC.modalTransitionStyle = .crossDissolve
        present(detailVC, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "annotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.glyphImage = UIImage(named: "duck")
            annotationView?.glyphTintColor = .systemTeal
            annotationView?.markerTintColor = .systemYellow
            //MARK: Text override the picture
            //annotationView?.glyphText = "iOS 6.3"
            
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if isShowingNewAnnotations {
            mapView.showAnnotations(annotations, animated: false)
        }
        isShowingNewAnnotations = false
    }
}
