---
name: grilling
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Use the `AskUserQuestion` tool to put each decision to me. Rules:
- Ask one question at a time, waiting for my answer before continuing. Asking multiple questions at once is bewildering.
- List your **recommended answer first** and append `(Recommended)` to its label. Offer the other plausible options too.
- Keep option labels short; use each option's description to explain the tradeoff behind that choice.
- The tool always adds an "Other" free-text escape, so I can answer off-menu when none of your options fit.

If a *fact* can be found by exploring the codebase, look it up rather than asking me. The *decisions*, though, are mine — put each one to me and wait for my answer.

Do not enact the plan until I confirm we have reached a shared understanding.
