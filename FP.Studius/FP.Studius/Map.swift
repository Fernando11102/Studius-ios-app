//
//  Map.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI
import MapKit

struct MapView: View {
    // MARK: - Types
    struct Building: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        // Optional description or label for static map labels
        let label: String

        static func == (lhs: Building, rhs: Building) -> Bool {
            lhs.name == rhs.name &&
            lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
    }

    // MARK: - Sample Data (Replace with your real campus data)
    // Update these coordinates to your campus center and buildings.
    private static let campusCenter = CLLocationCoordinate2D(latitude: 51.5162, longitude: -0.1439) // University of Westminster (Regent Street)

    private let buildings: [Building] = [
        Building(name: "Regent Street Campus", coordinate: .init(latitude: 51.5162, longitude: -0.1439), label: "Regent Street Campus"),
        Building(name: "Cavendish Campus",     coordinate: .init(latitude: 51.5202, longitude: -0.1426), label: "Cavendish Campus"),
        Building(name: "Marylebone Campus",    coordinate: .init(latitude: 51.5225, longitude: -0.1586), label: "Marylebone Campus")
    ]

    // MARK: - State
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MapView.campusCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.03)
        )
    )

    @State private var showNextClassHelp: Bool = false

    // Example next class helper content (replace with your schedule integration)
    private let nextClassBuilding = "Regent Street Campus"
    private let nextClassHelpText = "This class is on the 2nd floor at the end of the corridor. Look for Room 204B near the east stairwell."

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            mapContent
            controlsOverlay
        }
        .sheet(isPresented: $showNextClassHelp) {
            nextClassHelpSheet
                .presentationDetents([.medium, .large])
        }
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // Show the user's current location annotation if permission is granted
            UserAnnotation()

            // Simple building markers
            ForEach(buildings) { building in
                Marker(building.name, systemImage: "building.2", coordinate: building.coordinate)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
    }

    private var controlsOverlay: some View {
        VStack(spacing: 8) {
            HStack {
                // "Where am I" button that centers on the user's location
                MapUserLocationButton()
                    .labelStyle(.titleAndIcon)
                    .buttonBorderShape(.capsule)
                    .tint(.accentColor)
                    .controlSize(.large)

                Spacer()

                // Next class helper button
                Button {
                    // Optionally, center the map on the next class building
                    if let building = buildings.first(where: { $0.name == nextClassBuilding }) {
                        withAnimation(.easeInOut) {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: building.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025)
                            ))
                        }
                    }
                    showNextClassHelp = true
                } label: {
                    Label("Next Class Help", systemImage: "questionmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private var nextClassHelpSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.tint)
                Text("Next Class: \(nextClassBuilding)")
                    .font(.headline)
                Spacer()
            }

            Text(nextClassHelpText)
                .font(.body)

            Divider()

            // Simple hints to navigate within the building
            VStack(alignment: .leading, spacing: 8) {
                Label("Enter via the main entrance.", systemImage: "door.left.hand.open")
                Label("Take the east stairwell to floor 2.", systemImage: "stairs")
                Label("Follow corridor to the end; Room 204B is on the right.", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }
            .font(.subheadline)

            Spacer()

            Button {
                showNextClassHelp = false
            } label: {
                Text("Got it")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    MapView()
}
