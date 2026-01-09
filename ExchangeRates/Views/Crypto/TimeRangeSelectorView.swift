//
//  TimeRangeSelectorView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 04/01/2026.
//

import SwiftUI

struct TimeRangeSelectorView: View {
    @Binding var selectedRange: ChartTimeRange
    let onRangeSelected: (ChartTimeRange) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                    }
                    onRangeSelected(range)
                }) {
                    Text(range.displayLabel)
                        .font(.system(size: 14, weight: selectedRange == range ? .semibold : .regular))
                        .foregroundColor(selectedRange == range ? .green : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedRange == range {
                                    Capsule()
                                        .fill(Color.green.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                if range != ChartTimeRange.allCases.last {
                    Text("|")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.3))
                        .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimeRangeSelectorView(
            selectedRange: .constant(.sevenDays),
            onRangeSelected: { range in
                print("Selected range: \(range.displayLabel)")
            }
        )
        .padding()
        .background(Color(.systemBackground))
        
        TimeRangeSelectorView(
            selectedRange: .constant(.threeMonths),
            onRangeSelected: { range in
                print("Selected range: \(range.displayLabel)")
            }
        )
        .padding()
        .background(Color(.systemBackground))
    }
    .background(Color(.systemGroupedBackground))
}






