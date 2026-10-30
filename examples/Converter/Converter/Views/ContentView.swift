import SwiftUI

struct ContentView: View {
    @Environment(ConverterModel.self) private var model
    @FocusState private var inputFocused: Bool

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Form {
                Section {
                    Picker("Measure", selection: $model.kind) {
                        ForEach(UnitKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.symbol).tag(kind)
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Value", text: $model.input)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                            .focused($inputFocused)
                            .accessibilityIdentifier("input")
                        Text(ConverterModel.symbol(of: model.fromUnit))
                            .foregroundStyle(.secondary)
                    }
                    unitPicker("From", selection: $model.fromIndex)
                    HStack {
                        Spacer()
                        Button("Swap Units", systemImage: "arrow.up.arrow.down") {
                            withAnimation { model.swap() }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.bordered)
                        .clipShape(.circle)
                        Spacer()
                    }
                    unitPicker("To", selection: $model.toIndex)
                    resultView
                }

                if let value = model.value {
                    Section("All \(model.kind.title.localizedLowercase) units") {
                        ForEach(model.kind.units.indices, id: \.self) { index in
                            let unit = model.kind.units[index]
                            LabeledContent(ConverterModel.name(of: unit)) {
                                Text("\(ConverterModel.format(model.convert(value, to: unit))) \(ConverterModel.symbol(of: unit))")
                                    .monospacedDigit()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Converter")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                }
            }
        }
    }

    private func unitPicker(_ title: LocalizedStringKey, selection: Binding<Int>) -> some View {
        Picker(title, selection: selection) {
            ForEach(model.kind.units.indices, id: \.self) { index in
                Text(ConverterModel.name(of: model.kind.units[index])).tag(index)
            }
        }
    }

    @ViewBuilder private var resultView: some View {
        if let result = model.result {
            let text = ConverterModel.format(result)
            HStack {
                Text(text)
                    .font(.largeTitle.bold().monospacedDigit())
                    .accessibilityIdentifier("result")
                Text(ConverterModel.symbol(of: model.toUnit))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = text
                }
                .labelStyle(.iconOnly)
            }
            .contentTransition(.numericText())
        } else {
            Text("Enter a number")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environment(ConverterModel(defaults: UserDefaults(suiteName: "preview")!))
}
