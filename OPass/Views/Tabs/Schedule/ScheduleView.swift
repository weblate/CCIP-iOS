//
//  SessionView.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/2.
//  2022 OPass.
//

import SwiftUI
import SwiftDate

struct ScheduleView: View {
    
    @ObservedObject var eventAPI: EventAPIViewModel
    @State var selectDayIndex = 0
    @State var filterIndex = 0
    
    var body: some View {
        VStack {
            if let allScheduleData = eventAPI.eventSchedule {
                VStack(spacing: 0) {
                    if allScheduleData.sessions.section.count > 1 {
                        SelectDayView(selectDayIndex: $selectDayIndex, section: allScheduleData.sessions.section)
                    }
                    
                    Form {
                        switch filterIndex {
                        case 1:
                            FavoriteSessionView(eventAPI: eventAPI, sessionData: allScheduleData.sessions.data)
                        case 2:
                            VStack{} //TODO: Tag filter
                        default: //0
                            AllSessionView(allScheduleData: allScheduleData, selectDayIndex: selectDayIndex, eventAPI: eventAPI)
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            await eventAPI.loadSchedule() //TODO: need optimize
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker(selection: $filterIndex, label: EmptyView()) {
                        HStack {
                            Text("所有議程")
                            Spacer()
                            Image(systemName: "list.bullet")
                        }
                        .tag(0)
                        HStack {
                            Text("喜歡")
                            Spacer()
                            Image(systemName: "heart\(filterIndex == 1 ? ".fill" : "")")
                        }
                        .tag(1)
                        HStack {
                            Text("標籤")
                            Spacer()
                            Image(systemName: "tag\(filterIndex == 2 ? ".fill" : "")")
                        }
                        .tag(2)
                    }
                    .labelsHidden()
                    .pickerStyle(.inline)
                } label: {
                    SFButton(systemName: "line.3.horizontal.decrease.circle\(filterIndex == 0 ? "" : ".fill")") {

                    }
                }
            }
        }
    }
}

fileprivate struct AllSessionView: View {
    
    let allScheduleData: ScheduleModel
    let selectDayIndex: Int
    @ObservedObject var eventAPI: EventAPIViewModel
    
    var body: some View {
        ForEach(allScheduleData.sessions.section[selectDayIndex].header, id: \.self) { header in
            Section {
                ForEach(allScheduleData.sessions.section[selectDayIndex].sessionId[header] ?? [], id: \.self) { sessionId in
                    if let sessionDetail = allScheduleData.sessions.data[sessionId] {
                        if sessionDetail.type != "Ev" {
                            NavigationLink(destination:
                                            ScheduleDetailView(eventAPI: eventAPI, scheduleDetail: sessionDetail)
                            ){
                                DetailOverView(room: (eventAPI.eventSchedule?.rooms[sessionDetail.room]?.zh.name ?? sessionDetail.room),
                                               start: sessionDetail.start,
                                               end: sessionDetail.end,
                                               title: sessionDetail.zh.title)
                            }
                        } else {
                            DetailOverView(room: (eventAPI.eventSchedule?.rooms[sessionDetail.room]?.zh.name ?? sessionDetail.room),
                                           start: sessionDetail.start,
                                           end: sessionDetail.end,
                                           title: sessionDetail.zh.title)
                        }
                    }
                }
            }
            .listRowInsets(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
        }
    }
}

fileprivate struct FavoriteSessionView: View {
    
    let sessionData: [String : SessionDataModel]
    @AppStorage var likedSessions: [String]
    @ObservedObject var eventAPI: EventAPIViewModel
    
    init(eventAPI: EventAPIViewModel, sessionData: [String : SessionDataModel]) {
        self.sessionData = sessionData
        _eventAPI = ObservedObject(wrappedValue: eventAPI)
        _likedSessions = AppStorage(wrappedValue: [], "liked_sessions", store: UserDefaults(suiteName: eventAPI.event_id))
    }
    
    var body: some View {
        ForEach(sessionData.filter {likedSessions.contains($0.key)}.sorted(by: {$0.value.start < $1.value.start}), id: \.key) { _, sessionDetail in
            if sessionDetail.type != "Ev" {
                NavigationLink(destination:
                                ScheduleDetailView(eventAPI: eventAPI, scheduleDetail: sessionDetail)
                ){
                    DetailOverView(room: (eventAPI.eventSchedule?.rooms[sessionDetail.room]?.zh.name ?? sessionDetail.room),
                                   start: sessionDetail.start,
                                   end: sessionDetail.end,
                                   title: sessionDetail.zh.title)
                }
            } else {
                DetailOverView(room: (eventAPI.eventSchedule?.rooms[sessionDetail.room]?.zh.name ?? sessionDetail.room),
                               start: sessionDetail.start,
                               end: sessionDetail.end,
                               title: sessionDetail.zh.title)
            }
        }
    }
}

fileprivate struct SelectDayView: View {
    @Binding var selectDayIndex: Int
    let weekDayName = ["Mon", "Tue", "Wen", "Thr", "Fri", "Sat", "Sun"]
    let section: [SectionModel]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(0 ..< section.count, id: \.self) { index in
                    Button(action: {
                        selectDayIndex = index
                    }) {
                        VStack {
                            Text(
                                String(weekDayName[section[index].header[0].weekday - 1])
                                + "\n" +
                                String(section[index].header[0].day)
                            )
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(index == selectDayIndex ? Color.white : Color.black)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(index == selectDayIndex ? 1 : 0))
                        .cornerRadius(10)
                    }
                }
            }
            Divider().padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

fileprivate struct DetailOverView: View {
    
    let room: String,
        start: DateInRegion,
        end: DateInRegion,
        title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack() {
                Text(room)
                    .font(.caption2)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 8)
                    .foregroundColor(.white)
                    .background(.blue)
                    .cornerRadius(5)
                
                Text(String(format: "%d:%02d ~ %d:%02d", start.hour, start.minute, end.hour, end.minute))
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            Text(title)
                .lineLimit(2)
        }
    }
}

#if DEBUG
struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView(eventAPI: OPassAPIViewModel.mock().eventList[5])
            .environmentObject(OPassAPIViewModel.mock())
    }
}
#endif
