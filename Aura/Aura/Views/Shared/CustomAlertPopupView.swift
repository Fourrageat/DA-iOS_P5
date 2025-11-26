//
//  popup.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 19/11/2025.
//

import SwiftUI

private struct CustomAlertPopup: ViewModifier {
    @Binding var show: Bool
    @Binding var message: String
    @Binding var icon: String

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if show {
                        // Backdrop: dim + blur, tap outside to dismiss
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .accessibilityHidden(true)

                        // Popup card
                        ZStack {
                            VStack(spacing: 16) {
                                // Icon badge
                                ZStack {
                                    Circle()
                                        .fill(.thinMaterial)
                                        .frame(width: 72, height: 72)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)

                                    Image(systemName: icon)
                                        .foregroundStyle(.primary)
                                        .font(.system(size: 34, weight: .semibold))
                                        .accessibilityHidden(true)
                                }
                                .padding(.top, 8)

                                // Title / message
                                Text(message)
                                    .multilineTextAlignment(.center)
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 24)

                                // Action
                                Button(action: { show = false }) {
                                    Text("OK")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#94A684"))
                                .controlSize(.large)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                            }
                        }
                        .frame(maxWidth: 360)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                        .sensoryFeedback(.impact(weight: .medium, intensity: 0.9), trigger: show)
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isModal)
                        
                        .padding(.horizontal, 15)
                    }
                }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: show)
    }
}

extension View {
    func customAlertPopup(
        show: Binding<Bool>,
        message: Binding<String>,
        icon: Binding<String>) -> some View {
        modifier(CustomAlertPopup(show: show, message: message, icon: icon)
        )
    }
}

#Preview {
    struct AlertPopupPreviewHost: View {
        @State private var show = true
        @State private var message = "Error Message"
        @State private var icon = "exclamationmark.circle"
        
        let gradientStart = Color(hex: "#94A684").opacity(0.7)
        let gradientEnd = Color(hex: "#94A684").opacity(0.0) // Fades to transparent
        
        var body: some View {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .top, endPoint: .bottomLeading)
                    .edgesIgnoringSafeArea(.all)
            }
            .customAlertPopup(show: $show, message: $message, icon: $icon)
        }
    }

    return AlertPopupPreviewHost()
}
