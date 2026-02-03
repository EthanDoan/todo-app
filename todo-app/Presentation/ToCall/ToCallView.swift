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
            Text("Total people: \(viewModel.people.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            List {
                ForEach(viewModel.people) { person in
                    VStack(alignment: .leading) {
                        Text(person.name)
                        Text(person.phoneNumber)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentItem: person)
                    }
                }
                if !viewModel.hasNextPage && !viewModel.people.isEmpty {
                    Text("No more people to load.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            viewModel.loadFirstPage()
        }
    }
}
