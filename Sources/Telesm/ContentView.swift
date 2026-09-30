import SwiftUI

@MainActor
final class Model: ObservableObject {
    @Published var devices: [Device] = []
    @Published var selected: Device?
    @Published var current: Spot?
    @Published var busy = false
    @Published var status = "Checking for a connected iPhone…"
    @Published var isError = false

    init() { refresh() }

    func refresh() {
        let found = Phone.devices()
        devices = found
        if let selected, found.contains(selected) {
            self.selected = selected
        } else {
            selected = found.first { $0.isUSB } ?? found.first
        }
        if found.isEmpty {
            status = "No iPhone connected. Plug it in over USB, unlock it, and tap Trust if asked."
            isError = false
        } else if !busy {
            status = "Ready."
            isError = false
        }
    }

    func apply(_ spot: Spot) {
        guard let device = selected else { refresh(); return }
        busy = true
        isError = false
        status = "Setting \(spot.city)… first run can take a while."

        Task.detached(priority: .userInitiated) {
            let result = Phone.set(spot, device: device)
            await MainActor.run {
                self.busy = false
                if result.ok {
                    self.current = spot
                    self.status = "iPhone is now in \(spot.city)."
                    self.isError = false
                } else {
                    self.status = Phone.readable(result, fallback: "pymobiledevice3 failed.")
                    self.isError = true
                }
            }
        }
    }

    func reset() {
        guard let device = selected else { refresh(); return }
        busy = true
        isError = false
        status = "Clearing the fake location…"

        Task.detached(priority: .userInitiated) {
            let result = Phone.clear(device: device)
            await MainActor.run {
                self.busy = false
                if result.ok {
                    self.current = nil
                    self.status = "Cleared. The iPhone is back on its real GPS."
                    self.isError = false
                } else {
                    self.status = Phone.readable(result, fallback: "Could not clear the fake location.")
                    self.isError = true
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var model = Model()

    private let spots: [Spot] = [.newYork, .london, .oxford]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            deviceRow
            buttons
            statusRow
            Spacer(minLength: 0)
            credit
        }
        .padding(22)
        .frame(width: 430, height: 412)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Telesm").font(.system(size: 21, weight: .semibold))
            Text("A location spoofer for your iPhone's GPS.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var deviceRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.selected == nil ? Color.secondary.opacity(0.5) : Color.green)
                .frame(width: 9, height: 9)
            Text(model.selected.map { "\($0.name) · \($0.udid.prefix(8))…\($0.isUSB ? " · USB" : "")" }
                 ?? "No iPhone detected")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button("Check again") { model.refresh() }
                .controlSize(.small)
                .disabled(model.busy)
        }
    }

    private var buttons: some View {
        VStack(spacing: 10) {
            ForEach(spots) { spot in
                Button {
                    model.apply(spot)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(spot.city).font(.system(size: 15, weight: .semibold))
                            Text(spot.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if model.current == spot {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.busy || model.selected == nil)
            }

            Button("Real GPS (stop faking)") { model.reset() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(model.busy || model.selected == nil)
        }
    }

    private var statusRow: some View {
        HStack(alignment: .top, spacing: 8) {
            if model.busy {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: model.isError ? "exclamationmark.triangle.fill" : "info.circle")
                    .foregroundStyle(model.isError ? Color.orange : Color.secondary)
            }
            Text(model.status)
                .font(.system(size: 12))
                .foregroundStyle(model.isError ? Color.orange : Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var credit: some View {
        Text("Made by Morad")
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
    }
}
