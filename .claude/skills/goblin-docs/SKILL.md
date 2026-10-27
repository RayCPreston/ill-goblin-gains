---
name: goblin-docs
description: Write and maintain Ill Goblin Gains' documentation in docs/ — systems pages (how the game works today, written from the code), decision records (why it's built this way), and the harvest step that folds a shipped story into those docs before the story is deleted. Use when Ray invokes /goblin-docs, asks to document a system or decision, asks what's out of date in the docs, or when a story has shipped and needs harvesting.
argument-hint: "[audit | <system> | decision <topic> | harvest <story>]"
---

# Goblin Docs

Keeps `docs/` an accurate, readable account of the game, so neither Ray nor Claude has to reverse-engineer the code to know how something works or why.

Request: **$ARGUMENTS**

## The layout

| Folder | Answers | Changes when |
|---|---|---|
| `docs/design/` | What should the game be? (`game-design-doc.md` is the source of truth, plus `traits.md` and `procgen.md`) | Design decisions, made with Ray via `/goblin-design` |
| `docs/systems/` | How does it work **today**? One page per system | Code changes |
| `docs/decisions/` | Why is it this way? Short numbered records | A non-obvious choice is made, or an old one is overturned |
| `docs/stories/` | What's being built right now? | Work starts, or ships and is harvested |

`docs/README.md` is the index. Keep it current whenever pages are added, renamed, or removed.

## Modes

Choose by `$ARGUMENTS`:

### `audit` (or no argument)
Compare the docs to the code and report a short, prioritized list:
- systems with no page;
- pages whose "last verified" commit is old, or which describe code that has since changed (check `git log <sha>..HEAD -- <files the page links>`);
- decisions visible in code or git history but never recorded;
- drift in `CLAUDE.md`'s Current State or `docs/architecture.md`, which are both being replaced by `docs/systems/`;
- stories that shipped but were never harvested.

Then ask Ray what to tackle. Don't write pages in audit mode.

### `<system>`: write or refresh a systems page
Use [systems-page-template.md](systems-page-template.md) and save to `docs/systems/<kebab-name>.md`.
- **Write from the code.** Read the managers, entities, utilities, and signals involved. Treat old docs, `CLAUDE.md`, and stories as leads to check, never as truth.
- **Audience:** Ray first. Lead with plain language about what the player experiences and how it works, then point to the code. Prefer short paragraphs and tables to walls of bullets.
- **Diagrams:** use a Mermaid diagram (GitHub renders it) only when a flow or state machine is clearer drawn than described. Use at most one or two per page.
- **Links:** link to files and symbols with repo-relative paths (`project/autoloads/grid_manager.gd`). Don't paste large code blocks; the page explains, the code is linked.
- **Extending:** include an "Extending it" section showing how to add the next one (another trait, guard type, text effect), following the `/goblin-dev` no-bolt-ons standard.
- **Last verified:** stamp the "Last verified" line with the current short commit SHA and date.
- **Retire superseded content:** when a page fully covers something in `docs/architecture.md` or `CLAUDE.md`'s Current State, remove it from there, leaving a pointer. Once `architecture.md` is empty, delete it.

### `decision <topic>`: record a decision
Use [decision-template.md](decision-template.md) and save to `docs/decisions/NNNN-<kebab-title>.md`, where NNNN is the next free number.
- **Sources:** this conversation, Ray's words, git history, and old stories. Deleted stories are still in git: run `git log --diff-filter=D --format='%h %ad %s' --date=short -- docs/stories` to find them, then `git show <sha>^:<path>` to read one.
- **Rejected alternatives:** record the ones actually considered. Don't invent alternatives nobody discussed.
- **Superseding:** decisions aren't rewritten. When one is overturned, write a new record and set the old one's status to "Superseded by NNNN".
- **Linking:** link the decision from the systems pages it affects.
- **Ray's reasoning:** if the decision is Ray's and the reasoning isn't clear from sources, ask Ray rather than guessing.

### `harvest <story>`: after a story ships
Run this before a shipped story's doc is deleted:
1. Read the story and the code that shipped. They can differ; the code wins.
2. Update or create the affected systems pages, re-verified against the code.
3. Write decision records for any non-obvious choices in the story, or ones made while building it: tuning picks, rejected approaches, and anything that changed from the plan.
4. Move anything still useful from its "Out of scope" and "Open Questions" sections into the relevant systems page's "Not built yet" section, or into `docs/design/` with Ray's OK.
5. Report what was harvested. Ray (or `/goblin-ship`) deletes the story afterward.

## Writing standards

- **Write for a reader who's been away for months.** Define terms at first use (LKP, ALERT ratchet, POI). Don't rely on knowledge of the conversation.
- **Describe what is, not what was.** History belongs in decision records. A systems page should read correctly without knowing the past.
- **Keep it short.** A systems page should take about five minutes to read. Split a page that grows past that.
- **Mark unbuilt things.** Anything not yet built goes under "Not built yet". Never describe a planned feature as if it exists.
- **Don't duplicate content.** If something is documented elsewhere, link to it. The GDD owns design intent, `docs/design/traits.md` owns trait content, and systems pages own current behavior.
- **Line endings:** match the existing file's line endings (some docs are CRLF). New files use LF.

Don't commit. Ray ships via `/goblin-ship`.
