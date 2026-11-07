# Validation

## Course and web app

- 20 lessons, 100 teaching sections, 20 worked examples, 60 solved challenges, 100 explained multiple-choice questions.
- Node tests cover lesson structure, HTML escaping, progress import/export data normalization, quiz scoring, deep-link routing, and the non-executing UI illustration parser.
- Browser review covers desktop/mobile layout, navigation, quiz feedback, persistence, editable drafts, UI preview, and accessibility. Final evidence is added after the checks complete.
- Generated Markdown/source extracts must match the JSON content in CI.

## Native Swift

This repository was authored on Windows, where the iOS SDK and Xcode are unavailable. Native compilation and tests run in the repository's macOS GitHub Actions workflows. See their results before treating the source as build-verified. The example workflow documents any contextual setup and its typechecking scope.

The browser UI lab does not compile or execute Swift and cannot validate a solution. The native starter is a foundation for the course milestones, not an implementation of every advanced feature taught.

## Deployment

The existing user domain `hafizr283.me` was configured on GitHub Pages before this course. At initial inspection it served HTTP successfully but its HTTPS endpoint presented a certificate without the custom hostname. HTTPS status is tracked separately from the course deployment; the course does not silently disable TLS verification.
