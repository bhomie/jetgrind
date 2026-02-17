# ADHD-Friendly Feature Ideas

Five research-backed ideas for making JetGrind work better for people with ADHD.

---

## 1. Task Spotlight Mode

Show only 1–3 tasks at a time instead of the full list to prevent overwhelm.

**Why it works:**

- Large task lists trigger "task paralysis" — seeing everything at once causes prioritization confusion and fatigue ([Effectiveness and Challenges of Task Management Apps for ADHD](https://pressbooks.pub/thealttext/chapter/effectiveness-and-challenges-of-task-management-apps-for-students-with-adhd-a-focus-on-task-organization-and-time-management/))
- Apps like Llama Life and Sunsama succeed by surfacing only the current task ([5 To-Do List Apps That Actually Work with ADHD – Zapier](https://zapier.com/blog/adhd-to-do-list/))
- Reducing visible items cuts cognitive load significantly ([12 Best Productivity Apps for ADHD – Fluidwave](https://fluidwave.com/blog/productivity-apps-for-adhd))

**Implementation:**

- Add `isSpotlightMode: Bool` to `TodoStore` (persisted in UserDefaults)
- In `TodoListView`, filter `incompleteItems` to show only the first N items when spotlight is on
- Toggle via a small icon button near the top + keyboard shortcut
- When a spotlighted task is completed, the next task slides in

**Files:** `TodoStore.swift`, `TodoListView.swift`, `Theme.swift`

**Dependencies:** None — self-contained feature.

---

## 2. Streak & Micro-Reward System

Build on existing confetti/particle animations with persistent rewards: daily streaks, a running completion counter, and variable surprise celebrations.

**Why it works:**

- 2025 MDPI study: gamified interventions reduced ADHD symptom scores by 8.13 points over 4 weeks ([Digital Therapeutic Interventions for ADHD – MDPI](https://www.mdpi.com/2076-3417/15/2/788))
- ADHD brains have lower dopamine activity; variable, immediate rewards trigger stronger dopamine release than predictable ones via "reward prediction error" ([ADHD Reward System for Adults – Neurolaunch](https://neurolaunch.com/adhd-reward-system-for-adults/))
- 2024 Frontiers study: 8-week gamified intervention improved attention and academic performance ([Frontiers in Education](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2025.1668260/full))
- Small, frequent rewards outperform single large rewards for ADHD motivation ([Gamification in ADHD Therapy – Medium](https://medium.com/@ulucyuca/gamification-a-powerful-tool-in-adhd-therapy-347a13769c8d))

**Implementation:**

- Add to `TodoStore`: `currentStreak: Int`, `lastCompletionDate: Date?`, `totalCompleted: Int`
- Streak logic: increment if tasks completed today, reset if a day is missed
- Variable reward: on ~every 5th completion (randomized), trigger a special animation variant
- Display streak counter near the completed pill or as a small persistent badge
- Milestone celebrations at streak thresholds (3, 7, 14, 30 days)

**Files:** `TodoStore.swift`, `TodoListView.swift`, `ConfettiView.swift`, `Theme.swift`

**Dependencies:** None — extends existing animation infrastructure.

---

## 3. Built-in Pomodoro Timer with Time Awareness Cues

Embed a lightweight countdown timer with gentle visual pulses as time passes, addressing ADHD time blindness.

**Why it works:**

- Time blindness is caused by prefrontal cortex differences affecting time perception ([Time Blindness and ADHD – U.S. News](https://health.usnews.com/wellness/mind/articles/time-blindness-adhd-productivity-tools))
- Visual time mapping makes temporal flow tangible, counteracting the "silent clock" problem ([42 Time-Management Apps for ADHD – ADDitude Magazine](https://www.additudemag.com/punctuality-time-blindness-adhd-apps-tips/))
- Pomodoro technique with visual timers is consistently recommended for ADHD time management ([Time Management for ADHD – Study Hub](https://blogs.ed.ac.uk/studyhub/2025/01/21/time-management-for-adhd-2/))
- Time perception training apps show measurable improvement in time estimation skills ([Brili – ADHD Time Management](https://brili.com/))

**Implementation:**

- New `PomodoroTimer` observable class: `timeRemaining`, `isRunning`, `sessionType` (work/break)
- Default: 25min work / 5min break (configurable)
- `PomodoroView` widget at the bottom of `TodoListView` — minimal: circular progress ring + time label
- Gentle visual pulse on the ring every 5 minutes (time awareness cue)
- Keyboard shortcut to start/pause/reset (e.g., `Cmd+P`)
- Optional: associate timer with the currently focused task

**New files:** `Models/PomodoroTimer.swift`, `Views/PomodoroView.swift`
**Modified files:** `TodoListView.swift`, `TodoStore.swift`, `Theme.swift`

**Dependencies:** Most complex idea. Build after ideas 1 and 2 since it introduces new models and views.

---

## 4. One-Click Task Breakdown

Let users break a task into sub-steps with a single keystroke, bypassing "where do I start?" paralysis.

**Why it works:**

- Task breakdown is consistently rated the #1 ADHD productivity technique across studies ([Selfcare Strategies for Adults with ADHD – Tandfonline](https://www.tandfonline.com/doi/full/10.1080/01612840.2023.2234477))
- Breaking tasks into small, measurable chunks bypasses chronic procrastination ([Best ADHD-Friendly Todo Apps – NotePlan](https://noteplan.co/blog/best-adhd-friendly-todo-apps))
- 2024 systematic review of 136 studies confirms structured task decomposition improves executive function outcomes ([Treating Executive Function in Youth With ADHD – SAGE](https://journals.sagepub.com/doi/10.1177/10870547231218925))
- AI-powered task breakdown is the fastest-growing feature in ADHD apps (22% of 2024 launches)

**Implementation:**

- Add `subtasks: [SubTask]` array to `TodoItem` (where `SubTask` has `id`, `title`, `isCompleted`)
- Keyboard shortcut on a focused task (e.g., `Tab` or `Cmd+Enter`) creates a new subtask underneath
- Subtasks render as indented rows below the parent, with their own checkboxes
- Parent task shows progress indicator (e.g., "2/4" or a small progress bar)
- Completing all subtasks auto-completes the parent (with the full confetti celebration)

**Files:** `TodoItem.swift`, `TodoStore.swift`, `TodoRowView.swift`, `TodoFocus.swift`, `Theme.swift`

**Dependencies:** Requires careful focus state management. Keep subtask views in the tree and control visibility with opacity (not conditional rendering) to avoid breaking `@FocusState`.

---

## 5. Energy-Based Priority Tags

Replace traditional priority with energy-aware labels like "Quick Win," "Deep Focus," and "Low Energy" that match fluctuating ADHD cognitive states.

**Why it works:**

- 2024 HITL framework: effective ADHD tools should adapt to energy and attention cycles rather than imposing rigid priority schemes ([Neurodivergent-Aware Productivity Framework – arxiv](https://arxiv.org/html/2507.06864v1))
- ADHD brains have fluctuating cognitive states throughout the day; matching tasks to energy levels improves completion rates ([ADHD Context Switching – Focus Bear](https://www.focusbear.io/blog-post/adhd-context-switching-strategies-for-smoother-transitions))
- Apps that accommodate diverse attention patterns outperform one-size-fits-all systems ([ADHD Planner – Lunatask](https://lunatask.app/adhd))
- Grouping tasks by cognitive demand reduces context-switching cost ([Task Switching & ADHD – NoPlex](https://www.noplex.ai/task-switching-adhd))

**Implementation:**

- Add `EnergyTag` enum: `.quickWin`, `.deepFocus`, `.lowEnergy` (+ `nil` for untagged)
- Add `energyTag: EnergyTag?` to `TodoItem`
- Keyboard shortcut on focused task to cycle tags (e.g., `E` key)
- Visual: small colored dot or icon next to the task title
- Optional: sort/filter by tag, or show tag-grouped sections

**New file:** `Models/EnergyTag.swift`
**Modified files:** `TodoItem.swift`, `TodoStore.swift`, `TodoRowView.swift`, `Theme.swift`

**Dependencies:** None — lightweight addition to the data model.

---

## Suggested Build Order

1. **Task Spotlight Mode** — smallest scope, immediate impact
2. **Streak & Micro-Rewards** — extends existing animations
3. **Energy-Based Priority Tags** — lightweight data model change
4. **One-Click Task Breakdown** — more complex focus/data model work
5. **Pomodoro Timer** — largest scope, new models and views

