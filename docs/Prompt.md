Before doing anything else, read these files as completely as possible:

1. `docs/FINAL_TODO_PLAN.md`
2. `docs/PROJECT_PLAN.md`
3. `docs/QUICK_START.md`
4. `README.md`

Also inspect the datasets in:
`/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project/data`

Then execute this scope:

X = Phase 1

<<X>>

Interpret `<<X>>` as a whole phase from `docs/FINAL_TODO_PLAN.md`, not a single step. Complete that phase as fully as possible, including its steps, substeps, deliverables, and done-when conditions, as far as they are actually achievable from the current repository state.

Rules:

1. Scope
- Complete only the requested phase `<<X>>`.
- First identify all items inside that phase.
- Do not skip items unless there is a real blocker.
- Do not move to later phases unless a small supporting action is strictly necessary.
- Do not broaden the task beyond `<<X>>`.

2. Code location
- Write all executable implementation code in **R** inside:
  `/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project/notebooks/main.ipynb`
- **Do not create any other R file.**
- Keep the notebook clearly organized with markdown headers matching the phase and step names.
- Make the notebook easy to rerun from top to bottom.

3. Code style
- Do not write advanced code.
- Write human-understandable R code.
- Prefer simple, explicit, readable code.
- Use clear variable names.
- Add only short useful comments.
- Avoid unnecessary abstractions, metaprogramming, heavy indirection, and premature optimization.

4. Project consistency
- Respect frozen rules in `docs/FINAL_TODO_PLAN.md` and `notes/decision_log.md` if it exists.
- Reuse existing files where possible.
- Do not silently rebuild upstream outputs inside downstream work.
- For main-model work, preserve:
  - count-based modeling with `success` and `cohort`
  - `rel_with_new_flg == 1` as the main inclusion rule
  - `cohort >= 50` as the main threshold unless the task is explicitly a sensitivity analysis
  - the frozen year window
  - the frozen main predictor set
  - the frozen baseline region
- For DIC, do not use default JAGS DIC for M2/M3 as the primary comparison; use observed-data log-likelihood in post-processing.

5. Editing and completion
- Inspect the repository first and understand what already exists.
- Prefer modifying existing files over creating new ones.
- Create or update only the outputs, docs, metadata, and logs required by this phase.
- Update the relevant checklist items in `docs/FINAL_TODO_PLAN.md`.
- Update `notes/decision_log.md` if this phase freezes or changes any recorded decision.
- Mark `[x]` only for truly completed items, `[/]` for partial items, and leave unrelated items unchanged.

6. Validation
- Run only the smallest relevant checks for this phase.
- Verify changed code is syntactically valid and logically coherent.
- Confirm required generated files actually exist in the expected locations.

7. Blocking rule
- If something in the phase cannot be completed, do not fake it.
- Make the maximum safe progress on the rest.
- Clearly state what is blocked, why, and what prerequisite is missing.

At the end, report exactly in this format:

A. Phase interpretation
- steps/substeps from `<<X>>` treated as in-scope

B. What you changed
- short bullet list of concrete edits

C. Files changed
- exact file paths changed
- exact file paths created

D. Checks performed
- short bullet list

E. Checklist updates
- which items in `docs/FINAL_TODO_PLAN.md` were changed to `[x]`, `[/]`, or left `[ ]`

F. Result
- what is completed for this phase
- what remains unfinished inside this phase

G. Notes
- blockers, assumptions, decisions made
- whether `notes/decision_log.md` was updated

Now execute the requested phase:

<<X>>