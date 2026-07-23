# Contributing to Compatibility (and best practices for Open Source packages)

Compatibility prioritizes portability, backwards compatibility, clear public documentation, and reviewable changes. Contributors and coding agents should follow these repository-specific rules.

PROMPT prefix for Xcode or another context without memory for projects using Compatibility:
Follow the included Compatibility `CONTRIBUTING.md` (or github.com/kudit/Compatibility/CONTRIBUTING.md), preserve existing edits, then complete this request:
[REQUEST]

PROMPT for updating Module packages:
Review this Swift package for adoption of the Module APIs introduced in github.com/kudit/Compatibility v1.16.0 or later. Inspect the package’s existing architecture and preserve its public behavior and platform compatibility. Add or update its Compatibility dependency if necessary. Apply an appropriate Module conformance, including its version, direct Compatibility dependency, module dependencies, immediately available moduleInfo, ordered TestCase sections, and opt-in open-source repository metadata when applicable. Register the package from its highest-level module or document how an application should register it through Application.track(including:). Add complete inline DocC comments to the relevant public APIs so generated documentation can discover them. Do not create a .docc catalog, separate documentation articles, or another documentation folder. Preserve existing comments unless they are missing, unclear, or inaccurate. Put reusable tests in the module's TestCase collections so they run both in the in-app test UI and through the Swift Testing bridge; retain target-specific tests only where infrastructure requires them. Follow this package’s existing CONTRIBUTING.md, changelog, versioning, formatting, availability, and compatibility conventions. Avoid unrelated reformatting and whitespace-only changes. Before changing version numbers, compare the current changelog version with the latest committed Git version. If the active working-tree changelog is already ahead of Git, do not choose another version; synchronize that active version across every package manifest, Xcode project, public source constant, test fixture or suite heading, README or documentation display, and other hard-coded version surface. Please check that all deprecations (that can) have appropriate renamed clauses for easy fixits.


## Version and changelog rules

- Keep changelog entries in `## vX.X.X YYYY-MM-DD` format, with short line-separated notes under the current version.
- Before editing the active changelog entry, compare its version with the latest committed Git version.
- If those versions match, create a patch-version entry by default and update `Package.swift`, `Compatibility.version`, and the Xcode `MARKETING_VERSION` settings. Use a minor or major bump only when the user requests it or has already created that version entry.
- If an uncommitted manual version entry already differs from Git, use it and synchronize every version surface rather than choosing another version.
- Treat a heading such as `## vX.Y.Z TODO` as an intentional version stub: synchronize all version surfaces and replace `TODO` with the current date.
- If work is being applied to the active unpushed version and its date is not current, update that heading to the current date.
- Append every prompt-driven request to the current entry as `PROMPT: [PROMPT TEXT]`, after the concise change summary and a blank line.
- If a project has no changelog, offer to create one using this repository's `CHANGELOG.md` format.
- Modules should have separate `README.md` and `CHANGELOG.md` files. Final apps may keep a Changelog section in their README.
- When you notice existing/manual uncommitted edits, please automatically generate and add changelog comments for the manual changes.

## Post-prompt checklist

After every prompt-driven change, contributors and coding agents must:

1. Compare the active working-tree changelog version with the latest committed Git changelog/version before choosing a version.
2. If the active version matches Git, create the normal patch entry unless the user requested another version.
3. If an uncommitted active entry is already ahead of Git, keep that version and synchronize every version surface to it.
4. Check `Package.swift`, the public `Compatibility.version` value, every Xcode `MARKETING_VERSION`, README/version displays, manifests, and every other hard-coded version surface.
5. Refresh the active unpushed changelog date when work continues on a later date.
6. Append the complete prompt as `PROMPT: [PROMPT TEXT]`.
7. Review both the normal diff and an ignore-whitespace diff, remove unrelated or whitespace-only changes, run `git diff --check`, and run the repository's real build and tests.

A full changelog outline may include:

```markdown
# Changelog

## vX.X.X YYYY-MM-DD
Description

PROMPT: Prompt text

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
- Add clear inline comments explaining new or modified code and why compatibility-specific behavior is necessary.
- Add complete DocC comments to public APIs and to non-obvious internal APIs.
- Preserve existing comments unless they are obsolete.
- Use concise comments for obvious behavior and more detail around compatibility, migration, concurrency, and platform-specific decisions.
- Prefer plain Markdown and code blocks for text intended to be pasted into files, GitHub, Xcode, or terminals.

## Swift rules

- Include `github.com/kudit/Compatibility` as a dependency in Swift projects and reuse its APIs where appropriate.
- Use Compatibility's `debug()` function instead of `print()` for logging.
- Prefer availability checks and platform fallbacks over removing older behavior.
- Keep Swift Playgrounds, non-Foundation, WASM, and older-platform builds working where practical.
- Put reusable framework tests beside their implementation and collect them in each module's ordered `TestCase` sections so the same checks appear in the in-app runner and the Swift Testing bridge. Keep only infrastructure-specific tests in the Xcode/SwiftPM test target.

### Portability and conditional compilation

- Treat `hasFeature(Embedded)` as a compiler-mode capability check, not as a platform check. Ordinary Swift Package Index Apple, Linux, Android, and full-runtime WASM/WASI builds do not enable Embedded Swift merely because of their target platform.
- Do not assume `os(WASM)` or `os(WASI)` implies Embedded Swift, and do not assume `hasFeature(Embedded)` implies WASM. Embedded Swift can target microcontrollers, bare-metal ARM or RISC-V, WASM, and other environments when the build explicitly enables Embedded mode.
- Keep `@MainActor` and other actor-isolation annotations present in full-runtime WASM and in current Embedded Swift. Embedded concurrency is partial and experimental, but its supported single-threaded mode includes basic actors and tasks; removing isolation creates unsafe shared-state APIs and Swift 6 diagnostics.
- Gate the smallest unavailable capability instead of an entire platform or actor boundary. Prefer `canImport(...)`, `#available`, `hasFeature(Embedded)`, or a narrowly documented OS check around the exact API that is missing, such as reflection, dynamic casting, Foundation coding, Dispatch, threads, blocking sleep, or an unsupported task primitive.
- Do not combine `canImport(SwiftUI)` with a blanket `!(os(WASM) || os(WASI))` exclusion. If SwiftUI is unavailable, `canImport(SwiftUI)` already removes the code; if a compatible SwiftUI implementation becomes importable on WebAssembly, the capability check should allow that code to compile. Add narrower guards only for specific SwiftUI APIs that the imported implementation does not provide.
- Before adding or retaining a WASM or Embedded exclusion, inspect the current compiler error and the exact build command. Do not preserve an old Swift Package Index workaround solely because an earlier toolchain lacked the feature.
- Swift Package Index's standard WASM compatibility job uses the full-runtime WASI SDK and does not test Embedded mode. If Embedded compatibility matters for a change, run a separate target or fixture that explicitly enables Embedded Swift; a green SPI WASM result does not validate `hasFeature(Embedded)` branches.
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

PROMPT For new apps:
```
Use github.com/kudit/Compatibility as a dependency. Adopt the coding, documentation, testing, and changelog rules in that project's CONTRIBUTING.md. Generate a README.md following the Compatibility App Store Styleguide in that same file. Reconstruct the implementation history represented in this conversation into changelog entries, creating one version per prompt: v0.0.1 for the first prompt, v0.0.2 for the second prompt, and so on. Each entry should include the prompt text plus a succinct summary of decisions, instructions, and changes. Swift apps should prefer Compatibility APIs where relevant, including debug() instead of print(), Application.track(), and Compatibility JSON/string/date helpers.
```


README.md Outline:
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

PROMPT: Included here but changes should be described in such a way that this line can be safely removed before committing.

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
```
