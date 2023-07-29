//
//  ScheduleView.swift
//  OPass
//
//  Created by 張智堯 on 2022/3/2.
//  2023 OPass.
//

import SwiftUI
import SwiftDate

struct ScheduleView: View {
    
    @ObservedObject var EventService: EventService
    @State private var selectDayIndex: Int
    @State private var filter = Filter.all
    @State private var isError = false
    @AppStorage("AutoSelectScheduleDay") var autoSelectScheduleDay = true
    
    init(EventService: EventService) {
        self.EventService = EventService
        if AppStorage(wrappedValue: true, "AutoSelectScheduleDay").wrappedValue {
            self.selectDayIndex = EventService.schedule?.sessions.count == 1 ? 0 : EventService.schedule?.sessions.firstIndex { $0.header[0].isToday } ?? 0
        } else { self.selectDayIndex = 0 }
    }
    
    var body: some View {
        VStack {
            if !isError {
                if let allScheduleData = EventService.schedule {
                    VStack(spacing: 0) {
                        if allScheduleData.sessions.count > 1 {
                            SelectDayView(selectDayIndex: $selectDayIndex, sessions: allScheduleData.sessions)
                                .background(Color("SectionBackgroundColor"))
                        }
                        
                        let filteredModel = allScheduleData.sessions[selectDayIndex].filter { session in
                            switch filter {
                            case .all: return true
                            case .liked: return EventService.liked_sessions.contains(session.id)
                            case .tag(let tag): return session.tags.contains(tag)
                            case .type(let type): return session.type == type
                            case .room(let room): return session.room == room
                            case .speaker(let speaker): return session.speakers.contains(speaker)
                            }
                        }
                        Form {
                            ForEach(filteredModel.header, id: \.self) { header in
                                Section {
                                    ForEach(filteredModel.data[header]!.sorted { $0.end < $1.end }, id: \.id) { detail in
                                        NavigationLink(value: Router.mainDestination.sessionDetail(detail)) {
                                            SessionOverView(
                                                room: EventService.schedule?.rooms[detail.room]?.localized().name ?? detail.room,
                                                start: detail.start,
                                                end: detail.end,
                                                title: detail.localized().title
                                            )
                                        }
                                    }
                                }
                                .listRowInsets(.init(top: 10, leading: 15, bottom: 10, trailing: 15))
                            }
                        }
                        .refreshable { try? await EventService.loadSchedule() }
                        .overlay {
                            if filteredModel.isEmpty {
                                VStack(alignment: .center) {
                                    Image(systemName: "text.badge.xmark")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color("LogoColor"))
                                        .frame(width: UIScreen.main.bounds.width * 0.15)
                                        .padding(.bottom)
                                    
                                    Text(LocalizedStringKey("NoFilteredEvent"))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView(LocalizedStringKey("Loading"))
                        .task { await ScheduleFirstLoad() }
                }
            } else {
                ErrorWithRetryView {
                    self.isError = false
                    Task { await ScheduleFirstLoad() }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(EventService.settings.feature(ofType: .schedule)?.display_text.localized() ?? "Schedule").font(.headline)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if let schedule = EventService.schedule {
                        NavigationLink(value: Router.mainDestination.scheduleSearch(schedule)) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
                    Menu {
                        Picker(selection: $filter, label: EmptyView()) {
                            Label("AllSessions", systemImage: "list.bullet")
                                .tag(Filter.all)
                            
                            Label("Favorite", systemImage: "heart\(filter == .liked ? ".fill" : "")")
                                .tag(Filter.liked)
                            
                            if let schedule = EventService.schedule, !schedule.tags.isEmpty {
                                Menu {
                                    Picker(selection: $filter, label: EmptyView()) {
                                        ForEach(schedule.tags.keys, id: \.self) { id in
                                            Text(schedule.tags[id]?.localized().name ?? id)
                                                .tag(Filter.tag(id))
                                        }
                                    }
                                } label: {
                                    Label("Tags", systemImage: {
                                        switch filter {
                                        case .tag(_):
                                            return "tag.fill"
                                        default:
                                            return "tag"
                                        }
                                    }())
                                }
                            }
                            
                            if let schedule = EventService.schedule, !schedule.types.isEmpty {
                                Menu {
                                    Picker(selection: $filter, label: EmptyView()) {
                                        ForEach(schedule.types.keys, id: \.self) { id in
                                            Text(schedule.types[id]?.localized().name ?? id)
                                                .tag(Filter.type(id))
                                        }
                                    }
                                } label: {
                                    Label("Types", systemImage: {
                                        switch filter {
                                        case .type(_):
                                            return "signpost.right.fill"
                                        default:
                                            return "signpost.right"
                                        }
                                    }())
                                }
                            }
                            
                            if let schedule = EventService.schedule, !schedule.rooms.isEmpty {
                                Menu {
                                    Picker(selection: $filter, label: EmptyView()) {
                                        ForEach(schedule.rooms.keys, id: \.self) { id in
                                            Text(schedule.rooms[id]?.localized().name ?? id)
                                                .tag(Filter.room(id))
                                        }
                                    }
                                } label: {
                                    Label("Places", systemImage: {
                                        switch filter {
                                        case .room(_): return "map.fill"
                                        default: return "map"
                                        }
                                    }())
                                }
                            }
                            
                            if let schedule = EventService.schedule, !schedule.speakers.isEmpty {
                                Menu {
                                    Picker(selection: $filter, label: EmptyView()) {
                                        ForEach(schedule.speakers.keys, id: \.self) { id in
                                            Text(schedule.speakers[id]?.localized().name ?? id)
                                                .tag(Filter.speaker(id))
                                        }
                                    }
                                } label: {
                                    Label("Speakers", systemImage: {
                                        switch filter {
                                        case .speaker(_): return "person.fill"
                                        default: return "person"
                                        }
                                    }())
                                }
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle\(filter == .all ? "" : ".fill")")
                    }
                }
            }
        }
    }
    
    private func ScheduleFirstLoad() async {
        do {
            try await EventService.loadSchedule()
            if EventService.schedule?.sessions.count ?? 0 > 1, autoSelectScheduleDay{
                self.selectDayIndex = EventService.schedule?.sessions.firstIndex { $0.header[0].isToday } ?? 0
            }
        }
        catch { isError = true }
    }
}

private enum Filter: Hashable {
    case all, liked
    case tag(String)
    case type(String)
    case room(String)
    case speaker(String)
}

private struct SelectDayView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectDayIndex: Int
    let sessions: [SessionModel]
    private let weekDayName: [LocalizedStringKey] = ["SUN", "MON", "TUE", "WEN", "THR", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ForEach(0 ..< sessions.count, id: \.self) { index in
                    Button {
                        self.selectDayIndex = index
                    } label: {
                        VStack(alignment: .center, spacing: 0) {
                            Text(weekDayName[sessions[index].header[0].weekday - 1])
                                .font(.system(.subheadline, design: .monospaced))
                            Text(String(sessions[index].header[0].day))
                                .font(.system(.body, design: .monospaced))
                        }
                        .foregroundColor(index == selectDayIndex ?
                                         (colorScheme == .dark ? Color.white : Color.white) :
                                            (colorScheme == .dark ? Color.white : Color.black))
                        .padding(8)
                        .background(Color.blue.opacity(index == selectDayIndex ? 1 : 0))
                        .cornerRadius(10)
                    }
                }
            }
            Divider().padding(.top, 13)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionOverView: View {
    
    @AppStorage("DimPastSession") var dimPastSession = true
    @AppStorage("PastSessionOpacity") var pastSessionOpacity: Double = 0.4
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
        .opacity(end.isBeforeDate(DateInRegion(), orEqual: true, granularity: .minute) && dimPastSession ? pastSessionOpacity : 1)
    }
}

#if DEBUG
struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView(EventService: OPassService.mock().currentEventAPI!)
            .environmentObject(OPassService.mock())
    }
}
#endif
