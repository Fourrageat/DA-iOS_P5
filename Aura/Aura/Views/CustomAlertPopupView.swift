//
//  popup.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 19/11/2025.
//

import SwiftUI

private struct CustomAlertPopup: ViewModifier {
    @Binding var show: Bool

    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if show {
                    // Tap outside to dismiss
                    Color.clear
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { show = false }

                    // Popup content
                    ZStack {
                        VStack {
                            Image(systemName: "lock.badge.xmark")
                                .foregroundColor(Color.white)
                                .frame(width: 50, height: 50)
                                .font(Font.system(size: 50, weight: .bold, design: .default))
                                .padding(.bottom, 20)
                                
                            HStack {
                                Text("Email ou mot de passe incorrect")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.white)
                                    .font(Font.system(size: 17, weight: .bold, design: .default))
                            }
                            .padding(.horizontal, 35)

                            HStack {
                                Button(action: {
                                    show = false
                                }, label: {
                                    Text("OK")
                                        .foregroundColor(Color.gray)
                                        .padding(.top, 15)
                                        .padding(.bottom, 15)
                                        .padding(.trailing, 55)
                                        .padding(.leading, 55)
                                        .background(Color.black.opacity(0.8))
                                        .font(Font.system(size: 20, weight: .bold, design: .default))
                                        .cornerRadius(30)
                                })
                            }
                            .padding(.bottom, 0)
                            .padding(.horizontal, 50)
                            .padding(.top, 15)
                            
                        }
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#94A684"))
                    .cornerRadius(40)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
                    .ignoresSafeArea()
                }
            }
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: show)
    }
}

extension View {
    func customAlertPopup(show: Binding<Bool>) -> some View {
        modifier(CustomAlertPopup(show: show))
    }
}

#Preview {
    struct ErrorPopupPreviewHost: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                    .foregroundColor(.white)
                Spacer()
            }
            .customAlertPopup(show: $show)
        }
    }

    return ErrorPopupPreviewHost()
}
