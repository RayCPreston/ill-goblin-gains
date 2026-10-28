---
name: goblin-ship
description: Ship finished work in Ill Goblin Gains in two halves. First, put it on a feature branch, commit, push, and hand Ray a pre-filled PR link plus description. Ray opens and squash-merges the PR on GitHub. Then, once Ray confirms the merge, verify it landed, reset the local checkout to an up-to-date master, and delete the stale branch. Use when Ray invokes /goblin-ship, asks to ship or land the current work, or says a shipped PR is merged. Invoking it is Ray's go-ahead to commit and push; it still stops on any failed check or ambiguity.
argument-hint: "[PR title or branch name]"
---

# Goblin Ship

Takes what's in the working tree, or on the current feature branch, to a pushed branch with a PR ready for Ray to merge. After Ray confirms the merge, it leaves Ray on a clean, current `master`.

Optional PR title or branch name: **$ARGUMENTS**

**Ray does the merge.** There's no GitHub API access here. The deploy key covers git (fetch, push, branch deletes) but not pull requests, so Ray opens and squash-merges the PR in the browser. Never push to `master` directly, and never try to merge on Ray's behalf.

## Remote access

Pass the deploy key on every remote command. Never put it in git config. Each Bash call starts a fresh shell, so set it in the same call:

```bash
export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_claude_treasure_goblin -o IdentitiesOnly=yes -o BatchMode=yes"
```

The GitHub repo is `RayCPreston/ill-goblin-gains`. It was renamed from `treasure-goblin`, and the local `origin` URL may still use the old name, which GitHub redirects.

## Which half to run

Run `git fetch --prune origin`, then check `git status` and the current branch.

- **Uncommitted changes, or local commits not yet pushed:** run the first half (steps 1–4).
- **On a feature branch that's already pushed with nothing new, or Ray says the PR is merged:** run the second half (steps 5–7).
- **Clean `master`, nothing ahead of origin:** nothing to ship, so say so and stop.

## First half: get it ready to merge

### 1. Work out what's shipping

- **On a feature branch:** ship that branch, plus any uncommitted changes that belong to it.
- **On `master` with uncommitted changes:** fast-forward `master` to `origin/master` if it's behind (`git merge --ff-only origin/master`; uncommitted changes carry over). Then create the branch with `git checkout -b <name>`. Naming:
  - `feature/<kebab-name>` for features;
  - `feature/trait-<name>` for trait stories;
  - `fix/<kebab-name>` for bug fixes.
  - Use `$ARGUMENTS` if it names a branch.

If the uncommitted changes mix unrelated work (e.g. a finished story next to half-done skill files), show Ray the groups and ask which ship now. Whatever isn't shipped stays uncommitted and carries over to `master` at the end.

If the work completes a story whose doc is still in `docs/stories/`, offer to harvest it first (`/goblin-docs harvest <story>`: what was built goes into `docs/systems/`, notable choices into `docs/decisions/`), then delete the doc in this ship. Never delete an unharvested story without Ray's say-so.

### 2. Preflight: stop and report if any check fails

1. No `TEMP-` scaffolding: `grep -rn "TEMP-" project/` comes back empty.
2. The game still loads: `& ".claude/skills/goblin-dev/drive-game.ps1" headless` shows nothing but the version banner. Run it from PowerShell.
3. Nothing personal or secret is staged: no `.claude/settings.local.json` (it's gitignored, but check), no keys, tokens, or credentials.
4. You're not on `master`.

### 3. Commit and push

- Group the changes into logical commits: implementation, docs, and "Delete completed <name> story" each separate. Already-committed work stays as it is.
- Stage files by explicit path. Never `git add -A` or `git add .`.
- Write each message to a file in the scratchpad and run `git commit -F <file>`. Never pass messages as heredocs chained with `&&`; that has mangled messages before.
- Use a sentence-case subject (`Add 'Allergies' trait with on_turn_end alert burst`), an optional bullet body, and end with the attribution line from the system reminder.
- Push with `git push -u origin <branch>`, with `GIT_SSH_COMMAND` set.

### 4. Hand Ray the PR, then stop

Write two things:
- **The PR title:** `$ARGUMENTS` if given; otherwise a sentence-case summary of the whole change. It becomes the squash commit's subject.
- **The PR description:** a short summary of what changed, how it was verified, and any follow-ups. End it with the PR attribution line from the system reminder.

Build a link that opens GitHub's PR form already filled in. URL-encode the title and body (e.g. Python's `urllib.parse.quote`):

```
https://github.com/RayCPreston/ill-goblin-gains/compare/master...<branch>?expand=1&title=<title>&body=<body>
```

Give Ray the link, plus the description in a fenced block in case the pre-fill gets lost. Tell Ray to merge with **Squash and merge** and to say when it's done.

**Then stop.** Don't delete branches, switch to `master`, or pull until Ray confirms the merge.

## Second half: after Ray confirms the merge

### 5. Verify the merge actually landed

Fetch (`git fetch --prune origin`), then confirm `origin/master` contains the work:
- `git log origin/master -5 --format='%h %s'` shows the squash commit ("<title> (#N)").
- `git diff <branch> origin/master -- $(git diff --name-only $(git merge-base <branch> origin/master) <branch>)` is empty. In other words, every file the branch touched is identical on `master`.

If the squash commit isn't there, or those files differ, stop and show Ray what you found. Don't delete anything. A file can legitimately differ if `master` changed it again after the merge; ask rather than assume.

### 6. Reset local to master and clean up

```bash
export GIT_SSH_COMMAND="..."
git push origin --delete <branch>   # only if it still exists on GitHub (Ray may have deleted it from the PR page)
git checkout master
git pull --ff-only origin master
git branch -D <branch>
git fetch --prune origin
```

- `-D` is required because a squash merge never looks "merged" to git. It's safe only because step 5 confirmed the work is on `master`, so never run it without that confirmation.
- If `git checkout master` refuses because of unshipped uncommitted changes that conflict, stop and ask. Don't stash or discard Ray's work on your own.

### 7. Report

Keep it short:
- the squash commit that's now `master`'s head;
- confirmation that the remote and local branches are deleted;
- anything left uncommitted in the working tree.
