//
//  TabSelectionView.swift
//  Crema
//
//  Created by Hugo Persson on 2024-08-25.
//

import SwiftUI

struct TabModel: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let view: NotchViews

    static let home = TabModel(label: "Home", icon: "cup.and.saucer.fill", view: .home)
    static let shelf = TabModel(label: "Shelf", icon: "tray.and.arrow.down.fill", view: .shelf)
}

/// One icon button for a notch tab. The header puts Home and the shelf (AirDrop) side by side next to the notch.
struct NotchTabButton: View {
    let tab: TabModel
    @ObservedObject var coordinator = CremaViewCoordinator.shared

    private var selected: Bool { coordinator.currentView == tab.view }

    var body: some View {
        TabButton(label: tab.label, icon: tab.icon, selected: selected) {
            withAnimation(.smooth) {
                coordinator.currentView = tab.view
            }
        }
        .frame(height: 26)
        .foregroundStyle(selected ? .white : .gray)
        .background {
            Capsule()
                .fill(Color(nsColor: .secondarySystemFill))
                .opacity(selected ? 1 : 0)
        }
        .clipShape(Capsule())
    }
}

#Preview {
    CremaHeader().environmentObject(CremaViewModel())
}
