# TrisCalendarKit

`TrisCalendarKit` is a reusable SwiftUI calendar package for iOS.

It provides:

- A full month calendar
- A horizontally scrollable date strip
- Limited and infinite date strip ranges
- Date selection
- Highlighted dates
- Custom locale and time zone support
- Configurable week start
- Customizable calendar styling
- Month navigation
- Displayed date change callbacks

`TrisCalendarKit` is designed to stay independent from application-specific domains such as workouts, schedules, events, databases, or networking.

The package only handles calendar presentation and date interaction.  
The host application decides what each date represents.

---

## Requirements

- iOS 15+
- Swift
- SwiftUI

---

## Installation

### Swift Package Manager

Add `TrisCalendarKit` as a Swift Package dependency in Xcode.

```text
File
→ Add Package Dependencies...
```

For local development, you can also add the package using:

```text
Add Local...
```

and select the `TrisCalendarKit` package directory.

Then import the package:

```swift
import TrisCalendarKit
```

---

# Month Calendar

`MonthCalendarView` displays a complete month including adjacent month dates when enabled.

```swift
import SwiftUI
import TrisCalendarKit

struct ContentView: View {
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?

    var body: some View {
        MonthCalendarView(
            displayedMonth: $displayedMonth,
            selectedDate: $selectedDate
        )
    }
}
```

The displayed month can also be changed externally.

```swift
Button("Today") {
    displayedMonth = Date()
    selectedDate = Date()
}
```

---

## Highlight Dates

Highlighted dates can be passed using a `Set<Date>`.

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    highlightedDates: highlightedDates
)
```

For example:

```swift
private var highlightedDates: Set<Date> {
    let calendar = Calendar.current

    return Set(
        [
            calendar.date(
                byAdding: .day,
                value: -2,
                to: Date()
            ),
            calendar.date(
                byAdding: .day,
                value: -5,
                to: Date()
            )
        ]
        .compactMap { $0 }
    )
}
```

`TrisCalendarKit` compares highlighted dates by calendar day, so the time component does not need to match exactly.

---

# Date Strip Calendar

`DateStripCalendarView` displays a horizontally scrollable row of dates.

By default, seven dates are visible at once.

The scroll behavior is continuous rather than page-based.

A short drag moves the calendar slightly, while a fast swipe uses the natural scroll momentum.

```swift
@State private var displayedDate = Date()
@State private var selectedDate: Date?
```

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate
)
```

---

# Infinite Date Strip

The default date strip range is infinite.

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate,
    range: .infinite
)
```

The infinite date strip uses a virtual scrolling strategy internally.

It does not create an unlimited number of dates in memory.

Instead, the calendar recenters its internal range while preserving the date currently visible to the user.

This allows continuous scrolling toward both past and future dates.

```text
← Past                                Future →
```

---

# Limited Date Strip

The date strip can also be restricted to a finite range.

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate,
    range: .limited(
        pastDays: 365,
        futureDays: 30
    )
)
```

This example allows:

```text
365 days before the reference date
30 days after the reference date
```

The limited implementation uses a SwiftUI horizontal `ScrollView`.

---

# Date Selection

Both calendar types provide a date selection callback.

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    onSelectDate: { date in
        print("Selected:", date)
    }
)
```

The same API is available for `DateStripCalendarView`.

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate,
    onSelectDate: { date in
        print("Selected:", date)
    }
)
```

---

# Displayed Date Changes

The date strip distinguishes between:

```text
selectedDate
→ The date explicitly selected by the user

displayedDate
→ The date currently positioned near the center of the visible date strip
```

The displayed date can be observed with:

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate,
    onDisplayedDateChange: { date in
        print("Displayed:", date)
    }
)
```

This can be useful when loading date-dependent application data.

For example:

```swift
onDisplayedDateChange: { date in
    viewModel.loadRecords(for: date)
}
```

---

# Month Changes

`MonthCalendarView` provides a callback when the displayed month changes.

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    onDisplayedMonthChange: { month in
        print("Displayed month:", month)
    }
)
```

Applications can use this callback to load monthly data without coupling the calendar package to networking or persistence.

---

# Calendar Configuration

Calendar behavior can be configured using `CalendarConfiguration`.

```swift
let configuration = CalendarConfiguration(
    locale: .korea,
    timeZone: .seoul,
    weekStart: .sunday
)
```

Then pass it to a calendar view.

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    configuration: configuration
)
```

The same configuration can be reused across all calendar views.

---

## Locale

Built-in locale presets include:

```swift
.system
.korea
.unitedStates
.japan
.unitedKingdom
```

Example:

```swift
CalendarConfiguration(
    locale: .unitedStates
)
```

Custom Foundation locales are also supported.

```swift
CalendarConfiguration(
    locale: .custom(
        Locale(identifier: "fr_FR")
    )
)
```

---

## Time Zone

Built-in time zone presets include:

```swift
.system
.seoul
.losAngeles
.newYork
.london
.tokyo
```

Example:

```swift
CalendarConfiguration(
    timeZone: .losAngeles
)
```

Custom Foundation time zones are also supported.

```swift
CalendarConfiguration(
    timeZone: .custom(
        TimeZone(
            identifier: "Europe/Paris"
        ) ?? .current
    )
)
```

Locale and time zone are independent.

For example, an application can display Korean localized calendar text while using Los Angeles as the calendar time zone.

```swift
CalendarConfiguration(
    locale: .korea,
    timeZone: .losAngeles
)
```

---

# Week Start

The first day of the week can be configured.

```swift
CalendarConfiguration(
    weekStart: .sunday
)
```

or:

```swift
CalendarConfiguration(
    weekStart: .monday
)
```

The system setting can also be used.

```swift
CalendarConfiguration(
    weekStart: .system
)
```

The month calendar weekday header automatically follows this setting.

---

# Styling

`CalendarStyle` controls the visual appearance of the calendar.

```swift
let style = CalendarStyle(
    selectedBackgroundColor: .black,
    selectedTextColor: .white,
    highlightedBackgroundColor: .orange.opacity(0.2),
    currentMonthTextColor: .primary,
    adjacentMonthTextColor: .secondary,
    todayBorderColor: .blue,
    dayFont: .system(
        size: 16,
        weight: .semibold
    ),
    weekdayFont: .caption,
    headerFont: .title3.bold(),
    dayCellSize: 44,
    dayRowSpacing: 12,
    sectionSpacing: 16
)
```

Apply the style:

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    style: style
)
```

The same style can be reused with `DateStripCalendarView`.

---

# Month Calendar Options

Month-specific display behavior can be controlled with `MonthCalendarOptions`.

```swift
MonthCalendarOptions(
    showsNavigationButtons: true,
    showsAdjacentMonthDates: true
)
```

Example:

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    options: MonthCalendarOptions(
        showsNavigationButtons: false,
        showsAdjacentMonthDates: false
    )
)
```

---

# Adjacent Month Selection

When adjacent month dates are visible, their selection behavior can be configured.

### Navigate

Selecting an adjacent date automatically changes the displayed month.

```swift
adjacentMonthSelectionBehavior: .navigate
```

### Select Only

Selecting an adjacent date changes the selected date but keeps the currently displayed month.

```swift
adjacentMonthSelectionBehavior: .selectOnly
```

Example:

```swift
MonthCalendarView(
    displayedMonth: $displayedMonth,
    selectedDate: $selectedDate,
    adjacentMonthSelectionBehavior: .navigate
)
```

---

# Date Strip Options

The number of dates visible at once can be customized.

```swift
DateStripCalendarOptions(
    visibleDayCount: 7
)
```

For example:

```swift
DateStripCalendarView(
    displayedDate: $displayedDate,
    selectedDate: $selectedDate,
    options: DateStripCalendarOptions(
        visibleDayCount: 5
    )
)
```

This displays five dates across the available width.

---

# Example

A typical configuration:

```swift
import SwiftUI
import TrisCalendarKit

struct ContentView: View {
    @State private var displayedMonth = Date()
    @State private var selectedMonthDate: Date?

    @State private var displayedDate = Date()
    @State private var selectedDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                MonthCalendarView(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedMonthDate,
                    highlightedDates: highlightedDates,
                    configuration: calendarConfiguration
                )

                DateStripCalendarView(
                    displayedDate: $displayedDate,
                    selectedDate: $selectedDate,
                    range: .infinite,
                    highlightedDates: highlightedDates,
                    configuration: calendarConfiguration
                )
            }
            .padding()
        }
    }

    private var calendarConfiguration: CalendarConfiguration {
        CalendarConfiguration(
            locale: .korea,
            timeZone: .seoul,
            weekStart: .sunday
        )
    }

    private var highlightedDates: Set<Date> {
        let calendar = Calendar.current

        return Set(
            [
                calendar.date(
                    byAdding: .day,
                    value: -2,
                    to: Date()
                ),
                calendar.date(
                    byAdding: .day,
                    value: -5,
                    to: Date()
                )
            ]
            .compactMap { $0 }
        )
    }
}
```

---

# Architecture

`TrisCalendarKit` intentionally keeps application-specific business logic outside the package.

```text
Application
│
├── Workout
├── Schedule
├── Health
├── Server
├── SwiftData / Realm
│
└── TrisCalendarKit
        │
        ├── CalendarConfiguration
        ├── CalendarStyle
        ├── MonthCalendarView
        └── DateStripCalendarView
```

The package does not know whether a highlighted date represents:

```text
Workout
Schedule
Sleep
Health Record
Event
Reminder
```

The host application provides dates and handles selection callbacks.

This keeps `TrisCalendarKit` reusable across different applications.

---

# Internal Date Strip Strategies

`DateStripCalendarView` exposes a single public API while selecting the appropriate implementation internally.

```text
DateStripCalendarView
│
├── .limited
│       └── SwiftUI ScrollView
│
└── .infinite
        └── UICollectionView
            └── Virtual range recentering
```

This keeps the public API simple while allowing the infinite implementation to use a more appropriate scrolling strategy.

---

# Testing

The package includes tests for:

- Month generation
- Adjacent month dates
- Sunday and Monday week starts
- Leap years
- Month boundaries
- Year boundaries
- Continuous date generation
- Date normalization
- Highlight lookup
- Infinite date index mapping
- Infinite date offsets
- Infinite recenter thresholds

Run tests using:

```bash
swift test
```

---

# Public API

Primary public views:

```swift
MonthCalendarView
DateStripCalendarView
```

Configuration types:

```swift
CalendarConfiguration
CalendarLocale
CalendarTimeZone
CalendarWeekStart
CalendarStyle

MonthCalendarOptions
AdjacentMonthSelectionBehavior

DateStripRange
DateStripCalendarOptions
```

Implementation-specific calendar types remain internal to the package.

---

# Design Goals

`TrisCalendarKit` is designed around the following principles:

- Reusable across multiple applications
- Independent from application business logic
- SwiftUI-first public API
- iOS 15+ support
- Configurable locale and time zone
- Customizable appearance
- Testable date calculation logic
- Natural horizontal scrolling
- Simple public API
- Separate internal strategies for finite and infinite scrolling

---

# License

Add the license used by your project here.
