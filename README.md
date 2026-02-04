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

### Mock API/data setup

The app ships with in-memory mock data sources for **To-Call** and **To-Buy**, so there is no external API to configure.

- **To-Call**: `ToCallAPIClient` seeds an in-memory "server" with a list of people and simulates a streaming feed every 15 seconds. Edit the `seeds` array (names/phone numbers) or adjust the `streamInterval` if you want different mock data or timing. The mock server also supports pagination and search. (`todo-app/Data/Remote/ToCallAPIClient.swift`)
- **To-Buy**: `ToBuyAPIClient` loads a JSON payload embedded in `mockPayload` and emits new items on a timer. Update the JSON in `mockPayload` to change the catalog, or edit `realtimeItems` to control the live feed. (`todo-app/Data/Remote/ToBuyAPIClient.swift`)

No additional setup is required beyond running the app.

### Run the app

1. Open `todo-app.xcodeproj` in Xcode.
2. Select an iOS simulator or device.
3. Click **Run**.

### Run tests

From the repository root:

```bash
xcodebuild test -scheme todo-app -destination 'platform=iOS Simulator,name=iPhone 15'
```
