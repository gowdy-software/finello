import SwiftUI
import FinelloKit

struct MonthView: View {
    let posts: [Post]
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 6) {
            WeekdayHeader()
            VStack(spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 6) {
                        ForEach(week, id: \.date) { day in
                            DayCell(
                                day: day,
                                posts: app.posts(on: day.date, within: posts),
                                isToday: app.calendar.isDate(day.date, inSameDayAs: app.today)
                            )
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .padding(12)
    }

    private var weeks: [[GridDay]] {
        stride(from: 0, to: grid.count, by: 7).map { Array(grid[$0..<min($0 + 7, grid.count)]) }
    }

    private var grid: [GridDay] {
        app.layout.monthGrid(containing: app.anchor)
    }
}

struct WeekdayHeader: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        HStack(spacing: 6) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var symbols: [String] { DateText.weekdaySymbols(calendar: app.calendar) }
}
