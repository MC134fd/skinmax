import SwiftUI

struct WaterLogSheet: View {
    @Bindable var viewModel: WaterLogViewModel
    var onLog: (Double) -> Void
    var onDismiss: () -> Void

    @FocusState private var customFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                dropletSection
                presetsSection
                if viewModel.showCustom {
                    customEntrySection
                }
                logButton
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(GlowbiteColors.creamBG)
    }

    private var header: some View {
        HStack {
            Text("Log Water")
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Spacer()

            unitToggle
        }
    }

    private var unitToggle: some View {
        HStack(spacing: 0) {
            ForEach(WaterUnit.allCases) { unit in
                Button {
                    viewModel.toggleUnit(unit)
                } label: {
                    Text(unit.shortLabel.uppercased())
                        .font(.gbOverline)
                        .tracking(1.0)
                        .foregroundStyle(viewModel.unit == unit ? GlowbiteColors.hydrationBlue : GlowbiteColors.lightTaupe)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.unit == unit ? GlowbiteColors.blueLight : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(GlowbiteColors.paper)
                .overlay(
                    Capsule()
                        .stroke(GlowbiteColors.border, lineWidth: 1)
                )
        )
    }

    private var dropletSection: some View {
        VStack(spacing: 6) {
            WaterDropletVisualizer(
                fillRatio: viewModel.projectedRatio,
                centerNumber: viewModel.centerNumber,
                unitLabel: viewModel.centerUnit,
                subtitle: viewModel.progressSubtitle
            )
            .frame(width: 160, height: 200)

            Text(viewModel.goalLabel)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.mediumTaupe)

            if !viewModel.pourHistory.isEmpty {
                Button {
                    viewModel.undoLastPour()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 11, weight: .bold))
                        Text("Undo last pour")
                            .font(.gbOverline)
                            .tracking(0.8)
                    }
                    .foregroundStyle(GlowbiteColors.hydrationBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(GlowbiteColors.blueLight))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    private var presetsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("QUICK ADD")
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
                Spacer()
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(viewModel.unit.presets) { preset in
                    presetCard(preset)
                }

                customChip
            }
        }
    }

    private func presetCard(_ preset: WaterPreset) -> some View {
        Button {
            viewModel.addPreset(preset)
        } label: {
            HStack(spacing: 10) {
                Text(preset.emoji)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                    Text(preset.amountLabel)
                        .font(.gbOverline)
                        .tracking(0.6)
                        .foregroundStyle(GlowbiteColors.hydrationBlue)
                }

                Spacer(minLength: 0)

                Text("+")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(GlowbiteColors.hydrationBlue)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(GlowbiteColors.blueLight))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusSmall)
                    .fill(GlowbiteColors.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusSmall)
                    .stroke(GlowbiteColors.hydrationBlue.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: GlowbiteColors.subtleShadowColor, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var customChip: some View {
        Button {
            viewModel.showCustom.toggle()
            if viewModel.showCustom {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    customFieldFocused = true
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "keyboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(GlowbiteColors.hydrationBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom")
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                    Text("Type \(viewModel.unit.shortLabel)")
                        .font(.gbOverline)
                        .tracking(0.6)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusSmall)
                    .fill(GlowbiteColors.blueLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusSmall)
                    .stroke(GlowbiteColors.hydrationBlue.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var customEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ENTER AMOUNT (\(viewModel.unit.shortLabel.uppercased()))")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            HStack(spacing: 10) {
                TextField("0", text: $viewModel.customInput)
                    .keyboardType(.decimalPad)
                    .focused($customFieldFocused)
                    .font(.gbTitleL)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(GlowbiteColors.paper)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(GlowbiteColors.border, lineWidth: 1)
                    )

                Button {
                    viewModel.addCustomAmount()
                    customFieldFocused = false
                } label: {
                    Text("Add")
                        .font(.gbTitleM)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(GlowbiteColors.hydrationBlue)
                        )
                }
                .buttonStyle(.plain)
                .disabled(Double(viewModel.customInput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0 <= 0)
                .opacity((Double(viewModel.customInput.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) <= 0 ? 0.5 : 1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                .fill(GlowbiteColors.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                .stroke(GlowbiteColors.border, lineWidth: 1)
        )
    }

    private var logButton: some View {
        Button {
            guard viewModel.canLog else { return }
            let ml = viewModel.pendingMl
            HapticManager.notification(.success)
            onLog(ml)
            viewModel.reset()
            onDismiss()
        } label: {
            HStack(spacing: 6) {
                Text("Log")
                    .font(.gbTitleM)
                Text("💧")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule()
                    .fill(
                        viewModel.canLog
                            ? AnyShapeStyle(GlowbiteColors.buttonGradient)
                            : AnyShapeStyle(GlowbiteColors.border)
                    )
            )
            .shadow(
                color: viewModel.canLog ? GlowbiteColors.buttonGlowColor : .clear,
                radius: 14,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canLog)
        .padding(.top, 4)
    }
}

#if DEBUG
#Preview("Water Log Sheet — Empty") {
    WaterLogSheet(
        viewModel: WaterLogViewModel(alreadyConsumedMl: 600, goalMl: 2_000, unit: .ml),
        onLog: { _ in },
        onDismiss: { }
    )
}

#Preview("Water Log Sheet — With Pours (oz)") {
    let vm = WaterLogViewModel(alreadyConsumedMl: 480, goalMl: 64 * WaterUnit.mlPerOz, unit: .oz)
    vm.pendingMl = 240
    vm.pourHistory = [240]
    return WaterLogSheet(
        viewModel: vm,
        onLog: { _ in },
        onDismiss: { }
    )
}
#endif
