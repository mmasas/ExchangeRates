//
//  ThemePickerView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 11/01/2026.
//

import SwiftUI

struct ThemePickerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    private var theme: AppTheme { themeManager.currentTheme }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Theme cards container
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.usesSystemColors ? Color(.secondarySystemBackground) : theme.cardBackgroundColor)
                .frame(height: 160)
                .overlay(
                    ZStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(AppTheme.allCases) { themeOption in
                                    ThemeCardView(
                                        theme: themeOption,
                                        isSelected: themeManager.currentTheme == themeOption,
                                        currentTheme: theme,
                                        isDisabled: themeManager.isChangingTheme
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            themeManager.setTheme(themeOption)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .opacity(themeManager.isChangingTheme ? 0.5 : 1.0)
                        .allowsHitTesting(!themeManager.isChangingTheme)
                        
                        // Progress indicator overlay
                        if themeManager.isChangingTheme {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(theme.usesSystemColors ? .blue : theme.accentColor)
                        }
                    }
                )
        }
    }
}

// MARK: - Theme Card View

struct ThemeCardView: View {
    let theme: AppTheme
    let isSelected: Bool
    let currentTheme: AppTheme
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Theme preview card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.previewBackgroundColor)
                    .frame(width: 90, height: 90)
                
                // Three horizontal lines representing content
                VStack(spacing: 8) {
                    // Accent colored line (top)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accentColor)
                        .frame(width: 50, height: 6)
                    
                    // Gray lines (bottom two)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.previewLineColor)
                        .frame(width: 50, height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.previewLineColor)
                        .frame(width: 50, height: 6)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Theme name
            Text(theme.displayName)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(currentTheme.usesSystemColors 
                    ? (isSelected ? .primary : .secondary)
                    : (isSelected ? currentTheme.primaryTextColor : currentTheme.secondaryTextColor))
        }
        .opacity(isDisabled ? 0.6 : 1.0)
        .onTapGesture {
            guard !isDisabled else { return }
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ThemePickerView()
            .padding()
        Spacer()
    }
    .background(Color(.systemBackground))
}
