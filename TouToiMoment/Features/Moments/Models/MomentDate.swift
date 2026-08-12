import Foundation

/// A calendar day with no time-zone-dependent instant semantics.
nonisolated struct MomentDate: Codable, Hashable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(date: Date, calendar: Calendar = .current) {
        let gregorian = Self.gregorianCalendar(timeZone: calendar.timeZone)
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        self.init(
            year: components.year ?? 1970,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }

    var isValid: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        ).map {
            let value = calendar.dateComponents([.year, .month, .day], from: $0)
            return value.year == year && value.month == month && value.day == day
        } ?? false
    }

    func date(calendar: Calendar = .current) -> Date {
        Self.gregorianCalendar(timeZone: calendar.timeZone).date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        ) ?? Date(timeIntervalSince1970: 0)
    }

    private static func gregorianCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    func cardText(
        relativeTo referenceDate: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let value = date(calendar: calendar)
        let currentYear = calendar.component(.year, from: referenceDate)
        if year == currentYear {
            return value.formatted(
                Date.FormatStyle(date: .omitted, time: .omitted)
                    .month(.defaultDigits)
                    .day(.defaultDigits)
                    .locale(locale)
            )
        }
        return value.formatted(
            Date.FormatStyle(date: .omitted, time: .omitted)
                .year(.defaultDigits)
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(locale)
        )
    }

    static func < (lhs: MomentDate, rhs: MomentDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
