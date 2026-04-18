Before doing anything else, read these files as completely as possible:

1. docs/TODO_PLAN.md
2. docs/PROJECT_PLAN.md
3. docs/QUICK_START.md
4. README.md
5. src/main.R
6. notes/analysis_rules.md
7. notes/decision_log.md

Also inspect the datasets in:

/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project/data

Then execute this scope:

<<X>>

Interpret <<X>> as a whole phase from docs/TODO_PLAN.md, not a single step. Complete that phase as fully as possible, including its steps, substeps, deliverables, and done-when conditions, as far as they are actually achievable from the current repository state.

Important repository structure:

Project root:
/Users/armanfeili/Arman/Sapienza Courses/6-semester/SMDS-2 - SDS II/project/FSL_2_Final_Project

Current structure:
- Raw data: data/data_raw/
- Processed data: data/data_processed/
- Main R source file: src/main.R
- Logical R stages: inside src/main.R only
- JAGS model files: src/models/
- Outputs: src/outputs/
- Figures: src/outputs/figures/
- Tables: src/outputs/tables/
- Diagnostics: src/outputs/diagnostics/
- Model objects: src/outputs/model_objects/
- Simulations: src/outputs/simulations/
- Report exports: src/report/
- Tests: src/tests/

Rules:

1. Scope
- Complete only the requested phase <<X>>.
- First identify all items inside that phase from docs/TODO_PLAN.md.
- Do not skip items unless there is a real blocker.
- Do not move to later phases unless a small supporting action is strictly necessary.
- Do not broaden the task beyond <<X>>.

2. Code location
- Write all executable R implementation code inside:
  src/main.R
- Do not create separate .R files.
- Do not create temporary execution files such as src/main_phase_only.R, src/run_phase.R, or similar.
- The numbered script names in docs/TODO_PLAN.md are logical stages, not physical .R files.
- Keep src/main.R clearly organized with comments/headers matching the requested phase and step names.
- Make src/main.R easy to rerun from top to bottom, or at least make the requested phase section easy to rerun safely.
- When a requested phase explicitly requires JAGS model files, .jags files may be created under src/models/. This exception applies only to JAGS model definitions, not R scripts.

3. Path consistency
- Use the current repository structure, not the old root-level structure from earlier drafts.
- Raw data must be read from data/data_raw/.
- Processed data must be written to data/data_processed/.
- Tables must be written to src/outputs/tables/.
- Figures must be written to src/outputs/figures/.
- Diagnostics must be written to src/outputs/diagnostics/.
- Model objects must be written to src/outputs/model_objects/.
- Simulations must be written to src/outputs/simulations/.
- Report files must be written to src/report/.
- JAGS model files must be read from or written to src/models/.
- Avoid absolute paths inside reusable code except for detecting the local project root.
- Do not create old-style duplicate folders such as notebooks/, data_raw/, data_processed/, outputs/, report/, scripts/, or models/ at the project root.
- Do not create nested duplicate folders such as src/src/.

4. Code style
- Do not write advanced code.
- Write human-understandable R code.
- Prefer simple, explicit, readable code.
- Use clear variable names.
- Add only short useful comments.
- Avoid unnecessary abstractions, metaprogramming, heavy indirection, and premature optimization.

5. Project consistency
- Respect frozen rules in docs/TODO_PLAN.md, notes/analysis_rules.md, and notes/decision_log.md if they exist.
- Reuse existing files where possible.
- Do not silently rebuild upstream outputs inside downstream work.
- If the requested phase needs upstream data or outputs, read the official saved output from the expected location.
- For main-model work, preserve:
  - count-based modeling with success and cohort
  - rel_with_new_flg == 1 as the main inclusion rule
  - cohort >= 50 as the main threshold unless the task is explicitly a sensitivity analysis
  - the frozen year window, once frozen
  - the frozen main predictor set, once frozen
  - the frozen baseline region, once frozen
- For DIC, do not use default JAGS DIC for M2/M3 as the primary comparison; use observed-data log-likelihood in post-processing.

6. Editing and completion
- Inspect the repository first and understand what already exists.
- Prefer modifying existing files over creating new ones.
- Create or update only the outputs, docs, metadata, and logs required by this phase.
- Update the relevant checklist items in docs/TODO_PLAN.md.
- Update notes/decision_log.md if this phase freezes or changes any recorded decision.
- Mark [x] only for truly completed items, [/] for partial items, and leave unrelated items unchanged.
- Do not mark a phase complete if any required deliverable is missing.

7. Validation
- Run only the smallest relevant checks for this phase.
- Verify src/main.R is syntactically valid:
  Rscript -e "parse('src/main.R')"
- Confirm required generated files actually exist in the expected locations.
- Confirm no extra .R files were created.
- Confirm no duplicate nested folders such as src/src/ were created.
- If the phase creates or updates a dataset, verify basic integrity checks required by docs/TODO_PLAN.md.

8. Blocking rule
- If something in the phase cannot be completed, do not fake it.
- Make the maximum safe progress on the rest.
- Clearly state what is blocked, why, and what prerequisite is missing.

At the end, report exactly in this format:

A. Phase interpretation
- steps/substeps from <<X>> treated as in-scope

B. What you changed
- short bullet list of concrete edits

C. Files changed
- exact file paths changed
- exact file paths created
- exact file paths deleted, if any

D. Checks performed
- short bullet list

E. Checklist updates
- which items in docs/TODO_PLAN.md were changed to [x], [/], or left [ ]

F. Result
- what is completed for this phase
- what remains unfinished inside this phase

G. Notes
- blockers, assumptions, decisions made
- whether notes/decision_log.md was updated

Now execute the requested phase:

<<X>>