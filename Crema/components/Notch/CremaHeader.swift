//
//  CremaHeader.swift
//  Crema
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Defaults
import SwiftUI

struct CremaHeader: View {
    @EnvironmentObject var vm: CremaViewModel
    @ObservedObject var coordinator = CremaViewCoordinator.shared
    @StateObject var tvm = ShelfStateViewModel.shared

    private var showTabs: Bool {
        (!tvm.isEmpty || coordinator.alwaysShowTabs) && Defaults[.cremaShelf]
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Home and the shelf (AirDrop), sitting right beside the notch.
            HStack(spacing: 2) {
                if showTabs {
                    NotchTabButton(tab: .home)
                    NotchTabButton(tab: .shelf)
                }
            }
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .zIndex(2)

            if vm.notchState == .open {
                Rectangle()
                    .fill(NSScreen.screen(withUUID: coordinator.selectedScreenUUID)?.safeAreaInsets.top ?? 0 > 0 ? .black : .clear)
                    .frame(width: vm.closedNotchSize.width)
                    .mask {
                        NotchShape()
                    }
            }

            // Right side: volume, then settings, sitting right beside the notch like the tabs on the left.
            HStack(spacing: 2) {
                if vm.notchState == .open {
                    VolumeBar()
                        .padding(.trailing, 6)
                    if Defaults[.settingsIconInNotch] {
                        Button(action: {
                            DispatchQueue.main.async {
                                SettingsWindowController.shared.showWindow()
                            }
                        }) {
                            Capsule()
                                .fill(.black)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Image(systemName: "gear")
                                        .foregroundColor(.white)
                                        .padding()
                                        .imageScale(.medium)
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .font(.system(.headline, design: .rounded))
            .padding(.leading, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(vm.notchState == .closed ? 0 : 1)
            .blur(radius: vm.notchState == .closed ? 20 : 0)
            .zIndex(2)
        }
        .foregroundColor(.gray)
        .environmentObject(vm)
    }
}

#Preview {
    CremaHeader().environmentObject(CremaViewModel())
}
