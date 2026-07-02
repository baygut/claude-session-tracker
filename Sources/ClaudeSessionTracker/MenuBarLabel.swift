import SwiftUI

struct MenuBarLabel: View {
    @EnvironmentObject var store: UsageStore

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.needle")
            Text(store.menuBarText)
        }
    }
}
