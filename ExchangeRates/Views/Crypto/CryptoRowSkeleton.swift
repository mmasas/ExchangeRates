//
//  CryptoRowSkeleton.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoRowSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder (circle)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // Name and symbol placeholders
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 14)
            }
            .frame(minWidth: 60)
            
            Spacer(minLength: 4)
            
            // Sparkline placeholder
            SparklineSkeletonShape()
                .stroke(Color.gray.opacity(isAnimating ? 0.2 : 0.4), lineWidth: 1.5)
                .frame(width: 120, height: 40)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Right side content placeholder
            VStack(alignment: .trailing, spacing: 4) {
                // Price placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 70, height: 16)
                
                // Percentage change placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 14)
            }
            .frame(minWidth: 80)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .redacted(reason: .placeholder)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Sparkline Skeleton Shape

private struct SparklineSkeletonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let midY = rect.height / 2
        let amplitude: CGFloat = 8
        let width = rect.width
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        // Create a gentle wave pattern for skeleton
        for x in stride(from: 0, through: width, by: 2) {
            let progress = x / width
            let y = midY + sin(progress * .pi * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

#Preview {
    VStack(spacing: 12) {
        CryptoRowSkeleton()
        CryptoRowSkeleton()
        CryptoRowSkeleton()
        CryptoRowSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

