# Feature: CRB status stage dates + Fast Update Flow refactor

Plan: ~/.claude/plans/1-quiero-optimizar-y-purring-gem.md
TDD: strict (source: project config). Runner: `sf apex run test -n ULabOrderTriggerTest` (needs org; remote use requires explicit user authorization).
Delivery strategy: ask-on-risk. Forecast: well under 400 authored lines except flow XML.
Note: no permission sets/profiles are tracked in this repo; FLS for new fields must be granted in the org.

## Tasks
- [x] T1 (inline, mechanical) Create 8 DateTime fields on uLab_Order__c
- [ ] T2 (delegated writer) Tests RED, then handler change (Order_Status pair, CRB_Assigned_Date__c)
- [ ] T3 (delegated writer) Refactor flow into sections A/B/C
- [ ] T4 Validate deploy + run tests in sandbox (needs user authorization for org)

## Evidence
