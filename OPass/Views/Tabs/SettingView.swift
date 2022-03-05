//
//  SettingView.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/2.
//

import SwiftUI

struct SettingView: View {
    
    @ObservedObject var eventAPI: EventAPIViewModel
    
    var body: some View {
        //Only for API Testing
        VStack {
            if let data = eventAPI.eventLogo, let uiimage = UIImage(data: data) {
                Image(uiImage: uiimage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .frame(width: UIScreen.main.bounds.width * 0.78, height: UIScreen.main.bounds.width * 0.4)
                    .background(Color.purple)
            }
            
            Text(eventAPI.eventSettings?.event_id ?? "No Current Event Data")
            
            ScrollView {
                if let data = eventAPI.eventSettings {
                    ForEach(data.features, id: \.self) { feature in
                        Text(feature.display_text.zh)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(eventAPI: OPassAPIViewModel.mock().eventList[5])
            .environmentObject(OPassAPIViewModel.mock())
    }
}
#endif