---
name: git-activity-blog-post
description: Turns recent local git commit/branch activity from one or more of the user's repos into a first-person dev-log blog post draft, formatted for and committed (locally only — never pushed) to the thenomadlad/adityadharacom Astro blog, which auto-publishes on push via CI/CD. Use this whenever the user asks to "write a blog post about my work on X", "summarize my github/git activity", "recap what I did this week/month on <repo>", "turn my commits into a blog post", or wants a changelog-style / "hack of the week" write-up of recent coding work for their personal site. Always confirm which repo(s) and what timeframe before gathering data — never silently assume a default window or repo scope.
---

# git-activity-blog-post

## What this does

Reads real git history (commits across all local branches, not just the checked-out
one) from repo(s) the user names, and turns that raw activity into a narrative blog
post draft committed to the `adityadharacom` repo. It never pushes — pushing to that
repo triggers a live-site deploy, and that's the user's call to make after reading
the draft.

## Step 1 — Nail down scope before touching git

This skill only draws from **local git history** (commits, branches) — not the GitHub
API, not PRs/issues. That means it can see unpushed WIP branches, which is often
exactly the interesting material for a dev-log post, but it also means it only knows
about repos that exist as local clones.

Before running anything, you need two things from the user, and neither should be
guessed:

1. **Which repo(s)** — the user must name them. If they say something vague like
   "summarize my work," ask which repo(s) they mean rather than scanning everything
   under `~/github.com`.
2. **What timeframe** — if the prompt doesn't give one (a date, "since my last post",
   "this week," a branch name to diff against, etc.), ask. Don't default to "last 7
   days" or "since last post" on your own — the right window depends on what the user
   actually wants to write about, and guessing wrong wastes a full draft cycle.

Resolve each repo name to a local path (commonly `~/github.com/<owner>/<repo>` on
this machine). If you can't find a local clone for a named repo, say so and ask for
the path — don't fall back to fetching from the GitHub API instead, since the user
specifically chose local git history as the source for this skill.

## Step 2 — Gather the activity

For each resolved repo, run:

```
scripts/gather_activity.sh <repo_path> <since> [until]
```

This prints, across **all** local branches: commits in range (hash, date, author,
subject), which branches had activity in the window, and an aggregate diffstat. Using
`--all` matters — a branch that never got merged is often the most interesting story
(an experiment, an abandoned approach, a fix still in review).

Read the actual commit messages and diffstat, don't just glance at counts. If the
picture is thin or confusing (e.g. one giant "wip" commit with no other signal), say
so and ask the user for more color rather than inventing a narrative to fill the gap.

## Step 3 — Learn the target repo's conventions

Read `references/adityadharacom-conventions.md` before drafting anything — it covers
the exact frontmatter schema, file naming, the `hotw-NNN` recap series convention,
hero image fallback, tone, and the required git workflow (branch off `origin/main`,
commit locally, never push). Skipping this step is the most likely way to produce a
draft that doesn't build (schema mismatch) or clobbers the user's other WIP branch.

## Step 4 — Draft the post

Turn the commits and diffstat into a first-person narrative — what was built, why,
what was learned or is still unresolved — in the voice of the existing posts in
`src/content/blog/`. Skim 1-2 recent posts there for tone before writing if you
haven't already. This is a story about the work, not a reformatted commit log; the
raw git data is material, not the output.

## Step 5 — Commit locally, don't push

Work in the user's existing clone directly — check `git status` first. If it's
dirty (there's often unrelated WIP sitting on another branch), stop and ask how
to proceed instead of touching those changes yourself; don't assume stashing is
fine just because it's reversible. Once clear to proceed, follow the git
workflow in the conventions reference exactly: fetch, branch off `origin/main`
as `blog/<slug>`, add the new file(s), commit. Then stop — no push.

Tell the user: the branch name, the file path, and that review + push is manual
because a push here goes live immediately via CI/CD.
