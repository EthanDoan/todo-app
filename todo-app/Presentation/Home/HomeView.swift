import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let toCallDestination: AnyView
    let toBuyDestination: AnyView
    let toSellDestination: AnyView
    let syncDestination: AnyView

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Home")
                    .font(.largeTitle.bold())

                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: toCallDestination) {
                        homeCard(title: "To Call", count: viewModel.counters.toCall)
                    }
                    NavigationLink(destination: toBuyDestination) {
                        homeCard(title: "To Buy", count: viewModel.counters.toBuy)
                    }
                    NavigationLink(destination: toSellDestination) {
                        homeCard(title: "To Sell", count: viewModel.counters.toSell)
                    }
                    NavigationLink(destination: syncDestination) {
                        homeCard(title: "Sync (Manual)", count: viewModel.counters.sync)
                    }
                }
            }
            .padding(24)
        }
    }

    private func homeCard(title: String, count: Int) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text("\(count)")
                .font(.system(size: 36, weight: .bold))
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let container = AppContainer()
    HomeView(
        viewModel: container.makeHomeViewModel(),
        toCallDestination: AnyView(Text("To Call")),
        toBuyDestination: AnyView(Text("To Buy")),
        toSellDestination: AnyView(Text("To Sell")),
        syncDestination: AnyView(Text("Sync"))
    )
}
