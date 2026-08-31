# adityadharacom blog conventions

Repo: `thenomadlad/adityadharacom` (Astro site with CI/CD that auto-publishes on push to `main`).
Local clone, if present, is typically under `~/github.com/thenomadlad/adityadharacom`. If it isn't there, ask the user for the path rather than assuming — don't clone it yourself without asking.

## Where posts live

- Post content: `src/content/blog/<slug>.md`
- Slug = filename without `.md`. Existing slugs use kebab-case, and the "recap of recent work" style posts use a `hotw-NNN-<short-name>` prefix (short for "Hack of the Week") — check `src/content/blog/` for the highest existing `hotw-NNN` number before picking the next one if the post fits that series. A one-off post about a specific repo/topic doesn't need the prefix (e.g. `retrofit-ui.md`, `my-site-runs-on-astro.md`).
- Schema is enforced by `src/content.config.ts` (zod). Required frontmatter fields:
  ```yaml
  ---
  title: "..."
  description: "..."
  pubDate: "Mon D YYYY"   # e.g. "Dec 3 2023" — matches `new Date()`-parseable format used elsewhere
  heroImage: "/path/to/image"
  ---
  ```
- `heroImage` must point to something under `public/` (referenced without the `public` prefix). If there's no dedicated image for the post, fall back to one of the existing generic placeholders already in `public/`: `/blog-placeholder-1.jpg` through `/blog-placeholder-5.jpg`. Pick one that isn't already used by another recent post, and tell the user in your summary that it's a placeholder they may want to swap.

## Tone

Existing posts are first-person, conversational-but-technical dev-log style — they explain *why* something was built, what was learned, and link out to references (docs, videos, related repos) where relevant. They're not changelogs or dry commit lists — turn the raw git activity into a narrative about what was actually accomplished and why it mattered, using the commit messages and diffstat as raw material rather than transcribing them.

## Git workflow for this skill

Work directly in the user's existing local clone — no worktree, no scratch
copy. Git already gives us what we need (branches, stash, status) to do this
safely without a parallel mechanism.

1. `cd` into the repo and run `git status`. Two cases:
   - **Clean working tree**: proceed straight to step 2.
   - **Uncommitted changes present** (the repo commonly has unrelated WIP —
     e.g. a checkout sitting on `blag-retrofit-ui` mid-edit): stop and ask the
     user how to proceed rather than doing anything with those changes on
     their behalf. There are three legitimate answers, not two — offer all of
     them:
     1. Stash the existing changes (`git stash -u`, recoverable), branch off
        `origin/main` fresh, add the post there, leave the stash for the user
        to restore later.
     2. Commit the new post directly into whatever branch is currently
        checked out, combined with the existing uncommitted changes into one
        commit — the user may already consider that branch "theirs" for this
        work and not want it split out. Confirmed as the right default answer
        once in practice, so don't be surprised if this is what they pick.
     3. Stop entirely and let the user commit/stash manually, then re-run the
        skill once clean.
     Never silently stash, discard, or carry uncommitted changes onto a new
     branch without asking first — the point of asking is that only the user
     knows whether that WIP belongs with this post or not.
2. `git fetch origin`, then `git checkout -b blog/<slug> origin/main` —
   branching off `origin/main` specifically (not whatever was checked out)
   keeps the new post independent of any other branch's history.
3. Add the new `src/content/blog/<slug>.md` file (and any hero image under
   `public/blog/<slug>/` if one was supplied), then `git commit` locally.
4. Do **not** `git push`. Pushing triggers the CI/CD publish — that's a
   decision for the user to make after reviewing the draft, not something
   this skill does on its own.
5. If a stash was created in step 1, leave it stashed — don't pop it back
   onto the new branch. Mention it in the final report so the user knows to
   restore it themselves (`git stash pop`) after switching back to their own
   branch.
6. Report back: branch name, file path, and a reminder that review + push is
   a manual next step.
