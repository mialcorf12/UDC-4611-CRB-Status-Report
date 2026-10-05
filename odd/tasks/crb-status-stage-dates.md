# Feature: CRB status stage dates + Fast Update Flow refactor

Plan: ~/.claude/plans/1-quiero-optimizar-y-purring-gem.md
TDD: strict (source: project config). Runner: `sf apex run test -n ULabOrderTriggerTest` (needs org; remote use requires explicit user authorization).
Delivery strategy: ask-on-risk. Forecast: well under 400 authored lines except flow XML.
Note: no permission sets/profiles are tracked in this repo; FLS for new fields must be granted in the org.

## Tasks
- [x] T1 (inline, mechanical) Create 8 DateTime fields on uLab_Order__c
- [x] T2 (delegated writer) Tests RED, then handler change (Order_Status pair, CRB_Assigned_Date__c)
- [x] T3 (delegated writer) Refactor flow into sections A/B/C
- [x] T4 Validate deploy + run tests in sandbox Onboarding (user-authorized)

## Evidence
- T1: commit b3536d6; native review (medium) granted, approved, acknowledged.
- T2: commit 2559ca5. T3: commit 5377e87. Written by delegated writer; static checks only (xmllint OK, unique names, targetReferences resolve).
- T4 (user-authorized sandbox Onboarding, check-only `sf project deploy validate`, RunSpecifiedTests ULabOrderTriggerTest): Succeeded, 24/24 passing (job 0Afhu000000D5ptCAC). First runs failed 2 new tests: (a) test seeded `Tech Review`, absent from the Onboarding picklist (org drift); (b) tests reused stale in-memory timestamps on update. Both were test-data issues, fixed in tests.
- RED/GREEN order was NOT observed (tests written before the handler, but never run before it).
- Order_Status_Entered_Current/Last trackHistory set to false (rewritten by the CLI after validate; org history-tracking cap). Helper timestamps do not need history.
- Latent pre-existing issue: on order INSERT with a uAssist status and no Date_Entered_In_Last_Status__c, the uAssist KPI row has a null required Previous_Status_Entry_Time__c; the DmlException is swallowed and the whole KPI batch (including Order_Status/CRB rows) is lost. Not changed here.
- NOT done: FLS for new fields, real deploy (validate only), quick deploy.
- Route: T1 inline; T2+T3 delegated writer (multi-file trigger).
