import SwiftUI

// MARK: - Liquid Glass Design System for iOS 26+
// This design system implements Apple's Liquid Glass aesthetic introduced in iOS 26/visionOS
// with graceful fallbacks for earlier iOS versions.

// MARK: - iOS Version Check
struct VersionCheck {
    static var isIOS26OrLater: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}

// MARK: - Native Liquid Glass Effect (iOS 26+)
@available(iOS 26.0, *)
struct NativeLiquidGlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Color Scheme
extension Color {
    // Primary accent colors
    static let liquidGlassAccent = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let liquidGlassSecondary = Color(red: 0.6, green: 0.8, blue: 1.0)
    
    // Glass background colors
    static let glassBackground = Color.white.opacity(0.15)
    static let glassBorder = Color.white.opacity(0.3)
    
    // Dark mode specific
    static let darkGlassBackground = Color.white.opacity(0.08)
    static let darkGlassBorder = Color.white.opacity(0.15)
    
    // Gradient colors for ambient background
    static let ambientGradientStart = Color(red: 0.1, green: 0.1, blue: 0.2)
    static let ambientGradientMid = Color(red: 0.15, green: 0.12, blue: 0.25)
    static let ambientGradientEnd = Color(red: 0.08, green: 0.1, blue: 0.18)
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.12
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base blur effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Glass overlay gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2),
                                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle border glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.4),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Animated Background
struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: Double = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.08, green: 0.06, blue: 0.12),
                        Color(red: 0.04, green: 0.05, blue: 0.09)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.96, blue: 0.98),
                        Color(red: 0.92, green: 0.94, blue: 0.98),
                        Color(red: 0.96, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Animated ambient orbs
            GeometryReader { geometry in
                ZStack {
                    // Primary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.liquidGlassAccent.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                    Color.liquidGlassAccent.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                        .offset(
                            x: geometry.size.width * 0.2 + sin(animationPhase) * 30,
                            y: -geometry.size.height * 0.1 + cos(animationPhase * 0.8) * 20
                        )
                        .blur(radius: 60)
                    
                    // Secondary orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.liquidGlassSecondary.opacity(colorScheme == .dark ? 0.12 : 0.08),
                                    Color.liquidGlassSecondary.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.3
                            )
                        )
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                        .offset(
                            x: -geometry.size.width * 0.2 + cos(animationPhase * 0.7) * 25,
                            y: geometry.size.height * 0.4 + sin(animationPhase * 0.9) * 15
                        )
                        .blur(radius: 50)
                    
                    // Tertiary accent orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(colorScheme == .dark ? 0.1 : 0.06),
                                    Color.purple.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.25
                            )
                        )
                        .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5)
                        .offset(
                            x: geometry.size.width * 0.3 + sin(animationPhase * 1.1) * 20,
                            y: geometry.size.height * 0.6 + cos(animationPhase * 0.6) * 25
                        )
                        .blur(radius: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.liquidGlassAccent,
                                        Color.liquidGlassAccent.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3),
                                lineWidth: 1
                            )
                    }
                }
            )
            .foregroundColor(isProminent ? .white : (colorScheme == .dark ? .white : .primary))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Glass Text Field Style
struct GlassTextFieldModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.25),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Shimmer Effect for Loading States
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(x: -geometry.size.width * 0.3 + geometry.size.width * 1.3 * phase)
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.12) -> some View {
        if #available(iOS 26.0, *) {
            // Use native Liquid Glass on iOS 26+
            self
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        } else {
            // Fallback for earlier iOS versions
            modifier(GlassCardModifier(cornerRadius: cornerRadius, opacity: opacity))
        }
    }
    
    @ViewBuilder
    func glassTextField() -> some View {
        if #available(iOS 26.0, *) {
            self
                .padding(14)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
        } else {
            modifier(GlassTextFieldModifier())
        }
    }
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Days Badge View (Liquid Glass style)
struct DaysBadge: View {
    let days: Int
    let label: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(days)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Expand/Collapse Chevron with Animation
struct AnimatedChevron: View {
    let isExpanded: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .secondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}
