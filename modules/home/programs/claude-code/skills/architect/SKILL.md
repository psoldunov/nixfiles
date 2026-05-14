---
name: architect
description: >
  Create a comprehensive architectural plan for the current project or a specific feature/system.
  Use this skill when a user wants to design system architecture, plan a new project structure,
  evaluate technical trade-offs, create Architecture Decision Records (ADRs), or needs guidance
  on scalability, modularity, and technical design. Trigger on phrases like "architect this",
  "design the architecture", "system design", "how should I structure this", "technical design",
  "plan the architecture", "ADR", "architecture decision", "scalability plan", "what patterns
  should I use", or any request involving high-level technical planning and design decisions.
  When in doubt, use this skill — a structured architectural plan prevents costly rework later.
---

# Architect Skill

A skill for producing comprehensive architectural plans by leveraging the `architect` agent
to analyze the current project and deliver actionable design guidance.

---

## Process

### Step 1: Gather Context (MANDATORY — Do Not Skip)

Before invoking the architect agent, you MUST thoroughly understand the project. This step is
an interactive conversation with the user — do NOT rush to produce a plan.

**1. Auto-detect what you can:**
   - Read the project root for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
     `CLAUDE.md`, or similar manifest files
   - Identify the tech stack, frameworks, and language(s)
   - Scan directory structure for existing architecture patterns
   - Check for existing docs, READMEs, ADRs, or design documents

**2. Interview the user ONE question at a time.** Use AskUserQuestion for each question.
   Ask about anything that is not already clear from the codebase or the user's initial
   request. Wait for the user's answer before asking the next question. Skip questions
   whose answers are already obvious from the codebase or prior answers.

   IMPORTANT: Do NOT dump multiple questions at once. Ask ONE question, wait for the
   response, then decide what to ask next based on the answer. Adapt your questions
   dynamically — if an answer covers multiple dimensions, skip the redundant questions.

   Cover these dimensions as needed (not every question is required — use judgment):

   **Project Vision & Scope:**
   - What is the project's core purpose and who are the target users?
   - Is this greenfield, a rewrite, or an evolution of existing code?
   - What is the scope — entire project, a specific feature, or a subsystem?
   - What does success look like? What are the key outcomes?

   **Functional Requirements:**
   - What are the primary user flows and features?
   - What data does the system manage? What are the core domain entities?
   - What external systems, APIs, or third-party services must it integrate with?
   - Are there real-time requirements (websockets, SSE, push notifications)?
   - What authentication/authorization model is needed?

   **Non-Functional Requirements:**
   - What are the performance targets (latency, throughput, response times)?
   - What is the expected scale (users, requests/sec, data volume) at launch and in 1-2 years?
   - What are the availability/uptime requirements?
   - Are there compliance or regulatory constraints (GDPR, HIPAA, SOC2)?
   - What are the security requirements beyond standard best practices?

   **Team & Constraints:**
   - What is the team size and their technical expertise?
   - Are there technology constraints (must use X, cannot use Y)?
   - Are there budget or infrastructure constraints (cloud provider, self-hosted)?
   - What is the timeline? MVP vs. long-term product?
   - Are there existing architectural decisions that MUST be preserved?

   **Deployment & Operations:**
   - Where will this be deployed (cloud provider, edge, on-prem)?
   - What CI/CD and deployment patterns are in use or preferred?
   - What monitoring, logging, and observability tools are in use?
   - What is the testing strategy (unit, integration, e2e)?
   - How are database migrations and schema changes handled?

   **Existing Architecture (if not greenfield):**
   - What are the current pain points and bottlenecks?
   - What has been tried before and didn't work?
   - What parts of the current architecture MUST be kept?
   - Are there known areas of technical debt?

   Stop interviewing when you have enough context to produce a useful plan. Not every
   dimension needs deep coverage — match the depth to the complexity of the request.

**3. Summarize your understanding back to the user** before proceeding. List what you know
   and what assumptions you are making. Get explicit confirmation before moving to Step 2.
   If the user corrects or adds information, update your understanding and re-confirm.

### Step 2: Invoke the Architect Agent

Use the `architect` agent (subagent) to perform the analysis. Provide it with:
- The project path and relevant files to examine
- The user's specific architectural question or goal
- Any constraints or requirements gathered in Step 1

The architect agent will follow its own review process:
1. **Current State Analysis** — review existing architecture, identify patterns, document tech debt
2. **Requirements Gathering** — functional, non-functional, integration points, data flow
3. **Design Proposal** — architecture diagram, component responsibilities, data models, API contracts
4. **Trade-Off Analysis** — for each decision: Pros, Cons, Alternatives, Decision rationale

### Step 3: Deliver the Architectural Plan

Structure the output as follows:

---

#### Overview
Brief summary of the project, its current state, and the architectural goal.

#### Current Architecture Assessment
- Tech stack and framework analysis
- Existing patterns identified
- Technical debt and pain points
- Scalability limitations

#### Proposed Architecture
- High-level system design
- Component responsibilities and boundaries
- Data flow and integration points
- API contracts (if applicable)

#### Architecture Decision Records (ADRs)
For each significant decision, use this format (matches the architect agent's ADR template):
- **Context**: Why this decision is needed
- **Decision**: What was chosen
- **Consequences**:
  - **Positive**: Benefits and advantages
  - **Negative**: Drawbacks and limitations
- **Alternatives Considered**: Other options evaluated with brief rationale for rejection
- **Status**: Proposed / Accepted / Deprecated / Superseded
- **Date**: When the decision was made

#### Red Flags Check
Review the architecture for these anti-patterns (from the architect agent's checklist):
- Big Ball of Mud, Golden Hammer, Premature Optimization
- Not Invented Here, Tight Coupling, God Object
- Magic (unclear, undocumented behavior)
- Analysis Paralysis (flag if the plan itself is over-engineered)

#### System Design Checklist
Verify completeness against:
- [ ] User stories / use cases documented
- [ ] API contracts defined
- [ ] Data models specified
- [ ] UI/UX flows mapped
- [ ] Performance targets defined (latency, throughput)
- [ ] Scalability requirements specified
- [ ] Security requirements identified
- [ ] Availability targets set (uptime %)
- [ ] Architecture diagram created
- [ ] Component responsibilities defined
- [ ] Data flow documented
- [ ] Integration points identified
- [ ] Error handling strategy defined
- [ ] Testing strategy planned
- [ ] Deployment strategy defined
- [ ] Monitoring and alerting planned
- [ ] Backup and recovery strategy
- [ ] Rollback plan documented

#### Implementation Roadmap
Sequenced phases for adoption:
1. **Phase 1 - Quick wins**: Low-effort, high-impact changes
2. **Phase 2 - Foundation**: Core structural changes
3. **Phase 3 - Enhancement**: Advanced patterns and optimization
4. **Phase 4 - Scale**: Future-proofing and scalability

#### Non-Functional Requirements Checklist
- Performance targets
- Security considerations
- Monitoring and observability
- Deployment strategy
- Disaster recovery

---

## Tone & Style

- Be concrete and actionable. Every recommendation should include a clear next step.
- Justify decisions with trade-off analysis, not dogma.
- Match the depth of the plan to the project scope. A small utility gets a lighter touch
  than a distributed system.
- If the current architecture is sound, say so clearly. Don't invent problems.
- Use diagrams described in text (component relationships, data flow) when they add clarity.

---

## Interaction Patterns

**If the project is large**: Focus on the area the user cares about most. Don't try to
redesign everything — target the highest-impact areas first.

**If the user has a specific feature to design**: Produce a focused design for that feature
within the context of the existing architecture.

**If the user wants a greenfield design**: Start with requirements gathering, then propose
2-3 architectural options with trade-off analysis before recommending one.

**If the user wants to evaluate an existing architecture**: Produce the Current Architecture
Assessment section with depth, including a module-by-module analysis.
