# watchOS Start

This repo now includes a watch-first scaffold in `/DrinkyPooWatch` plus shared
SwiftData setup in `/DrinkyPoo/Shared`.

## What is ready

- Shared SwiftData + CloudKit container factory
- Shared stats snapshot calculation for watch-friendly screens
- Minimal watch home screen for:
  - logging today as dry or drinking
  - clearing today's entry
  - viewing current streaks
  - viewing the last 7 days

## What still needs Xcode target wiring

1. Add a new `watchOS App` target named `DrinkyPooWatch`.
2. Point the target's bundle identifier at something like
   `com.golackey.DrinkyPoo.watchkitapp`.
3. Include these source folders in the watch target:
   - `/DrinkyPooWatch`
   - `/DrinkyPoo/Models`
   - `/DrinkyPoo/Shared`
4. Enable the same iCloud/CloudKit container:
   - `iCloud.com.golackey.DrinkyPoo`
5. Keep the watch UI focused on "today" instead of mirroring the iPhone tabs.

## Known follow-up

`@AppStorage` values do not automatically sync between the iPhone app and watch.
If we want shared goals/reminder settings next, the clean follow-up is moving
those preferences into an app group or a small explicit sync layer.
