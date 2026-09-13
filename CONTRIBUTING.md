# Contributing to Compatibility (and best practices for Open Source packages)

Compatibility prioritizes portability, backwards compatibility, clear public documentation, and reviewable changes. Contributors and coding agents should follow these repository-specific rules.

## Optional prompt templates

The templates in this section apply only when explicitly requested or when the current task is creating or modernizing a package according to these templates. Otherwise, skip this section and follow the general and interactive coding rules below.

PROMPT prefix for Xcode or another context without memory for projects using Compatibility:
```
Follow the rules in github.com/kudit/Compatibility/CONTRIBUTING.md, preserve existing edits, then complete this request:
[REQUEST]
```

PROMPT for updating Module packages:
```
Review this Swift package for adoption of the Module APIs introduced in github.com/kudit/Compatibility v1.16.0 or later. Inspect the package’s existing architecture and preserve its public behavior and platform compatibility. Add or update its Compatibility dependency if necessary. Apply an appropriate Module conformance, including its version, direct Compatibility dependency, module dependencies, immediately available moduleInfo, ordered TestCase sections, and opt-in open-source repository metadata when applicable. Register the package from its highest-level module or document how an application should register it through Application.track(including:). Add complete inline DocC comments to the relevant public APIs so generated documentation can discover them. Do not create a .docc catalog, separate documentation articles, or another documentation folder. Put reusable tests in the module's TestCase collections so they run both in the in-app test UI and through the Swift Testing bridge; retain target-specific tests only where infrastructure requires them. Follow this package’s existing CONTRIBUTING.md, changelog, versioning, formatting, availability, and compatibility conventions.
```

PROMPT For new apps:
```
Use github.com/kudit/Compatibility as a dependency. Adopt the coding, documentation, testing, and changelog rules in that project's CONTRIBUTING.md. Generate a README.md following the Compatibility App Store Styleguide in that same file. Reconstruct the implementation history represented in this conversation into changelog entries using the guidelines.  Swift apps should prefer Compatibility APIs where relevant, including debug() instead of print(), Application.track(), Backports, and Compatibility JSON/string/date helpers.
```

PROMPT for updating projects:
```
Use github.com/kudit/Compatibility where appropriate. Adopt the coding, documentation, testing, and changelog rules in Compatibility/CONTRIBUTING.md. Preserve existing behavior and edits, inspect the project before changing architecture, and complete the requested implementation with real tests.
```


## Interactive Coding Preferences
When working interactively with a maintainer, generally (this shouldn't be meant to override thread instructions but are here as a default):
- If there is ever any conflict between instructions in a prompt, pause and clarify before continuing.
- Work in small, reviewable stages rather than delivering a large implementation all at once (unless specifically requested).
- Present one immediate decision or action at a time and pause for maintainer feedback unless instructed to do a batch.
- Explain design choices briefly and answer questions before continuing implementation.
- Preserve and review the maintainer's local edits before adding further changes.
- When working in a shared local filesystem, let the maintainer build, edit, commit, and push between stages when practical. Do not commit or push coding-agent changes when you have access to the local filesystem.  When working purely via github access, then adding commits is okay as long as you include the proper CHANGELOG updates and version bumps.  Commit summaries should be the new version number and the description should be complete and clear and concise.
- For API changes, command-line interfaces, compatibility behavior, file formats, migrations, handling, or other boundary decisions, explain the recommendation and ask for maintainer confirmation before implementation unless the maintainer has already specified the desired behavior.  This is not necessary for non-impactful or obvious decisions to avoid overloading with unnecessary questions, however, style choices or various equivalent implementation decisions should be left to the maintainer.
- Coding-agent changes remain local for maintainer review: do not commit or push unless the maintainer explicitly requests that exact action. A prompt may be recorded in a local-only changelog note, but prompt text must never be committed or pushed to the server.
- After each pushed maintainer change, review the latest commit before proposing or applying the next change.
- Keep pull requests in draft until the implementation is compiled, exercised by real tests, and fully reviewed.
- Avoid unrelated cleanup, broad reformatting, and speculative changes that make the diff harder to reason about unless specifically asked for.
- Do not delete, rewrite, condense, or "clean up" maintainer-authored comments unless the Comment preservation rules explicitly permit it. Treat comments and TODOs as source material that must survive refactoring unless their underlying information is genuinely obsolete.
- Don't offer verbose explanations in the chat interface.  Long explanations should not be necessary if code is well documented inline and should be included there to read inline with code changes during diff review.  The chat interface should be for clarifying questions and high level discussion, answering questions, and providing high-level feedback.  When working on code projects, extra text and explanation in the chat is not a good way to preserve information.  Put next steps into an appropriate section of a markdown file like the CHANGELOG, put potential future ideas there, and architecture plans and roadmaps rather than in the chat itself.


## Version and changelog rules
- Keep changelog entries in `## vX.X.X YYYY-MM-DD` format, with short line-separated notes under the current version without any bullets like `- ` prepending the lines.
- Keep entries in strict reverse chronological order: newest version first. If two entries share a date, the higher version must appear first.
- Before editing the active changelog entry, compare its version with the latest committed Git version. If those versions match, create a bumped patch-version entry to edit and update version surfaces.
- Before changing a version, inspect the latest committed Git version and the active working-tree changelog. Never rewrite or reuse a committed historical entry. If the active working-tree version is ahead of Git, create a new version only when the maintainer requests it or when the active version has already been committed.
- Do not bump or create a version entry for uncommitted work when the active changelog version already matches the latest committed Git version; leave the working tree on that committed version until the maintainer commits or explicitly requests a release/version update.
- If an uncommitted manual version entry already differs from Git, use it and synchronize every version surface rather than choosing another version.  Swift code should update Xcode `MARKETING_VERSION`, `Package.swift`, and the Module`.version` (if it's a module).  Check the package manifest, Xcode project, public source constant, test fixture or suite heading, README or documentation display, and other hard-coded version surfaces.
- Manual-change notes belong under the existing active version unless the version rules above require a new version entry.
- Treat a heading such as `## vX.Y.Z TODO` as an intentional version stub: synchronize all version surfaces and replace `TODO` with the current date.
- If continuing work under an active uncommitted version entry on a later date, update only that active entry’s date; never change dates on historical entries.
- Changelog entries should contain concise summaries of changes.  They should be complete enough to communicate the changes but concise enough to be easily understandable at a high level and not get into too much detail unless it's particularly relevant like a changed API boundary.
- If a project has no `CHANGELOG.md` file (or `README.md` with a `# Changelog` section), offer to create one using this repository's format pulling from any available comments/history/prompts to generate an appropriate changelog with best guess estimates.  Do not invent dates unless there is evidence to support it.  You could however simplify dates to just a year, or just a year and a month if that information is present or put UNAVAILABLE if you need a date placeholder.  You can invent versions only when creating an initial `CHANGELOG.md` proposal and unless other information is available, you can start at v0.0.1 for the initial creation entry, v0.0.2 for the second entry, and so on. Each entry should include a succinct summary of decisions, instructions, and changes. 
- Modules should have separate `README.md` and `CHANGELOG.md` files. Final apps may keep a Changelog section in their README.
- When existing maintainer-authored uncommitted changes are present, preserve them and add concise note(s) to the current working changelog describing the changes that are visibly present. Do not invent implementation details, rationale, authorship, dates, or version history, and never modify committed historical entries.
- When modernizing an existing changelog, preserve historical content exactly and add new entries separately. Do not treat modernization itself as permission to rewrite, merge, or reinterpret existing entries.
- If there are pieces that aren't implemented in this pass and require future action, a short concise continuation prompt should be added to a beginning #TODO section just before the changelog (if it's things that need to happen before we commit this version) or added to the ## Known Issues, ## Roadmap, or ## Proposals section if there are longer term proposals or ideas or outstanding issues that will be addressed in a future version.
### Changelog preservation:
When converting or modernizing a changelog, preserve every existing entry’s
date, version, comments, wording, capitalization, punctuation,
and ordering exactly. Do not summarize, rewrite, merge, delete, or reclassify
historical entries. Only change the surrounding format as required, and keep the original text byte-for-byte wherever possible. Add new entries separately.

## Post-prompt checklist

After every prompt-driven change, contributors and coding agents must:

1. Compare the active working-tree changelog version with the latest committed Git changelog/version before choosing a version.
2. If the active version matches Git, create the normal patch entry unless the user requested another version.
3. If an uncommitted active entry is already ahead of Git, keep that version and synchronize every version surface to it.
4. Check `Package.swift`, the public `Compatibility.version` value, every Xcode `MARKETING_VERSION`, README/version displays, manifests, and every other hard-coded version surface.
5. Refresh the active unpushed changelog date when work continues on a later date.
6. Keep the complete prompt local-only; do not add it to tracked files or push it.
7. Review both the normal diff and an ignore-whitespace diff, remove unrelated or whitespace-only changes, run `git diff --check`, and run the repository's real build and tests.
8. For multi-file edits, patch each repository or external file separately. After every patch, verify the tool result, inspect the exact diff, run syntax checks, and search for the removed symbol or dependency. Never report the overall change as complete when any hunk failed or remains unverified. Always list changed files and show all deltas using a diff editor (if in Codex).
9. Treat local source changes, local tests, uploaded files, activated server configuration, DNS resolution, certificate coverage, cache behavior, and live responses as separate verification layers. Report which layers were actually verified; local tests alone do not establish deployment or production success.

## File editing safety

Whole-file replacement is an acceptable and often appropriate way to edit a repository file when the editing tool requires it. File size alone is not a reason to avoid the correct edit.

- Before any whole-file replacement, fetch the complete current file from the exact branch or commit being edited. Never construct a replacement file from a search result, partial snippet, truncated response, stale copy, or remembered version.
- Apply changes to that complete current content and upload the complete resulting file. A replacement containing only the changed region is a destructive truncation, not a patch.
- If the complete file cannot safely fit in one tool response or working context, read it in explicit contiguous ranges and verify that those ranges cover the entire file before constructing the replacement. Splitting the read is encouraged; omitting unread ranges is never acceptable.
- For especially large or complex files, break the work into small logical edits, but refetch the latest complete file before each sequential whole-file replacement so earlier edits and maintainer changes are preserved.
- Immediately inspect the resulting Git diff after every whole-file replacement. Unexpected large deletions, missing comments, missing declarations, or unrelated formatting changes are evidence of a bad replacement and must be corrected before continuing.
- Compare deleted lines as carefully as added lines. Whole-file editing must preserve comments, TODOs, disabled reference code, whitespace conventions, and unrelated source exactly unless the requested change intentionally modifies them.
- When a tool supports true patches, patches may be preferred for small localized changes, but do not avoid a necessary whole-file replacement merely because the file is large. The safety requirement is complete-current-input plus verified-output, not a particular editing mechanism.
- Instead of deleting configuration, mappings, comments, code, commented/unused reference code, or reference data, preserve the original information by commenting out the old code out rather than deleting so that the changes can be easily tracked inline without needing to reference a file diff or history to see what was changed.  An additional comment at the end of the commented code line should be added describing the version that the code was commented out (disabled) and briefly why.
- Do not permanently delete configuration, mappings, comments, code, or reference data without explicit approval. For small code or configuration changes, prefer commenting out the old line with a dated explanation. For larger or non-commentable material, preserve it in an appropriate archive, inventory, or reference file by default.
- Never redact or remove keys or passwords in code or comments unless specifically instructed to.  You can warn about security concerns, but there are times when the author may choose to have sensitive information included in a private repository.  If there is a flag that can be added to indicate the author understands and accepts those risks, that should be available to prevent continual security warnings for acceptable uses. This rule applies only where the maintainer has intentionally accepted the repository’s access controls. Never copy credentials into public releases, shared bug reports, generated output, public pull requests, public comments, logs, or deployment artifacts.


A full changelog outline may include:

```markdown
# Changelog

## vX.X.X YYYY-MM-DD
Description

## Known Issues
- [ ] Near-term actionable work, bugs, and release blockers.

## Roadmap
Planned features grouped by future version.

## Proposals
- [ ] Longer-term ideas, experiments, and possible improvements.
```


## Code style

- Preserve public identifiers, established behavior, compatibility paths, and user-visible syntax unless a breaking change is explicitly requested.
- Keep changes tightly scoped and avoid unrelated reformatting or whitespace-only edits.
- Please make clear when code is not best practice or the obvious way of doing things particularly when you're making stylistic or judgement choices.
- Prefer plain Markdown and code blocks for text intended to be pasted into files, GitHub, Xcode, or terminals.
- Prefer matching existing code style and leverage existing helper functions when possible rather than writing your own.
- Please check that all deprecations (that can) have appropriate renamed clauses for easy fixits.


## Comment preservation rules

Comments are part of the source and should be treated as maintainer-authored documentation, requirements, historical context, and design rationale rather than as optional clutter.

- Add complete DocC comments to public APIs and to non-obvious internal APIs.
- Use concise comments for obvious behavior and more detail around compatibility, migration, concurrency, and platform-specific decisions.
- Add clear inline comments explaining all new or modified code and why the change was made.
- Preserve existing comments by default, including explanatory comments, TODOs, reference URLs, migration notes, historical rationale, disabled example code, and maintainer-authored reminders.  If a comment is missing, unclear, or inaccurate, please flag and confirm with the maintainer.
- Do not remove or shorten a comment merely because the surrounding code appears self-explanatory, because the comment seems verbose, or because the implementation has been refactored.
- Prefer updating an existing comment when behavior changes rather than deleting it.
- A comment may only be removed when it is demonstrably factually incorrect, describes code or behavior that no longer exists, or the maintainer explicitly requests its removal.
- When resolving a TODO or instruction comment, remove it only after the requested work is actually complete. If the comment also contains useful rationale, history, compatibility information, or references, preserve that information in an updated explanatory comment.
- When adding or changing compatibility branches, tests, workarounds, non-obvious API choices, or platform-specific behavior, prefer adding comments explaining why the code exists rather than relying on the implementation alone.
- During final diff review, specifically inspect every deleted comment line. Any intentional comment deletion must be justified in the completion summary. Accidental or unjustified comment deletions must be restored before the change is considered complete.
- Unless explicitly requested, comment cleanup is not an acceptable form of unrelated cleanup.


## Swift rules

- Include `github.com/kudit/Compatibility` as a dependency in Swift projects and reuse its APIs where appropriate.
- Use Compatibility's `debug()` function instead of `print()` for logging.
- Prefer availability checks and platform fallbacks over removing older behavior.
- When possible, do not hide functions with availability checks.  If possible, do the availability checking inside the function and create backports if a feature is version-gated so that new features can be added and either backported for earlier versions or gracefully ignored when appropriate while keeping the code as close to the preferred modern syntax whenever possible.
- Keep Swift Playgrounds, non-Foundation, WASM, and older-platform builds working where practical.
- Put reusable framework tests beside their implementation and collect them in each module's ordered `TestCase` sections so the same checks appear in the in-app runner and the Swift Testing bridge. Keep only infrastructure-specific tests in the Xcode/SwiftPM test target.

### Portability and conditional compilation

- Treat `hasFeature(Embedded)` as a compiler-mode capability check, not as a platform check. Ordinary Swift Package Index Apple, Linux, Android, and full-runtime WASM/WASI builds do not enable Embedded Swift merely because of their target platform.
- Use `arch(wasm32)` for limitations common to every WebAssembly host, and use `os(WASI)` only when behavior is specifically tied to the WASI operating-system interface. Swift 6.2 and newer recognize `os(WASM)`, but the condition is false for standard WASI SDK targets and therefore is not a general WebAssembly check. If a distinct WASM operating-system target genuinely needs a branch, protect the condition from older compilers by nesting `#if os(WASM)` inside `#if compiler(>=6.2)`; do not place both conditions in one expression because older compilers still parse it. Do not assume `os(WASI)` implies Embedded Swift, and do not assume `hasFeature(Embedded)` implies WebAssembly.
- Keep `@MainActor` and other actor-isolation annotations present in full-runtime WASM. Current Swift 6.3 Embedded WebAssembly SDK builds do not expose `MainActor` or `Task`, so Embedded support must gate the complete concurrency-dependent API surface rather than merely changing an operating-system condition.
- Gate the smallest unavailable capability instead of an entire platform or actor boundary. Prefer `canImport(...)`, `#available`, `hasFeature(Embedded)`, or a narrowly documented OS check around the exact API that is missing, such as reflection, dynamic casting, Foundation coding, Dispatch, threads, blocking sleep, or an unsupported task primitive.
- Do not combine `canImport(SwiftUI)` with a blanket `!os(WASI)` exclusion. If SwiftUI is unavailable, `canImport(SwiftUI)` already removes the code; if a compatible SwiftUI implementation becomes importable on WebAssembly, the capability check should allow that code to compile. Add narrower guards only for specific SwiftUI APIs that the imported implementation does not provide.
- Before adding or retaining a WASM or Embedded exclusion, inspect the current compiler error and the exact build command. Do not preserve an old Swift Package Index workaround solely because an earlier toolchain lacked the feature.
- Swift Package Index's standard WASM compatibility job uses the full-runtime WASI SDK and does not test Embedded mode. If Embedded compatibility matters for a change, run a separate target or fixture that explicitly enables Embedded Swift; a green SPI WASM result does not validate `hasFeature(Embedded)` branches or promise that this package's concurrency-dependent public API is available in Embedded mode.
- Because Embedded Swift remains experimental, verify each concurrency runtime operation separately. If a specific operation such as task detachment or suspension is unsupported, provide a focused fallback while retaining valid actor annotations and isolation requirements.
- Swift does not expose a general-purpose `hasFeature(Concurrency)` condition that proves a target has a scheduler, threads, Dispatch, or suspending timers. Use `canImport(Dispatch)` for Dispatch-backed implementations, availability checks for deployed Apple concurrency runtimes, `hasFeature(Embedded)` only for known Embedded restrictions, and narrowly documented platform checks for host facilities such as WebAssembly timers.
- Do not gate `Equatable`, `Encodable`, or `Decodable` merely because a build targets Linux, Android, WASM, or WASI. Those protocols are part of full Swift runtimes. Before changing a conformance gate, also check whether the concrete type is locally owned, is a typealias to a Foundation type, already conforms on that Foundation implementation, or requires Swift 6's `@retroactive` ownership annotation.


## Design goals

- Backwards compatibility where practical.
- Consistent APIs across platforms.
- Well-documented public interfaces.
- Minimal breaking changes.
- Swift Playgrounds compatibility whenever possible.


# App Store Styleguide
Included for reference and utility and as a best practices model.  Feel free to substitute your own style guide or suggest improvements.

## README.md Outline (Apps that are not modules may have simply a `README.md` file with a `# Changelog` section and not a separate `CHANGELOG.md` file):
```
# App Name

[Optionally include outstanding bugs and issues or prompts that need to be addressed BEFORE pushing changes and locking the version.]

# Changelog
Maintain a reverse-chronological changelog, newest version first using the rules above.
Each entry should follow the same format indicated above, except if this release is targeted for the App Store, the simple user-facing App Store changes to use as the public "what changed in this version" release notes for that version should be first, followed by **App Store Updates above** on its own line as a separator, followed by any internal developer focused changes.  If there is a new version that isn't submitted to the App Store in between, the App Store Updates section should be moved up to the top until those changes are pushed to the app store with that version.
Example:
v0.0.1 2026-07-06
User-facing note
**App Store Updates above**
Internal developer note

# App Store Copy

## Title
[App Store Title]

## Subtitle (30)
123456789012345678901234567890
[Subtitle.  Uses the monospacing numbers above to ensure that it fits in 30 characters]

## Promotional Text (170)
Write App Store promotional text. Keep the heading’s character limit visible. The text should be short, direct, and marketing-oriented.

## Description (4,000)
Write the full App Store description. Keep the heading’s character limit visible. Include:
* Clear opening value proposition
* Main use cases
* Key features
* Paid/free behavior if relevant
* Privacy or data-handling notes if relevant
* Support/contact information
* Terms or policy URL if needed

## Keywords (100)
1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
[List App Store keywords. Keep the heading’s character limit and the reference numberline visible. Use comma-separated keywords and preserve the 100-character target/limit awareness.  Commas should not be followed by a space to save characters.]

## Pricing Analysis
[Document pricing assumptions, monetization logic, historical pricing changes, subscription tiers, consumables, unlocks, ad behavior, and any notes about how paid/free usage works.]
[Include date-based pricing sections when pricing changes over time.]

# Legacy Information
[Include any legacy information we don't want to delete but may not be relevant anymore.]
[Only public libraries need public-safe cleanup. Private app READMEs may keep PAT references, App Review notes, DTS history, upload warnings, pricing experiments, and other working context when useful.]

## Known Issues
- [ ] Near-term actionable work, bugs, and release blockers.

## Roadmap
Planned features grouped by future version.

## Proposals
- [ ] Longer-term ideas, experiments, and possible improvements.
```
