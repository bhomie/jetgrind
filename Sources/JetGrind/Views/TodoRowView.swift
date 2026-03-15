import SwiftUI

private struct DimState: Equatable {
    let isCompleted: Bool
    let isEditBlurred: Bool
}

private struct LayoutState: Equatable {
    let isFocusedOrExpanded: Bool
    let isInActionMode: Bool
}

struct TodoRowView: View {
    @Binding var item: TodoItem
    let store: TodoStore
    var focus: FocusState<TodoFocus?>.Binding
    let previousTaskId: UUID?
    let nextTaskId: UUID?
    let onDelete: () -> Void
    let onOpenCompleted: (() -> Void)?
    @Binding var isExpanded: Bool
    let isEditBlurred: Bool
    let onExpand: () -> Void
    let onEditingChanged: ((Bool) -> Void)?
    var rowIndex: Int = 0
    var cascadeDelay: Double = 0

    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var showTimestamp = false
    @State private var isCompleting = false
    @State private var isAppearing = true
    @State private var isEditing = false
    @State private var editText = ""
    @State private var editDescription = ""
    @State private var editLinks: [LinkItem] = []
    @State private var titleFocused = false
    @State private var descriptionFocused = false
    @State private var titleHeight: CGFloat = 20
    @State private var descriptionHeight: CGFloat = 20
    @State private var readOnlyDescriptionHeight: CGFloat = 18
    @State private var showCheckmarkDraw = false
    @State private var showParticleBurst = false
    @State private var emojiScale: CGFloat = 1.0
    @State private var emojiBlur: CGFloat = 0.0
    @State private var visualActionIndex: Int? = nil

    private let opacityAnimation: Animation = .linear(duration: 0.15)

    private var pastelColor: Color {
        Theme.Pastel.color(for: rowIndex)
    }

    private var pastelOpacity: Double {
        colorScheme == .dark ? Theme.Opacity.pastelRowDark : Theme.Opacity.pastelRowLight
    }

    private var actionButtonOpacity: Double {
        colorScheme == .dark ? 0.15 : 0.3
    }

    private var isActive: Bool {
        !item.isCompleted && (isHovered || focus.wrappedValue == .task(item.id) || isInActionMode)
    }

    private var isKeyboardFocused: Bool {
        focus.wrappedValue == .task(item.id)
    }

    private var isHighlighted: Bool {
        isHovered || focus.wrappedValue == .task(item.id) || isInActionMode
    }

    private var isInActionMode: Bool {
        switch focus.wrappedValue {
        case .actionEdit(let id), .actionComplete(let id), .actionDelete(let id):
            return id == item.id
        default:
            return false
        }
    }

    private var hasExpandedContent: Bool {
        item.description != nil || !item.links.isEmpty
    }

    private var titleHasMarkers: Bool {
        TextPillConverter.containsMarkers(item.title)
    }

    private var descriptionHasMarkers: Bool {
        guard let desc = item.description else { return false }
        return TextPillConverter.containsMarkers(desc)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row
            HStack(alignment: .center, spacing: 0) {
                // Emoji / celebration area
                emojiArea

                ZStack(alignment: .leading) {
                    titleView
                        .opacity(isEditing ? 0 : 1)
                        .animation(opacityAnimation, value: isEditing)
                    inlineEditField
                        .opacity(isEditing ? 1 : 0)
                        .animation(opacityAnimation, value: isEditing)
                        .allowsHitTesting(isEditing)
                }
                .padding(.leading, 6)
                Spacer(minLength: 4)
                trailingArea
            }

            // Expanded content: description + inline pills
            if isExpanded || isEditing {
                expandedContent
                    .padding(.vertical, 4)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(pastelColor.opacity(isHighlighted ? pastelOpacity * 3 : pastelOpacity))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHighlighted)
        .opacity(item.isCompleted ? Theme.Opacity.completedRow : (isEditBlurred ? Theme.Opacity.editDimOpacity : 1.0))
        .blur(radius: isEditBlurred ? Theme.Size.editBlurRadius : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: DimState(isCompleted: item.isCompleted, isEditBlurred: isEditBlurred))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: LayoutState(isFocusedOrExpanded: isKeyboardFocused || isExpanded, isInActionMode: isInActionMode))
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isAppearing = false
                }
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if hasExpandedContent {
                withAnimation(Theme.Anim.fanOut) {
                    if isExpanded {
                        isExpanded = false
                    } else {
                        onExpand()
                    }
                }
            }
        }
        .focusable()
        .focused(focus, equals: .task(item.id))
        .focusEffectDisabled()
        .onChange(of: focus.wrappedValue) { _, newFocus in
            let idx: Int?
            switch newFocus {
            case .actionComplete(let id) where id == item.id: idx = 0
            case .actionEdit(let id) where id == item.id: idx = 1
            case .actionDelete(let id) where id == item.id: idx = 2
            default: idx = nil
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                visualActionIndex = idx
            }
        }
        .onKeyPress(.upArrow) {
            guard !isEditing else { return .ignored }
            if isInActionMode {
                if let prevId = previousTaskId, let idx = focus.wrappedValue?.actionIndex {
                    focus.wrappedValue = TodoFocus.action(index: idx, taskId: prevId)
                }
                return .handled
            }
            if let prevId = previousTaskId {
                focus.wrappedValue = .task(prevId)
            } else {
                focus.wrappedValue = .input
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !isEditing else { return .ignored }
            if isInActionMode {
                if let nextId = nextTaskId, let idx = focus.wrappedValue?.actionIndex {
                    focus.wrappedValue = TodoFocus.action(index: idx, taskId: nextId)
                }
                return .handled
            }
            if let nextId = nextTaskId {
                focus.wrappedValue = .task(nextId)
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !isEditing, !item.isCompleted else { return .ignored }
            if isInActionMode {
                if let idx = focus.wrappedValue?.actionIndex {
                    if idx < 2 {
                        focus.wrappedValue = TodoFocus.action(index: idx + 1, taskId: item.id)
                    } else if let openCompleted = onOpenCompleted {
                        openCompleted()
                    }
                }
                return .handled
            }
            if isKeyboardFocused {
                focus.wrappedValue = .actionComplete(item.id)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.leftArrow) {
            guard !isEditing else { return .ignored }
            if isInActionMode {
                if let idx = focus.wrappedValue?.actionIndex {
                    if idx > 0 {
                        focus.wrappedValue = TodoFocus.action(index: idx - 1, taskId: item.id)
                    } else {
                        focus.wrappedValue = .task(item.id)
                    }
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            guard !isEditing, !isInActionMode else { return .ignored }
            cycleEmoji()
            return .handled
        }
        .onKeyPress(.return) {
            guard !isEditing, !isInActionMode else { return .ignored }
            handleToggle()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "eE")) { _ in
            guard !isEditing, !isInActionMode, !item.isCompleted else { return .ignored }
            startEditing()
            return .handled
        }
        .onKeyPress(.escape) {
            if isInActionMode {
                focus.wrappedValue = .task(item.id)
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            guard !isEditing, !isInActionMode else { return .ignored }
            moveFocusToNeighbor()
            onDelete()
            return .handled
        }
        .onKeyPress { keyPress in
            guard !isEditing, !isInActionMode else { return .ignored }
            if keyPress.key.character == "\u{7F}" || keyPress.key.character == "\u{08}" {
                moveFocusToNeighbor()
                onDelete()
                return .handled
            }
            return .ignored
        }
    }

    private var emojiArea: some View {
        ZStack {
            if showCheckmarkDraw {
                CheckmarkDrawView()
                    .frame(width: 20, height: 20)
                    .transition(.scale.combined(with: .opacity))
            }
            if showParticleBurst {
                ParticleBurstView(color: pastelColor)
                    .frame(width: 40, height: 40)
            }
            if !showCheckmarkDraw {
                Text(item.emoji ?? "✨")
                    .font(.system(size: Theme.Font.display))
                    .scaleEffect(emojiScale)
                    .blur(radius: emojiBlur)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 24, height: 24)
        .onTapGesture {
            cycleEmoji()
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if titleHasMarkers {
            PillTextView(
                text: .constant(item.title),
                links: .constant(item.links),
                isEditable: false,
                isSingleLine: true,
                font: .systemFont(ofSize: Theme.Font.title, weight: .medium),
                textColor: item.isCompleted ? .secondaryLabelColor : .labelColor,
                isFocused: .constant(false),
                height: .constant(20)
            )
            .strikethrough(item.isCompleted)
            .contentTransition(.opacity)
            .blur(radius: (isCompleting || isAppearing) ? 8 : 0)
            .opacity((isCompleting || isAppearing) ? 0 : 1)
            .animation(opacityAnimation, value: isCompleting)
            .animation(opacityAnimation, value: isAppearing)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
        } else {
            Text(item.title)
                .font(.system(size: Theme.Font.title, weight: .medium))
                .strikethrough(item.isCompleted)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .lineLimit(1)
                .contentTransition(.opacity)
                .blur(radius: (isCompleting || isAppearing) ? 8 : 0)
                .opacity((isCompleting || isAppearing) ? 0 : 1)
                .animation(opacityAnimation, value: isCompleting)
                .animation(opacityAnimation, value: isAppearing)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.isCompleted)
        }
    }

    private var inlineEditField: some View {
        PillTextView(
            text: $editText,
            links: $editLinks,
            isEditable: true,
            isSingleLine: true,
            font: .systemFont(ofSize: Theme.Font.title, weight: .medium),
            textColor: .labelColor,
            placeholderText: "Edit task",
            onCommit: { commitEdit() },
            onCancel: { cancelEdit() },
            onNavigateDown: {
                descriptionFocused = true
                titleFocused = false
            },
            isFocused: $titleFocused,
            height: $titleHeight
        )
        .frame(height: max(titleHeight, 20))
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isEditing {
                PillTextView(
                    text: $editDescription,
                    links: $editLinks,
                    isEditable: true,
                    isSingleLine: false,
                    font: .systemFont(ofSize: Theme.Font.body),
                    textColor: NSColor.labelColor,
                    placeholderText: "Add description...",
                    onCommit: { commitEdit() },
                    onCancel: { cancelEdit() },
                    onNavigateUp: {
                        titleFocused = true
                        descriptionFocused = false
                    },
                    isFocused: $descriptionFocused,
                    height: $descriptionHeight
                )
                .frame(height: max(descriptionHeight, 18))
            } else if let description = item.description {
                if descriptionHasMarkers {
                    PillTextView(
                        text: .constant(description),
                        links: .constant(item.links),
                        isEditable: false,
                        isSingleLine: false,
                        font: .systemFont(ofSize: Theme.Font.body),
                        textColor: NSColor.labelColor,
                        isFocused: .constant(false),
                        height: $readOnlyDescriptionHeight
                    )
                    .frame(height: max(readOnlyDescriptionHeight, 18))
                } else {
                    Text(description)
                        .font(.system(size: Theme.Font.body))
                        .foregroundStyle(.primary)
                        .lineLimit(isExpanded ? nil : 2)
                }
            }

            // Show link pills in read mode only for items without markers (legacy items)
            if !isEditing && !item.links.isEmpty && !titleHasMarkers && !descriptionHasMarkers {
                FlowLayout(spacing: Theme.Size.linkPillSpacing) {
                    ForEach(item.links) { link in
                        LinkPillView(link: link, tintColor: pastelColor)
                    }
                }
            }

            if isEditing {
                doneButton
            }
        }
    }

    private var doneButton: some View {
        Button(action: commitEdit) {
            HStack(spacing: 4) {
                Text("Done")
                    .font(.system(size: Theme.Font.body, weight: .medium))
                Image(systemName: "return")
                    .font(.system(size: Theme.Font.caption))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(pastelColor.opacity(actionButtonOpacity))
                    .blendMode(.plusLighter)
            }
        }
        .buttonStyle(.plain)
        .transition(.blurResolve)
    }

    private var actionArea: some View {
        let fanned = isActive || isInActionMode
        return HStack(spacing: isInActionMode ? Theme.Size.actionButtonSpacing : 6) {
            unifiedActionButton(icon: "checkmark", label: "Complete", focusCase: .actionComplete(item.id), buttonIndex: 0, action: handleToggle)
                .onKeyPress(.return) {
                    handleToggle()
                    return .handled
                }
                .scaleEffect(isEditing ? 0.01 : 1)
                .frame(width: isEditing ? 0 : nil)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isEditing)
                .offset(x: fanned ? 0 : 64)
                .animation(Theme.Anim.fanOut, value: fanned)
            unifiedActionButton(icon: "pencil", label: "Edit", focusCase: .actionEdit(item.id), buttonIndex: 1, action: startEditing)
                .onKeyPress(.return) {
                    startEditing()
                    return .handled
                }
                .scaleEffect(isEditing ? 0.01 : 1)
                .frame(width: isEditing ? 0 : nil)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isEditing)
                .offset(x: fanned ? 0 : 32)
                .animation(Theme.Anim.fanOut, value: fanned)
            unifiedActionButton(icon: "trash", label: "Delete", focusCase: .actionDelete(item.id), buttonIndex: 2, action: { moveFocusToNeighbor(); onDelete() })
                .onKeyPress(.return) {
                    moveFocusToNeighbor()
                    onDelete()
                    return .handled
                }
                .animation(Theme.Anim.fanOut, value: fanned)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInActionMode)
    }

    private func unifiedActionButton(icon: String, label: String, focusCase: TodoFocus, buttonIndex: Int, action: @escaping () -> Void) -> some View {
        let isVisuallyFocused = visualActionIndex == buttonIndex
        return Button(action: action) {
            HStack(spacing: isVisuallyFocused ? 4 : 0) {
                Image(systemName: icon)
                    .font(.system(size: Theme.Font.body))
                Text(label)
                    .font(.system(size: Theme.Font.caption, weight: .medium))
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.push(from: .leading))
                    .scaleEffect(isVisuallyFocused ? 1 : 0, anchor: .leading)
                    .blur(radius: isVisuallyFocused ? 0 : 4)
                    .opacity(isVisuallyFocused ? 1 : 0)
                    .animation(opacityAnimation, value: isVisuallyFocused)
                    .frame(width: isVisuallyFocused ? nil : 0, alignment: .leading)
            }
            .foregroundStyle(isInActionMode && isVisuallyFocused ? .primary : .secondary)
            .padding(.horizontal, isVisuallyFocused ? 10 : 0)
            .frame(width: isVisuallyFocused ? nil : Theme.Size.actionButtonSize, height: Theme.Size.actionButtonSize)
            .background {
                Circle()
                    .fill(pastelColor.opacity(isInActionMode ? actionButtonOpacity : 0))
                    .blendMode(.plusLighter)
                    .opacity(isVisuallyFocused ? 0 : 1)
                    .animation(opacityAnimation, value: isVisuallyFocused)
                Capsule()
                    .fill(pastelColor.opacity(isInActionMode ? actionButtonOpacity : 0))
                    .blendMode(.plusLighter)
                    .opacity(isVisuallyFocused ? 1 : 0)
                    .animation(opacityAnimation, value: isVisuallyFocused)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInActionMode)
        }
        .buttonStyle(.plain)
        .focusable()
        .focused(focus, equals: focusCase)
        .focusEffectDisabled()
    }

    private var trailingArea: some View {
        ZStack(alignment: .trailing) {
            // Date pill — visible when row is inactive
            Text(item.createdAt.relativeFormat)
                .font(.system(size: Theme.Font.body))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
                .scaleEffect(isActive ? 0.6 : (showTimestamp ? 1.0 : 0.6), anchor: .trailing)
                .blur(radius: isActive ? 4 : (showTimestamp ? 0 : 4))
                .opacity(isActive ? 0 : (showTimestamp ? 1 : 0))
                .animation(opacityAnimation, value: isActive)
                .animation(opacityAnimation, value: showTimestamp)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showTimestamp = true
                    }
                }

            // Action buttons — visible when row is active
            actionArea
                .scaleEffect(isActive || isInActionMode ? 1.0 : 0.6, anchor: .trailing)
                .blur(radius: isActive || isInActionMode ? 0 : 4)
                .opacity(isActive || isInActionMode ? 1 : 0)
                .frame(width: isActive || isInActionMode ? nil : 0)
                .animation(opacityAnimation, value: isActive || isInActionMode)
        }
    }

    private func cycleEmoji() {
        // Pop down with blur
        withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
            emojiScale = 0.5
            emojiBlur = 4.0
        }
        // Swap the emoji while invisible, then pop back in sharp
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            store.randomizeEmoji(id: item.id)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                emojiScale = 1.0
                emojiBlur = 0.0
            }
        }
    }

    private func startEditing() {
        editText = item.title
        editDescription = item.description ?? ""
        editLinks = item.links
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isEditing = true
            onEditingChanged?(true)
            if !isExpanded && (hasExpandedContent || true) {
                onExpand()
            }
        }
        // Focus the title PillTextView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            titleFocused = true
        }
    }

    private func commitEdit() {
        let trimmedTitle = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            cancelEdit()
            return
        }
        store.updateTitleDescriptionAndLinks(
            id: item.id,
            title: editText,
            description: editDescription.isEmpty ? nil : editDescription,
            links: editLinks
        )
        isEditing = false
        titleFocused = false
        descriptionFocused = false
        onEditingChanged?(false)
        focus.wrappedValue = .task(item.id)
    }

    private func cancelEdit() {
        isEditing = false
        titleFocused = false
        descriptionFocused = false
        onEditingChanged?(false)
        focus.wrappedValue = .task(item.id)
    }

    private func moveFocusToNeighbor() {
        if let nextId = nextTaskId {
            focus.wrappedValue = .task(nextId)
        } else if let prevId = previousTaskId {
            focus.wrappedValue = .task(prevId)
        } else {
            focus.wrappedValue = .input
        }
    }

    private func handleToggle() {
        guard !item.isCompleted else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                item.isCompleted.toggle()
            }
            return
        }
        Task { @MainActor in
            // Show celebration
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCheckmarkDraw = true
                showParticleBurst = true
            }
            isCompleting = true
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                item.isCompleted.toggle()
            }
            moveFocusToNeighbor()
            try? await Task.sleep(for: .milliseconds(200))
            isCompleting = false
            showCheckmarkDraw = false
            showParticleBurst = false
        }
    }
}
