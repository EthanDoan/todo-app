# Todo App (iOS)

A SwiftUI sample app that organizes personal tasks into focused workflows: **To Call**, **To Buy**, **To Sell**, and **Sync**. The home screen shows live counters for each area and routes you into dedicated flows for calling people, shopping, selling items, and managing sync jobs.

## Features

- **Home dashboard** with quick navigation and live counters for each workflow.
- **To Call** list with search, pagination, and manual refresh.
- **To Buy** catalog with search, sorting, max-price filtering, and wishlist toggling.
- **To Sell** inventory management with add/edit, bulk delete, undo, and sold status tracking.
- **Manual Sync** screen to review pending sync items and trigger a sync on demand.

## Architecture

The app is organized into `Presentation`, `Domain`, and `Data` layers.

- **Presentation**: SwiftUI views and view models for each workflow.
- **Domain**: Use cases and entities driving the business logic.
- **Data**: Repositories and storage/remote clients (in-memory stores, SQLite-backed stores, and mock API clients).

`AppContainer` wires dependencies together and starts background syncing for pending sell items.

## Getting Started

### Requirements

- Xcode 15 or newer
- iOS 17+ simulator or device

### Run the app

1. Open `todo-app.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Click **Run**.

### Run tests

From the repository root:

```bash
xcodebuild test -scheme todo-app -destination 'platform=iOS Simulator,name=iPhone 15'
```
