import SwiftUI

struct SyncView: View {
    @StateObject private var viewModel: SyncViewModel

    init(viewModel: SyncViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Manual Sync")
                .font(.largeTitle.bold())
            Text("Pending: \(viewModel.pendingItems.count)")
                .font(.headline)
            Button("Sync Now") {
                viewModel.syncNow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Sync")
    }
}
