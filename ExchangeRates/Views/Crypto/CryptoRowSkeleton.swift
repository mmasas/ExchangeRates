//
//  CryptoRowSkeleton.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // Logo placeholder (circle)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // Name and symbol placeholders
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 14)
            }
            
            Spacer()
            
            // Right side content placeholder
            VStack(alignment: .trailing, spacing: 4) {
                // Price placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                
                // Percentage change placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 14)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .redacted(reason: .placeholder)
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

