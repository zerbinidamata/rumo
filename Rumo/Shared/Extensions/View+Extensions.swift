import SwiftUI

extension View {

    // MARK: - Conditional Modifiers

    /// Applies a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies a modifier if the value is non-nil
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    // MARK: - Card Style

    /// Applies a card style with rounded corners and shadow
    func cardStyle(
        backgroundColor: Color = Color(.systemBackground),
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }

    // MARK: - Hide Keyboard

    /// Adds a gesture to hide the keyboard when tapping outside
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    // MARK: - Loading Overlay

    /// Shows a loading overlay when condition is true
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }

    // MARK: - Error Alert

    /// Shows an error alert with the given error
    func errorAlert(
        _ error: Binding<Error?>,
        title: LocalizedStringKey = "error.title"
    ) -> some View {
        self.alert(
            title,
            isPresented: .init(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { _ in
            Button(String(localized: "common.ok"), role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Reduce Motion

    /// Returns whether the user has enabled Reduce Motion
    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

// MARK: - Safe Area

extension View {

    /// Reads the safe area insets
    func readSafeAreaInsets(_ insets: Binding<EdgeInsets>) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        insets.wrappedValue = proxy.safeAreaInsets
                    }
            }
        )
    }
}
