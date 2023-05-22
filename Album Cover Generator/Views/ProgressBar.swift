//
//  ProgressBar.swift
//  Album Cover Generator
//
//  Created by Rehan Parwani on 5/15/23.
//

import SwiftUI

struct ProgressBar: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var percent : Double
    var timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
//    @Binding var displayNextView : Bool
//    @Binding var generatePressed : Bool
    
    var primary = Color(red: 255/255, green: 200/255, blue: 200/255)
    var secondary = Color(red: 255/255, green: 215/255, blue: 202/255)
    var tertiary = Color(red: 255/255, green: 142/255, blue: 106/255)
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: UIScreen.main.bounds.width/1.05, height: UIScreen.main.bounds.height/22)
                .foregroundColor(.primary.opacity(0.15))
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .frame(width: UIScreen.main.bounds.width/1.05 * percent, height: UIScreen.main.bounds.height/22)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [secondary, primary, tertiary]), startPoint: .leading, endPoint: .trailing)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    )
                    .foregroundColor(.clear)
                Text("\(Int(percent * 100))%")
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .bold()
            }
        }
//        .onReceive(timer) { time in
//            withAnimation(.default) {
//                percent = percent + 5.0 / 100.0
//            }
//            if percent * 100 >= 100.0 {
//                timer.upstream.connect().cancel()
////                displayNextView = true
////                generatePressed = false
//            }
//        }
    }
}

