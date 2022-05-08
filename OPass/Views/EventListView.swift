//
//  EventListView.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/1.
//  2022 OPass.
//

import SwiftUI

struct EventListView: View {
    
    @EnvironmentObject var OPassAPI: OPassAPIViewModel
    @Environment(\.dismiss) var dismiss
    @State var isError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !isError {
                    if !OPassAPI.eventList.isEmpty {
                        Form {
                            ForEach(OPassAPI.eventList, id: \.event_id) { list in
                                Button(action: {
                                    OPassAPI.currentEventID = list.event_id
                                    dismiss()
                                }) {
                                    HStack {
                                        AsyncImage(url: URL(string: list.logo_url)) { Image in
                                            Image
                                                .renderingMode(.template)
                                                .resizable().aspectRatio(contentMode: .fit)
                                                .foregroundColor(Color("LogoColor"))
                                        } placeholder: {
                                            Rectangle().hidden()
                                        }
                                        .padding(.horizontal, 3)
                                        .frame(width: UIScreen.main.bounds.width * 0.25, height: UIScreen.main.bounds.width * 0.15)
                                        
                                        Text(LocalizeIn(zh: list.display_name.zh, en: list.display_name.en))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    } else { ProgressView("Loading") }
                } else {
                    ErrorWithRetryView {
                        self.isError = false
                        Task {
                            do { try await self.OPassAPI.loadEventList() }
                            catch { self.isError = true }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("SelectEvent"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if OPassAPI.currentEventAPI != nil {
                        Button(LocalizedStringKey("Close")) {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SFButton(systemName: "arrow.clockwise") {
                        self.isError = false
                        Task {
                            do { try await self.OPassAPI.loadEventList() }
                            catch {
                                if self.OPassAPI.eventList.isEmpty { self.isError = true }
                            }
                        }
                    }
                }
            }
        }
        .task {
            do { try await OPassAPI.loadEventList() }
            catch { isError = true }
        }
        .interactiveDismissDisabled(OPassAPI.currentEventID == nil)
    }
}

#if DEBUG
struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventListView()
                .environmentObject(OPassAPIViewModel.mock())
        }
        .navigationTitle(LocalizedStringKey("SelectEvent"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedStringKey("Close")) {}
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                SFButton(systemName: "arrow.clockwise") {}
            }
        }
    }
}
#endif
