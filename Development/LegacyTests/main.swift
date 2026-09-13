// Compile alongside the library sources to reuse the synchronous regression checks.
// This runner deliberately has no dependency on Swift Testing or the actor test UI.
try testBackportOutputFormatting()
debug("Legacy JSON formatting checks passed")
