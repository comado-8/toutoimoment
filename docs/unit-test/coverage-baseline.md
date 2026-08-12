# Unit-test coverage baseline

Status: pending the first stable green CI runs.

The Phase 1 workflow reports coverage without enforcing a threshold. After two or three consecutive stable PR runs, replace the pending values below with the measured values from `coverage-summary.md`.

| Metric | Baseline |
| --- | ---: |
| Logic scope coverage | Pending |
| Baseline source run | Pending |
| Recorded at | Pending |

Pre-CI local observation (not a baseline): 75.67% logic coverage, 6,379 of 8,430 executable lines, measured on 2026-08-12 with Xcode 26.6 and iOS 26.5. The baseline remains pending until CI is stable across two or three PRs.

Phase 2 must reject a decrease below the recorded logic baseline. Phase 3 requires at least 80% coverage for changed logic files. Overall 85% becomes mandatory only after the measured logic coverage reaches at least 85%; until then, continue enforcing non-regression against the baseline.

Coverage scope: Core, Models, ViewModels, Services, and Repositories. Exclusions: Views, Components, Theme, tests, and generated code.
