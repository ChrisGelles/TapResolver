//
//  BeaconConfigProgressView.swift
//  TapResolver
//
//  Created by Chris Gelles on 1/3/26.
//


//
//  BeaconConfigProgressView.swift
//  TapResolver
//
//  Progress view for beacon configuration operations.
//

import SwiftUI

struct BeaconConfigProgressView: View {
    @Binding var results: [BeaconConfigResult]
    let onClose: () -> Void
    
    private var completedCount: Int {
        results.filter { $0.status == .complete || $0.status == .failed }.count
    }
    
    private var progress: Double {
        guard !results.isEmpty else { return 0 }
        return Double(completedCount) / Double(results.count)
    }
    
    private var isComplete: Bool {
        completedCount == results.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Progress list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(results) { result in
                            BeaconProgressRow(result: result)
                        }
                    }
                    .padding()
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                    
                    Text("\(Int(progress * 100))% Complete")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Close button
                Button {
                    onClose()
                } label: {
                    Text(isComplete ? "Close" : "Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isComplete ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Configuring Beacons")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Progress Row

struct BeaconProgressRow: View {
    let result: BeaconConfigResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.beaconID)
                .font(.system(size: 14, weight: .semibold))
            
            HStack(spacing: 8) {
                statusIcon
                statusText
            }
            .font(.system(size: 12))
            .foregroundColor(statusColor)
            
            if let error = result.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.leading, 24)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch result.status {
        case .waiting:
            Image(systemName: "clock")
        case .connecting, .settingTxPower, .settingInterval, .verifying:
            ProgressView()
                .scaleEffect(0.7)
        case .complete:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "xmark.circle.fill")
        }
    }
    
    private var statusText: Text {
        switch result.status {
        case .waiting:
            return Text("Waiting...")
        case .connecting:
            return Text("Connecting...")
        case .settingTxPower:
            return Text("Setting TX Power...")
        case .settingInterval:
            return Text("Setting Interval...")
        case .verifying:
            return Text("Verifying...")
        case .complete:
            return Text("Complete")
        case .failed:
            return Text("Failed")
        }
    }
    
    private var statusColor: Color {
        switch result.status {
        case .waiting:
            return .secondary
        case .connecting, .settingTxPower, .settingInterval, .verifying:
            return .blue
        case .complete:
            return .green
        case .failed:
            return .red
        }
    }
}