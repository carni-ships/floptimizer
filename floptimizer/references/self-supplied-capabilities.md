# Self-Supplied Capabilities

Use this file when a promising optimization path is blocked not by bad evidence, but by a missing capability: no access to a repo, no backend for the target hardware, no port for the target architecture, no binding for the needed runtime, or no available implementation for the environment you actually have.

## Core Idea

Do not confuse "we do not have this implementation" with "this direction is impossible."

If the missing thing is the blocker, ask whether you can build the smallest local substitute that is sufficient to test or keep the optimization.

Good targets:

- a narrow adapter around an unavailable library
- a local port of one hot kernel to the current architecture
- a compatibility shim that preserves the existing interface
- a benchmark-only surrogate that proves the mechanism
- a clean-room reimplementation of one required behavior
- a data conversion or preprocessing step that unlocks a faster backend

Do not attempt to bypass access controls, scrape private code, or act as if unavailable proprietary code is fair game. If access is missing, treat the missing component as a contract to replace, not a boundary to break.

## When To Consider This

Consider a self-supplied capability when:

- the bottleneck is real and large enough to matter
- the missing capability is the main blocker, not just one excuse among many
- the contract or expected behavior can be inferred from public behavior, tests, fixtures, docs, interfaces, or measurable outputs
- there is a bounded slice you can build without committing to a full replacement up front
- there is an oracle or fallback path for validation

## Good Forms

Prefer the smallest form that teaches the answer you need:

- one hot parser or serializer, not a whole framework rewrite
- one architecture port of a hot loop, not a full multi-platform backend
- one accelerator kernel behind the current API, not a full runtime redesign
- one compatibility layer that lets the existing code talk to a new fast path
- one benchmark-only implementation to prove a suspected win before integration

## Required Questions

Before you treat this as active work, answer:

1. What exact capability is missing?
2. What contract must be preserved: API, bytes on the wire, numerical output, query semantics, scheduling behavior, or file format?
3. Where does that contract come from: public docs, tests, fixtures, observed behavior, or an accessible interface?
4. What is the smallest bounded substitute worth building first?
5. What oracle will prove the substitute is acceptable?
6. What result would justify expanding it beyond the spike?
7. What legal, licensing, support, or maintenance cost makes this a bad idea even if it performs well?

## Good Examples

- A private dependency contains the hot path, but the calling contract is visible through tests and interfaces. Rebuild the hot slice behind the current boundary instead of halting on access.
- A library has no ARM64 or Metal fast path. Port the dominating kernel first and compare it against the existing CPU path.
- The desired accelerator backend does not exist for this runtime. Add a narrow preprocessing stage plus a local kernel spike behind the current API to see whether the offload direction is even worth it.
- The current environment lacks a vendor primitive. Build a simpler local surrogate that preserves the data shape and proves whether the mechanism matters before chasing the exact vendor path.

## Guardrails

- Do not use this as an excuse for giant unsupervised rewrites.
- Do not recreate whole ecosystems when one hot slice would answer the question.
- Do not treat guessed behavior as good enough; keep a real oracle.
- Do not ignore maintenance cost if the substitute becomes production code.
- Do not break legal or contractual boundaries to obtain the missing implementation.

## What To Record

For a branch that depends on self-supplied capability work, record:

- missing_capability
- contract_source
- smallest_substitute
- oracle
- fallback
- expected_upside
- expansion_condition
- park_reason if the substitute is not worth continuing

This keeps the branch reusable instead of collapsing into "blocked by unavailable thing."
