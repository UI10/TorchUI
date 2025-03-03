//
//  PlaceSensorView.swift
//  TorchUI
//
//  Created by Parth Saxena on 6/28/23.
//

import SwiftUI
import CoreLocation
import GoogleMaps
import CodeScanner
import MapboxMaps

struct PlaceSensorView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private let width = UIScreen.main.bounds.width
    private let height = UIScreen.main.bounds.height
    
    //    @ObservedObject var sessionManager = SessionManager()
    //    @Binding var state: OnboardingState?
    @ObservedObject var sessionManager = SessionManager.shared
    
    // Google maps tutorial START
    static var detectors: [Detector] = []
    @State var markers: [GMSMarker] = []
    
    @State var annotations: [PointAnnotation] = [PointAnnotation]()
    
    @State var hideOverlay: Bool = false
    @State var showDetectorDetails: Bool = false
    @State var zoomInCenter: Bool = false
    @State var selectedDetector: Detector?
    @State var selectedMarker: GMSMarker?
    
    @State var isPresentingScanner: Bool = false
    @State var showingOptions: Bool = false
    
    @State var isConfirmingLocation: Bool = false
    
    @State var selectedSensor: Detector?
    
    @State var mapOffset: CGSize = CGSize()
    @State var size: CGSize = CGSize()
    
    @State var pin: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    @State var needsLocationPin: Bool = false
    
    @State var moveToUserTapped: Bool = false
    
    @State var sensorTapped: Bool = false
    
    // Google maps tutorial END
    
    init() {
        // print("Count: \(sessionManager.selectedProperty!.detectors.count)")
        // print("Markers Count: \(markers.count)")
        
        //        self.pin = GMSMarker()
        ////        pin!.icon = UIImage(named: "Pin")
        ////        pin!.icon?.scale = 5.0
        //
        //        var markerImage = UIImage(named: "Pin")
        //        markerImage = UIImage(cgImage: (markerImage?.cgImage)!, scale: 4.0, orientation: (markerImage?.imageOrientation)!)
        //        self.pin!.icon = markerImage
        //        pin!.map = self.map
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Maps
                ZStack {
                    MapboxPlaceSensorViewWrapper(mapOffset: $mapOffset, showDetectorDetails: $showDetectorDetails, selectedDetector: $selectedDetector, needsLocationPin: $needsLocationPin, annotations: $annotations, pin: $pin, moveToUserTapped: $moveToUserTapped, sensorTapped: $sensorTapped)
                    //                    PlaceSensorViewControllerBridge(mapBottomOffset: $size.height, isConfirmingLocation: $isConfirmingLocation, markers: $markers, selectedMarker: $selectedMarker, selectedDetector: $selectedDetector, showDetectorDetails: $showDetectorDetails, detectors: sessionManager.selectedProperty!.detectors, onAnimationEnded: {
                    //                        self.zoomInCenter = true
                    //                    }, mapViewWillMove: { (isGesture) in
                    //                        guard isGesture else { return }
                    //                        self.zoomInCenter = false
                    //                    }, mapViewDidChange: { (position) in
                    //                        if !isConfirmingLocation {
                    //                            self.pin = position.target
                    //                            // print("Map did change: \(position.target)")
                    //                            // print("Map did change, pin: \(self.pin)")
                    //                        }
                    //                    })
                        .ignoresSafeArea()
                        .animation(.easeIn)
                }
                
                //                ZStack {
                //                    VStack {
                //                        Spacer()
                //
                //                        Image("Pin")
                //                            .resizable()
                //                            .frame(width: 60, height: 69)
                //                            .padding(.bottom, 69 + 20)
                //
                //                        Spacer()
                //                    }
                //                    .padding(.bottom, self.size.height)
                //                }
                
                VStack {
                    // Image pin
                    
                    Spacer()
                    
                    // Overlay
                    VStack {
                        if isConfirmingLocation {
                            SensorConfirmLocationOverlayView(mapOffset: $mapOffset, size: $size, markers: $markers, pin: $pin, selectedSensor: $selectedSensor, isConfirmingLocation: $isConfirmingLocation)
                        } else {
                            SensorSetupOverlayView(mapOffset: $mapOffset, size: $size, markers: $markers, sessionManager: sessionManager, isPresentingScanner: $isPresentingScanner, isConfirmingLocation: $isConfirmingLocation, selectedSensor: $selectedSensor, selectedDetector: $selectedDetector, sensorTapped: $sensorTapped, annotations: $annotations, pin: $pin)
                                .sheet(isPresented: $isPresentingScanner) {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            
                                            Text("Scan the QR code on your Torch device")
                                                .font(Font.custom("Manrope-Medium", fixedSize: 20))
                                                .foregroundColor(CustomColors.TorchGreen)
                                                .padding(.top, 20)
                                            
                                            Spacer()
                                        }
                                        
                                        CodeScannerView(codeTypes: [.qr], showViewfinder: true) { response in
                                            if case let .success(result) = response {
                                                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                                                impactMed.impactOccurred()
                                                
                                                print("Got device EUI: \(result.string)")
                                                isPresentingScanner = false
                                                
                                                // create detector model
                                                var detector = Detector(id: result.string, deviceName: String(sessionManager.newProperty!.detectors.count + 1), deviceBattery: 0.0, coordinate: nil, selected: true, sensorIdx: sessionManager.newProperty!.detectors.count + 1)
                                                sessionManager.addNewDetector(detector: detector)
                                                self.selectedSensor = detector
                                                self.selectedDetector = detector
                                                needsLocationPin = true
                                                // sessionManager.newProperty!.detectors.append(detector)
                                                
                                                let x =  print("Added, new detector count: \(sessionManager.newProperty!.detectors.count)")
                                            }
                                        }
                                        .ignoresSafeArea(.container)
                                    }
                                }
                        }
                    }
                    .animation(.easeInOut)
                }
                
                // Heading saying Set up torch sensors
                HStack {
                    Spacer()
                    
                    Text("Set up Torch sensors")
                        .font(Font.custom("Manrope-SemiBold", fixedSize: 20))
                        .foregroundColor(CustomColors.TorchGreen)
                        .padding(.top, 25)
                    
                    Spacer()
                }
                
                // Exit, layers, location button on right side
                HStack {
                    Spacer()
                    VStack(spacing: 1) {
                        ExitButton(showingOptions: $showingOptions)
                        
                        Spacer()
                            .frame(height: 150)
                        
                        //                        LayersButton()
                        //                        LocationButton()
                    }
                    .padding(.trailing, 10)
                    .padding(.top, 10)
                }
                
                VStack {
                    Spacer()
                    
                    //                    HStack {
                    //                        Spacer()
                    //
                    //                        LayersButton()
                    //                    }
                    //                    .padding(.trailing, 10)
                    
                    HStack {
                        Spacer()
                        
                        LocationButton(moveToUserTapped: $moveToUserTapped)
                    }
                    .padding(.trailing, 10)
                    .padding(.bottom, 10)
                    
                    Spacer()
                        .frame(height: self.size.height)
                }
                .opacity(isConfirmingLocation ? 0.0 : 1.0)
            }
            .confirmationDialog("Select a color", isPresented: $showingOptions, titleVisibility: .hidden) {
                Button("Save & Exit") {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    // Upload new detectors & return to properties view
                    if SessionManager.shared.selectedPropertyIndex < SessionManager.shared.properties.count {
                        SessionManager.shared.properties[SessionManager.shared.selectedPropertyIndex].loadingData = true
                    }
                    SessionManager.shared.newProperty!.loadingData = true
                    SessionManager.shared.uploadNewDetectors()
                    dismiss()
                    //                    SessionManager.shared.appState = .properties
                    SessionManager.shared.newProperty = nil
                }
                
                
                Button("Quit without saving", role: .destructive) {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    //                    SessionManager.shared.appState = .properties
                    SessionManager.shared.newProperty!.detectors = []
                    SessionManager.shared.properties[SessionManager.shared.selectedPropertyIndex].detectors = []
                    dismiss()
                    SessionManager.shared.newProperty = nil
                }
            }
        }
    }
}

//struct DeviceScanerView: View {
//    @State var isPresentingScanner: Bool
//
//
//    var body: some View {
//        CodeScannerView(codeTypes: [.qr]) { response in
//            if case let .success(result) = response {
//                // print(result.string)
//                isPresentingScanner = false
//            }
//        }
//    }
//}
//struct PlaceSensorView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaceSensorView()
//    }
//}
