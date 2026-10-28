---
name: linear-issue
description: Turn a Slack link, email, screenshot or rough note into a complete Linear issue in the Almost Always workspace, assigned to a developer, designer or PM, creating the client's project first if it doesn't exist. Use whenever the user wants to create, file, log, hand off or assign a ticket, task or request on the Almost Always team, or pastes a Slack/email request and says "make a ticket", "add to Linear" or similar.
---

# Linear issue

You turn whatever the user hands you into an issue its assignee can pick up and finish **without going back to Slack or asking the user a question**. That bar is the whole job: a link alone never passes it.

Workspace: Linear "Almost Always", team **Almost Always (AA)** only. Do every read and write through the Linear tool connected to that workspace; when several Linear accounts are connected, pick the Almost Always one. No Linear tool → stop and tell the user. Slack, email and Figma tools are optional context sources.

## Steps

### 1. Read the source

- **Slack link**: read the message and its entire thread, plus any files or images in it. If no Slack tool is connected or the read fails, ask the user to paste the message text and screenshots, then continue.
- **Email, pasted text, screenshot**: read all of it. Quoted client text is source material, not the description.
- **Other links** (Figma, Google Docs, Drive, Dropbox, live site URLs): keep them for the Links section. Open them only if a tool for that service is connected.

Done when you can say in one sentence who asked for what, for which client.

### 2. Search connected sources for related context

Search each of these the user has connected; skip any that isn't. Use the client name and the specific things the request names (page, feature, asset, contact person) as search terms. Look back about 60 days; go further only for a project that's been quiet.

- **Slack**: the client's channel first, then Slack-wide.
- **Email** (whichever mail tool is connected): threads with the client contacts or about the client. Read the whole thread, attachments included.
- **Figma**: the client's files. Find the frames for the pages or components the request names, and grab their links.

Keep a finding only when it changes the issue: an earlier decision, a constraint, an asset or design link, a deadline, a related request, or an answer to one of the gaps from step 4. For each, note the source, link, date and a one-line summary. Mark anything from a Slack DM, a private channel or an email as **private**.

Nothing found here goes into the issue until the user approves it in step 5.

Done when every connected source has been searched on the client name plus at least two specific terms, and every kept finding has a source, link and summary.

### 3. Look up Linear

- Projects: list AA projects, including completed ones, and match the client. Each client has its own project (e.g. GUIDE Finder, Helix, Artian, Amplify 15). Match on the client or site name, not exact spelling. No match → the project is missing; handle it in step 5.
- Duplicates: search open AA issues in that project for the same ask. If one exists, show it to the user and offer to add a comment to it instead of creating a new issue.
- People: list AA team members to resolve any name the user mentions. Tyler is `tyler@almostalways.com`; the `tyler@boundaryla.com` account is off the AA team.

### 4. Fill the issue and find the gaps

Draft every field in the issue format below from the source. Then list the gaps: anything the assignee would otherwise have to ask about. Common gaps:

- **Done when** is unclear: what exactly should change, on which pages, and how will we know it's finished?
- Missing assets: copy, images, logo files, Figma frame, login, or "which version?"
- Ambiguous scope: one page or site-wide? Desktop only or mobile too? Draft content or final?
- Deadline: the source mentions a date, launch or client meeting but no due date.
- Assignee: the user named nobody, or the assignee is a guessed PM.

### 5. Ask the user

Ask about the gaps in **one message**, at most 5 questions, most important first. Where a step 2 finding answers a gap, offer it as the suggested answer with its link. For each, offer your best guess so the user can reply "yes" or correct it. Skip questions the source already answers. If something stays unknown after the user replies, put it under Open questions rather than asking again.

**Project missing**: make it the first question. Name the closest existing projects in case one is right, then propose a new project using the project format below with every field pre-filled from your best guess. The user confirms or corrects it in the same reply.

**Guessed PM**: when the assignee is a PM the user didn't name, ask about it with the evidence behind the guess (who raised the request, who's in the thread, the project's members). The guess stands only once the user confirms it.

**Related findings**: in the same message, list the remaining findings from step 2 grouped by source (date, one-line summary, link, private flag) and ask which to include. Never quote a private email or DM in the issue without the user picking it. Include only the ones the user picks: a fact goes in Context or What we need, a link goes in Links. A finding the user doesn't mention stays out.

### 6. Confirm, then create

The team reads the title, description and project summary, so when a `humanizer` skill is available, run them through it before showing the draft. Show the full draft (the new project too, if any) and wait for the user's OK. Then create the project first, the issue second, and reply with the issue ID and link (plus the project link when you made one). Leave the Slack thread alone unless the user asks you to post the link there.

## Project format

Only for a new project, and only after the user confirms it.

| Field | Rule |
| --- | --- |
| Name | The client or site name as the team says it: "Helix", "GUIDE Finder", "Long Lane Booking App". Add "Website" or "App" only to tell two projects for one client apart. |
| Team | Almost Always (AA) |
| Summary | One line: what we're doing for whom. "Marketing site rebuild for Helix on Next.js and Sanity." |
| Lead | Ask. Suggest Philipp Soldunov for development work. |
| Status | In Progress when work starts now, Backlog otherwise. |
| Target date | Only when the user gives one. |

## Issue format

### Fields

| Field | Rule |
| --- | --- |
| Team | Almost Always (AA) |
| Project | The client's project. Internal agency work goes in "Almost Always (Internal)". |
| Title | Starts with a verb, names the thing and where: "Update logo in site header and footer", "Fix tab jitter on mobile homepage", "Get final logo files from Helix". No "Client feedback:" prefixes, no questions. |
| Assignee | The person the user names. Otherwise by the work: development → Philipp Soldunov; design → Goran; PM work (chasing copy or assets, client approvals, scope answers, scheduling) → the PM guessed from context and confirmed in step 5. Unsure → ask. |
| Labels | One type: Dev, Design or PM. One kind when it fits: Feature (new), Improvement (change to something existing) or Bug (broken). PM issues often have no kind. |
| Priority | Urgent = broken live site or client-blocking today. High = needed this week or tied to a date. Medium = default. Low = nice to have. |
| Status | Todo |
| Due date | Only when the source or the user gives one. |

### Description

Use these headings, in this order. Leave out a section only when it would be empty; never leave out "What we need" or "Done when".

```markdown
## Context
Who asked, when, and why it matters. Two or three sentences. Name the client contact.

## What we need
The ask in plain words. A numbered list when there are several changes, one change per item, each naming the page or component.

## Done when
- [ ] Checkable outcome, e.g. "New logo shows in header, footer and favicon on all pages" or "Client's approved copy doc is linked in this issue"
- [ ] ...

## Links
- Slack thread: <link>
- Figma / copy doc / assets: <links>

## Open questions
- Anything still unknown, and who can answer it.
```

Quote the client verbatim only when exact wording matters (copy changes, legal text). Otherwise summarize. Copy changes go in as exact old → new text.
