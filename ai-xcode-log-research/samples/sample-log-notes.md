# Sample Log Notes

This file records observations from experiments.

## Baseline

- Expected state: project generates with XcodeGen.
- Expected test result: `LogResearchDemoTests` passes.
- Expected app runtime logs: `AppLifecycle` and `DemoEvents` categories appear when the app launches and the button is tapped.

## Controlled Failure Ideas

- Change a test assertion to fail and see if AI identifies the test name.
- Introduce a compile error in `ContentView.swift` and see if AI quotes the compiler diagnostic.
- Run against a missing simulator destination and see if AI recognizes destination resolution failure.
- Emit runtime `Logger.error` messages and see if AI separates synthetic app errors from build errors.

