# Validation

## Course and web app

- 20 lessons, 100 teaching sections, 20 worked examples, 60 solved challenges, 100 explained multiple-choice questions.
- Node tests cover lesson structure, HTML escaping, progress import/export data normalization, quiz scoring, deep-link routing, and the non-executing UI illustration parser.
- Chrome browser checks passed for all 100 day/section routes, quiz scoring and explained answers, best-score retention, saved drafts and notes, progress resumption, search, UI lab property edits, and invalid-route recovery.
- Progress JSON import/export was exercised: existing completed days and the best quiz score were retained, imported notes appeared, and a backup downloaded before merging. Data also survived a page reload.
- Desktop (1440px) and mobile (390px) views were visually reviewed. Automated accessibility scans reported no violations on the reviewed overview, mobile lesson/navigation, practice, quiz, and UI lab pages after corrections. Some offscreen/gradient contrast checks require manual review; this is not a claim of exhaustive accessibility certification.
- Generated Markdown/source extracts must match the JSON content in CI.

## Native Swift

This repository was authored on Windows, where the iOS SDK and Xcode are unavailable. Native compilation and tests run in the repository's macOS GitHub Actions workflows.

**PocketTasks passed:** [Native UIKit run 42394706856](https://github.com/hafizr283/uikit-path/actions/runs/42394706856), native source at `baaca75f34e78f3107aea3301a9294ae0fd1701e`. The iOS Simulator app built for arm64 and x86_64; all six native unit tests passed. Later web/content edits do not alter that tested native source.

**Course examples passed:** [Swift validation run 42395819772](https://github.com/hafizr283/uikit-path/actions/runs/42395819772) at `f37473fde625e71658f7b247f26826db9398876d`. All **48 checks** passed: the 19 Swift worked examples typechecked against the iOS Simulator SDK, the Day 20 shell script passed syntax checking, 13 bounded cases passed both iOS typechecking and macOS runtime assertions, and the combined Day 16 XCTest example/solutions passed iOS typechecking and actual macOS test execution (eight tests).

The workflow documents its exact contextual setup and verification scope in [validation/README.md](validation/README.md). An initial run exposed a missing Swift XCTest overlay import path in the runner; it was fixed using SwiftPM's SDK layout. No assertions were stubbed or disabled.

The browser UI lab does not compile or execute Swift and cannot validate a solution. The native starter is a foundation for the course milestones, not an implementation of every advanced feature taught.

## Deployment

The course is published through GitHub Pages at `http://hafizr283.me/uikit-path/`, independently of the existing homepage. [Deployment 42395819785](https://github.com/hafizr283/uikit-path/actions/runs/42395819785) succeeded and the live page returned HTTP 200. All 100 section routes and the interactive behavior checks also passed against the live domain. The homepage link was verified live.

The existing user domain was configured before this course. HTTP serves correctly, but its HTTPS endpoint currently presents a certificate without the custom hostname. DNS also has `www.hafizr283.me CNAME hafizr283.me`; GitHub recommends `www.hafizr283.me CNAME hafizr283.github.io`. The registrar/DNS record needs correction before restarting stuck GitHub certificate provisioning. The binding was not removed from the live site, and TLS verification was not disabled. See [GitHub custom-domain configuration](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site) and [certificate troubleshooting](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https).
