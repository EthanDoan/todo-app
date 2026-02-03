import SwiftUI

struct ToCallView: View {
    @StateObject private var viewModel: ToCallViewModel

    init(viewModel: ToCallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("To Call")
                .font(.largeTitle.bold())
            Text("Last synced: \(viewModel.lastSyncedAt?.description ?? "Never")")
                .font(.caption)
            List(viewModel.people) { person in
                VStack(alignment: .leading) {
                    Text(person.name)
                    Text(person.phoneNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if viewModel.hasNextPage {
                Button(action: { viewModel.loadNextPage() }) {
                    if viewModel.isLoadingNextPage {
                        ProgressView()
                    } else {
                        Text("Load more")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoadingNextPage)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            viewModel.loadFirstPage()
        }
    }
}
