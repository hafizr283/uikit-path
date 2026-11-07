// Write a simulator CI job that preserves failures
// Create a GitHub Actions job that checks out the repository and builds the shared PocketTasks scheme on macOS. Explain what is still needed before it can act as a release gate.
// See lessons/day-20.md for requirements, hints, and acceptance checks.
// Independent exercise; do not add all course files to one Xcode target.

name: iOS build
on: [push, pull_request]
# Add a read-only macOS build job.
