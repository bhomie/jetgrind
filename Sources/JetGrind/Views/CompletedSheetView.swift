import SwiftUI

struct CompletedSheetView: View {
    @Bindable var store: TodoStore
    @Binding var isPresented: Bool
    var focus: FocusState<TodoFocus?>.Binding

    @State private var dragOffset: CGFloat = 0

    private var completedItems: [TodoItem] {
        store.items.filter { $0.isCompleted }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(Theme.Opacity.overlayDim)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Sheet content
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(.secondary.opacity(Theme.Opacity.handleMuted))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Header
                HStack {
                    Text("Completed")
                        .font(.system(size: Theme.Font.bodySemibold, weight: .semibold))
                    Spacer()
                    Text("\(completedItems.count)")
                        .font(.system(size: Theme.Font.bodyMedium, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                Divider()
                    .padding(.horizontal, 12)

                // Completed items list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(completedItems.enumerated()), id: \.element.id) { index, item in
                            let prevId = index > 0 ? completedItems[index - 1].id : nil
                            let nextId = index < completedItems.count - 1 ? completedItems[index + 1].id : nil
                            completedRow(item: item, previousId: prevId, nextId: nextId, isFirst: index == 0)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .offset(y: max(0, dragOffset))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        
                        if value.translation.height > threshold || velocity > 500 {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
            focus.wrappedValue = .completedPill
        }
    }

    @ViewBuilder
    private func completedRow(item: TodoItem, previousId: UUID?, nextId: UUID?, isFirst: Bool) -> some View {
        let isFocused = focus.wrappedValue == .completedTask(item.id)
        
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Theme.Font.icon))
                .foregroundStyle(Theme.Color.completedCheckmark)

            Text(item.title)
                .font(.system(size: Theme.Font.bodyMedium, weight: .medium))
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(item.createdAt.relativeFormat)
                .font(.system(size: Theme.Font.body))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.primary.opacity(Theme.Opacity.rowHighlight)))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(isFocused ? Color.primary.opacity(Theme.Opacity.rowHighlight) : Color.clear)
        .focusable()
        .focused(focus, equals: .completedTask(item.id))
        .focusEffectDisabled()
        .onKeyPress(.upArrow) {
            if let prevId = previousId {
                focus.wrappedValue = .completedTask(prevId)
            } else {
                dismiss()
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if let nextId = nextId {
                focus.wrappedValue = .completedTask(nextId)
            }
            return .handled
        }
        .onKeyPress(.space) {
            // Uncomplete the task
            if let idx = store.items.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.items[idx].isCompleted = false
                }
                // Move focus to next item or close if none left
                if let nextId = nextId {
                    focus.wrappedValue = .completedTask(nextId)
                } else if let prevId = previousId {
                    focus.wrappedValue = .completedTask(prevId)
                } else {
                    dismiss()
                }
            }
            return .handled
        }
        .onKeyPress(.return) {
            // Uncomplete the task
            if let idx = store.items.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    store.items[idx].isCompleted = false
                }
                // Move focus to next item or close if none left
                if let nextId = nextId {
                    focus.wrappedValue = .completedTask(nextId)
                } else if let prevId = previousId {
                    focus.wrappedValue = .completedTask(prevId)
                } else {
                    dismiss()
                }
            }
            return .handled
        }
    }
}
