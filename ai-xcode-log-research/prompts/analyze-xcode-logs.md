# Prompt: Analyze Xcode Logs

You are analyzing logs from an Xcode project.

Use only the attached logs and summaries as evidence. Do not invent files, symbols, tests, or build settings that are not present in the logs.

Return:

1. Overall status: success, failure, or inconclusive.
2. Failing phase: build, test, launch, runtime, simulator, signing, package resolution, or unknown.
3. Top findings ordered by likelihood, each with quoted log evidence.
4. The smallest next action to confirm or fix the issue.
5. Missing context that would improve the diagnosis.

Prefer concise, actionable output. Separate primary errors from follow-on noise.

