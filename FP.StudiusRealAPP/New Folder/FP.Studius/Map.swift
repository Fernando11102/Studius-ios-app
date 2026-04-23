//
//  Map.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI
import MapKit

struct MapView: View {
    @Environment(AppDataStore.self) private var store

    private struct CampusLocation: Identifiable {
        let id: String
        let name: String
        let coordinate: CLLocationCoordinate2D
        let subtitle: String
    }

    private struct CavendishSpot: Identifiable {
        let id: String
        let title: String
        let floor: String
        let systemImage: String
        let note: String
        let direction: String
        let accent: Color
    }

    private enum MapTheme {
        static let background = Color(red: 0.81, green: 0.76, blue: 0.67)
        static let card = Color(red: 0.94, green: 0.88, blue: 0.80)
        static let darkCard = Color(red: 0.36, green: 0.28, blue: 0.20)
        static let softCard = Color.white.opacity(0.62)
    }
    
    private static let cavendishCoordinate = CLLocationCoordinate2D(latitude: 51.5202, longitude: -0.1426)

    // The map shows the main Westminster campuses, then focuses the guide on Cavendish.
    private static let campusLocations: [CampusLocation] = [
        CampusLocation(
            id: "cavendish",
            name: "Cavendish Campus",
            coordinate: cavendishCoordinate,
            subtitle: "Main student building"
        ),
        CampusLocation(
            id: "regent",
            name: "Regent Street Campus",
            coordinate: .init(latitude: 51.5162, longitude: -0.1439),
            subtitle: "Regent Street"
        ),
        CampusLocation(
            id: "marylebone",
            name: "Marylebone Campus",
            coordinate: .init(latitude: 51.5225, longitude: -0.1586),
            subtitle: "Marylebone"
        )
    ]

    // These are the quick indoor places used by the guide cards and assistant map commands.
    private static let cavendishSpots: [CavendishSpot] = [
        CavendishSpot(
            id: "cafeteria",
            title: "Cafeteria",
            floor: "1st floor",
            systemImage: "fork.knife.circle.fill",
            note: "Good place for a quick lunch, coffee, or a break between lectures.",
            direction: "Enter Cavendish, stay on the first floor, then follow the main corridor towards the food area.",
            accent: Color(red: 0.72, green: 0.42, blue: 0.24)
        ),
        CavendishSpot(
            id: "social",
            title: "Social Area",
            floor: "1st floor",
            systemImage: "person.3.fill",
            note: "Useful for meeting classmates, checking notes, or waiting before a lab.",
            direction: "When you reach the cafeteria on the first floor, turn right. The social area is next to it.",
            accent: Color(red: 0.32, green: 0.48, blue: 0.56)
        ),
        CavendishSpot(
            id: "room-2110",
            title: "Room 2/110",
            floor: "2nd floor",
            systemImage: "door.right.hand.open",
            note: "A regular teaching room for classes and seminars.",
            direction: "Go to the second floor and look for room 110 in the main teaching-room corridor.",
            accent: Color(red: 0.45, green: 0.36, blue: 0.62)
        ),
        CavendishSpot(
            id: "library",
            title: "Library",
            floor: "3rd floor",
            systemImage: "books.vertical.fill",
            note: "Best for quiet study, research, and finishing coursework.",
            direction: "Take the stairs or lift to the third floor. Follow the signs towards the study area.",
            accent: Color(red: 0.40, green: 0.52, blue: 0.35)
        ),
        CavendishSpot(
            id: "room-3119",
            title: "Room 3/119",
            floor: "3rd floor",
            systemImage: "signpost.right.fill",
            note: "Third-floor classroom, usually easier to find if you keep going to the end.",
            direction: "Go to the third floor and continue to the end of the corridor. Room 119 is there.",
            accent: Color(red: 0.36, green: 0.41, blue: 0.68)
        ),
        CavendishSpot(
            id: "room-4118",
            title: "Room 4/118",
            floor: "4th floor",
            systemImage: "laptopcomputer",
            note: "iOS development labs and practical coding sessions.",
            direction: "Head to the fourth floor and follow the lab signs. Room 118 is the iOS development lab.",
            accent: Color(red: 0.26, green: 0.50, blue: 0.44)
        )
    ]

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MapView.cavendishCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.009, longitudeDelta: 0.009)
        )
    )
    var body: some View {
        NavigationStack {
            ZStack {
                MapTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    mapContent
                        .frame(height: 315)
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                    
                    guideContent
                }
            }
            .navigationTitle("Cavendish")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(MapTheme.darkCard)
    }

    private var mapContent: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                ForEach(Self.campusLocations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        CampusMarker(location: location, isMain: location.id == "cavendish")
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            
            VStack(spacing: 12) {
                headerCard
                
                HStack {
                    MapUserLocationButton()
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                    
                    Spacer()
                    
                    Button {
                        focusOnCavendish()
                    } label: {
                        Label("Focus", systemImage: "location.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(MapTheme.darkCard)
                }
            }
            .padding()
        }
    }
    
    private var headerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.columns.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.18), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cavendish student guide")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Food, study spaces and rooms without the awkward wandering.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(MapTheme.darkCard.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
    
    private var guideContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                selectedSpotCard
                floorSelector
                quickRooms
            }
            .padding()
            .padding(.bottom, 12)
        }
    }
    
    private var selectedSpot: CavendishSpot {
        Self.cavendishSpots.first { $0.id == store.selectedMapSpotID } ?? Self.cavendishSpots[0]
    }
    
    private var selectedSpotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedSpot.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(selectedSpot.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedSpot.title)
                        .font(.title3.bold())
                        .foregroundStyle(MapTheme.darkCard)
                    
                    Text(selectedSpot.floor)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedSpot.accent, in: Capsule())
                }
                
                Spacer()
            }
            
            Text(selectedSpot.note)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Label(selectedSpot.direction, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MapTheme.darkCard)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.56))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding()
        .background(MapTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
    
    private var floorSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cavendish places", systemImage: "square.grid.2x2.fill")
                .font(.headline)
                .foregroundStyle(MapTheme.darkCard)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Self.cavendishSpots) { spot in
                    Button {
                        store.selectedMapSpotID = spot.id
                        focusOnCavendish()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: spot.systemImage)
                                    .foregroundStyle(store.selectedMapSpotID == spot.id ? .white : spot.accent)
                                Spacer()
                                Text(spot.floor)
                                    .font(.caption2.weight(.semibold))
                            }
                            
                            Text(spot.title)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
                        .padding(12)
                        .foregroundStyle(store.selectedMapSpotID == spot.id ? .white : MapTheme.darkCard)
                        .background(store.selectedMapSpotID == spot.id ? MapTheme.darkCard : MapTheme.softCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(MapTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
    
    private var quickRooms: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Room shortcuts", systemImage: "door.left.hand.open")
                .font(.headline)
                .foregroundStyle(MapTheme.darkCard)
            
            roomHint(room: "2/110", detail: "Second floor. Look for room 110 in the teaching-room corridor.")
            roomHint(room: "3/119", detail: "Third floor. Keep walking to the end of the corridor.")
            roomHint(room: "4/118", detail: "Fourth floor lab. Used for iOS development practical sessions.")
        }
        .padding()
        .background(MapTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
    
    private func roomHint(room: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(room)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 36)
                .background(MapTheme.darkCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(12)
        .background(MapTheme.softCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func focusOnCavendish() {
        withAnimation(.easeInOut) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: Self.cavendishCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                )
            )
        }
    }
    
    private struct CampusMarker: View {
        let location: CampusLocation
        let isMain: Bool
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: isMain ? "graduationcap.fill" : "building.2.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: isMain ? 42 : 34, height: isMain ? 42 : 34)
                    .background(isMain ? MapTheme.darkCard : Color.secondary, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                
                VStack(spacing: 2) {
                    Text(location.name)
                        .font(.caption.bold())
                    Text(location.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

#Preview {
    MapView()
        .environment(AppDataStore())
}
