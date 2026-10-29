# Stories

A story is the spec for one piece of work in flight: a feature, trait, mechanic, guard behavior, or bit of juice. It says what the player should experience and how anyone can tell it's done. It doesn't say how to write the code.

Stories are temporary. Once one ships, what it built is described in [`systems/`](../systems/) and the reasons behind it in [`decisions/`](../decisions/), and the story is deleted. This folder only ever holds work that's still open, so an empty folder means nothing is in flight.

## Where a story fits

| Folder | Answers |
|---|---|
| [`design/`](../design/) | What should the game be? The GDD is the source of truth. |
| **`stories/`** | **What are we building next, and when is it done?** |
| [`systems/`](../systems/) | How does it work today? |
| [`decisions/`](../decisions/) | Why is it built this way? |
| [`bugs/`](../bugs/) | What's broken? Bugs get their own files, not stories. |

A story turns part of the design into a concrete, testable chunk of work. It must never quietly contradict the GDD. If a design session changes the design, the GDD is edited too, with Ray's OK.

## Lifecycle

1. **Design.** Ray and Claude work it out from the player's point of view in `/goblin-design`, and the result is written here.
2. **Build.** `/goblin-dev <story>` implements it and treats the story as the spec. The build is verified by running the game against the acceptance criteria. Anything that changes along the way is reported back and recorded as a decision.
3. **Harvest.** `/goblin-docs harvest <story>` folds what shipped into the systems pages, writes decision records for non-obvious choices, and moves deferred ideas to a systems page's "Not built yet" section.
4. **Delete.** The story is deleted in its own commit, in the same ship as the work (`/goblin-ship`). Old stories stay readable in git history:

   ```bash
   git log --diff-filter=D --format='%h %ad %s' --date=short -- docs/stories
   ```

## Naming

- `<kebab-case-name>.md` for most stories, e.g. `furniture-hiding.md`.
- `trait-story-NN-<name>.md` for trait stories, numbered in the order they're written.
- An **epic** is a story that groups several smaller ones under a shared goal and the architecture they all follow. It stays until its last child story ships, and is harvested with it.

## Format

New stories start from the [story template](../../.claude/skills/goblin-design/story-template.md). Each section has a job:

| Section | Its job |
|---|---|
| **Context** | Why this exists now. Which GDD sections it implements, which stories or decisions it builds on, and anything Ray settled during design (numbers, names, cut ideas). |
| **Player Experience** | The moment as the player lives it, turn by turn: what they see, hear, and decide. This is what the work is judged against. |
| **Readability** | How the play area stays clear: what draws where, for how long, above or below what. What it must never cover or reveal (fog of war, guard state colors). How it stacks with other effects on the same turn. |
| **Goal** | One paragraph: what's true when this ships. |
| **Scope** | What's in, and what's deliberately out. Each deferred idea gets a one-line reason, so it isn't lost. |
| **Acceptance Criteria** | The bar for "done" (below). |
| **Technical Notes** | Only what keeps the implementer on track: the systems involved, the conventions that apply, and the tuning values that should become named constants. Not a pre-written implementation. |
| **Open Questions** | Feel and tuning questions to settle after seeing it run. |

Not every story needs every section. A small trait story might be a definition, a paragraph, and the criteria. Never skip the acceptance criteria.

## Acceptance criteria

Acceptance criteria are how anyone, Ray or Claude, decides a story is done without arguing about it. Good ones are:

- **Observable.** Each one can be checked by playing the game or by a headless run, e.g. "while asleep, a move input spends a turn and the goblin stays put". If the only way to check it is reading the code, rewrite it, unless it's a structural rule that really matters, like "no branching on trait ids outside `GameData`".
- **Numbered**, so a build report can say which ones were observed and how.
- **About behavior, not feel.** "Shows small text when it fires" is a criterion; "the text feels cozy" is an open question.
- **Inclusive of readability.** At least one criterion covers the play area staying clear, e.g. "a guard's cone stays visible under the effect" or "nothing appears for a guard the player can't see".
- **Explicit about what's excluded.** If a piece is out of scope for this story (e.g. juice), say so in the criteria, so nobody wonders whether it's missing.

During a build, every criterion that can be observed gets observed. When the build has to deviate from one, the report says so and why, and the change is recorded as a decision, not left as a silent mismatch.
