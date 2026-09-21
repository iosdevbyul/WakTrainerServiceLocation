# WakTrainerServiceLocation

`WakTrainerServiceLocation` is a Swift Package that provides location-based workout tracking for WakTrainer.

It is responsible for collecting workout location updates, building route coordinates, processing static and dynamic workout locations, and rendering workout routes on a map.

## Features

- Workout location tracking
- Route coordinate collection
- Static workout location summary
- Dynamic workout pace segment processing
- Workout route map rendering
- Location permission handling through `TrisLocationKit`
- Async location update handling
- Unit tests for tracking behavior

## Architecture

```text
WakTrainerServiceLocation
        ↓
TrisLocationKit
        ↓
CoreLocation
```

`WakTrainerServiceLocation` does not manage `CLLocationManager` directly.  
Common CoreLocation behavior is delegated to `TrisLocationKit`, while this package focuses on workout-specific location logic.

## Requirements

- iOS 15+
- Swift 5.9+
- Xcode 15+

## Dependencies

- `WakTrainerCoreModels`
- `TrisLocationKit`

## Main Components

```text
Sources/WakTrainerServiceLocation
├── Services
│   └── LocationManager.swift
├── Processors
│   └── WorkoutLocationProcessor.swift
└── Views
    └── WorkoutMapView.swift
```

## Testing

The package uses `xcodebuild` for iOS Simulator tests.

```bash
xcodebuild \
  -scheme WakTrainerServiceLocation \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  test
```

GitHub Actions also runs build and test validation automatically on pushes and pull requests.
