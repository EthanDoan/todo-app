import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: HomeViewModel
    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: container.makeHomeViewModel())
    }

    var body: some View {
        HomeView(
            viewModel: viewModel,
            toCallDestination: AnyView(ToCallView(viewModel: container.makeToCallViewModel())),
            toBuyDestination: AnyView(ToBuyView(viewModel: container.makeToBuyViewModel())),
            toSellDestination: AnyView(ToSellView(viewModel: container.makeToSellViewModel())),
            syncDestination: AnyView(SyncView(viewModel: container.makeSyncViewModel()))
        )
    }
}

#Preview {
    let container = AppContainer()
    ContentView(container: container)
}
