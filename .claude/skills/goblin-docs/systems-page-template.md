# <System Name>

<One or two sentences: what this system does for the player, in plain language.>

## How it works

<Plain-language explanation of the mechanism. Start from what happens during a turn, then go down a level. Add a Mermaid diagram only if a flow or state machine is clearer drawn than described.>

## Key pieces

| Piece | Where | Role |
|---|---|---|
| `<Manager / Class>` | [`project/...gd`](../../project/...gd) | <what it owns> |
| `<signal_name>` | `<emitter>` → `<listeners>` | <what it announces> |

## Extending it

<How to add the next one (another trait, guard type, text effect…): which data or extension point to touch, following the no-bolt-ons standard. Link a real example where one exists.>

## Gotchas

- <Non-obvious behavior or constraint, linking the decision record that explains it: [NNNN](../decisions/NNNN-title.md)>

## Not built yet

- <Planned or deferred pieces, linking the GDD section or story where they're defined.>

---
*Last verified against code: `<short sha>` on <YYYY-MM-DD>.*
