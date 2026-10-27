# Ill Goblin Gains: Docs

Where to look, depending on the question:

| Question | Folder |
|---|---|
| What should the game be? | [`design/`](design/) |
| How does it work today? | [`systems/`](systems/) |
| Why is it built this way? | [`decisions/`](decisions/) |
| What's being built right now? | [`stories/`](stories/) |

## Design: intent

- [Game Design Document](design/game-design-doc.md): **source of truth** for mechanics, world, guards, security, and juice.
- [Traits](design/traits.md): every trait's data definition, the effect-kind schema, and the property reference.
- [Procedural generation](design/procgen.md): early notes; not implemented yet.

## Systems: current behavior

One page per system, written from the code and stamped with the commit it was last verified against. Being populated. Until a system has a page here, [`architecture.md`](architecture.md) and `CLAUDE.md`'s Current State are the fallback; both shrink as pages land.

*No pages yet.*

## Decisions: the why

Short numbered records: context, decision, alternatives, consequences. Decisions aren't rewritten; an overturned one is marked superseded by a newer record.

*No records yet.*

## Stories: work in flight

Specs for work being built. When a story ships, it's **harvested**: what was built goes into `systems/`, notable choices go into `decisions/`, and then the story is deleted.

## Maintaining these docs

- `/goblin-docs` audits the docs against the code and suggests what to write or refresh.
- `/goblin-docs <system>` writes or refreshes a systems page.
- `/goblin-docs decision <topic>` records a decision.
- `/goblin-docs harvest <story>` folds a shipped story into the docs.
- `/goblin-design` writes stories, and `/goblin-ship` offers a harvest before deleting a finished one.
