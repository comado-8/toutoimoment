# TouToiMoment unit tests

The MVP pull-request gate runs `TouToiMomentTests` only. UI tests remain in the shared scheme but are intentionally excluded from this gate.

## Local command

Open an iOS 26.5 iPhone 17 simulator, obtain its UDID with `xcrun simctl list devices available`, then run:

```sh
xcodebuild test \
  -project TouToiMoment.xcodeproj \
  -scheme TouToiMoment \
  -destination "id=<SIMULATOR_UDID>" \
  -only-testing:TouToiMomentTests \
  -parallel-testing-enabled NO \
  -maximum-parallel-testing-workers 1 \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/toutoi-unit-tests.xcresult
```

The shared scheme contains the app, `TouToiMomentTests`, and `TouToiMomentUITests`. Omitting `-only-testing:TouToiMomentTests` will also select UI tests, so keep it in the PR-gate command.

## CI rollout

Phase 1 requires only a successful unit-test run. Coverage is reported in `coverage-summary.md` and the complete `.xcresult` is retained as an artifact whether the job succeeds or fails.

After the workflow is merged into `main`, configure the GitHub ruleset or branch protection to require pull requests, require the `toutoi-unit-tests` status check, block merges while it is failing, and require branches to be current with `main`.

Before making the check required, verify one intentionally failing test PR and one green PR. Confirm the failing PR is red, the green PR is green, UI tests did not run, and both artifacts were uploaded.

After two or three stable PR runs, record the measured logic coverage in [coverage-baseline.md](coverage-baseline.md) and begin Phase 2.
