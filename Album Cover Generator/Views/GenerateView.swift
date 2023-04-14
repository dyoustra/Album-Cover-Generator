//
//  GenerateView.swift
//  Album Cover Generator
//
//  Created by Danny Youstra on 4/13/23.
//

import SwiftUI

enum GenerationOptions: String, CaseIterable, Identifiable {
    case Song_Titles
    case Song_Duration
    case Album_Name
    /// Name of the creator of the Album, or the creator of the playlist
    case Artist_Name
    /// Names of the individual song artists. Used only for playlists
    case Song_Artist_Names
    /// Album Covers of the individual songs. Used only for playlists.
    case Song_Album_Covers
    
    func playlistOnly() -> Bool {
        switch self {
                case .Song_Duration,
                     .Song_Album_Covers:
                return true
            default:
                return false
        }
    }
    
    func ordinal() -> Int {
        return Self.allCases.firstIndex(of: self)!
    }
    
    var id: Self {
        self
    }
}

struct GenerateView: View {
    
    let coverImage: Image
    
    @State private var toggles: [Bool] = [false, false, false, false, false, false, false]
    
    var body: some View {
        ScrollView {
            VStack {
                coverImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
                    .shadow(radius: 20)
                Text("Album Name")
                    .font(.largeTitle)
                    .bold()
                HStack {
                    AsyncImage(url: URL(string: "https://illustoon.com/photo/thum/7431.png")) { image in
                        image
                            .resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                    }
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    Text("Artist Name")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary)
                }
                .frame(height: 30)
            }
            .padding(.all)
            List {
                ForEach(GenerationOptions.allCases.filter({ option in
                    !option.playlistOnly()
                })) { option in
                    Toggle(isOn: $toggles[option.ordinal()]) {
                        Text(option.rawValue.replacingOccurrences(of: "_", with: " "))
                    }
                }
            }
            .scaledToFit()
            .listStyle(.plain)
        }
//        .navigationTitle("Generate Album")
    }
}

struct GenerateView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GenerateView(coverImage: Image(systemName: "square.fill"))
        }
    }
}
