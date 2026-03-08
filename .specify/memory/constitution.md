<!--
  Sync Impact Report
  ==================
  Version change: N/A (template) → 1.0.0
  Modified principles: N/A (initial population from template)
  Added sections:
    - 10 Core Principles (I–X) replacing 5 template slots
    - Engineering Standards (Section 2)
    - Development Workflow (Section 3)
    - Governance rules
  Removed sections: None
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ compatible (dynamic Constitution Check)
    - .specify/templates/spec-template.md ✅ compatible (edge cases, requirements, acceptance criteria align)
    - .specify/templates/tasks-template.md ✅ compatible (phased testing, incremental delivery align)
    - .specify/templates/checklist-template.md ✅ compatible (generic, no constitution refs)
    - .specify/templates/agent-file-template.md ✅ compatible (generic, no constitution refs)
    - .specify/templates/commands/ — directory does not exist, nothing to check
  Follow-up TODOs: None
-->

# KSEB App Constitution

## Core Principles

### I. Spec First

No code MUST be written before a clear specification exists.
Every feature MUST start with:

- Problem definition
- Functional requirements
- Non-functional requirements
- API/data contracts
- Edge cases
- Acceptance criteria

**Rationale**: Specifications prevent scope creep, reduce rework,
and ensure all stakeholders agree on intent before investment
in implementation.

### II. Single Source of Truth

All system behavior MUST be derived from the specification
documents. If implementation deviates from the spec, the spec
MUST be updated first — never the reverse.

**Rationale**: A canonical spec eliminates ambiguity and ensures
that code, tests, and documentation stay aligned with declared
intent.

### III. Small Iterative Specs

Large features MUST be broken into small, independently testable
specs. Each spec MUST be implementable within one development
iteration.

**Rationale**: Small increments reduce risk, enable faster
feedback loops, and make progress measurable.

### IV. Clear Data Contracts

All APIs, Firestore schemas, and data structures MUST be
explicitly defined before implementation. Strongly typed schemas
(e.g., Dart model classes, Firestore rules) MUST be used
wherever possible.

**Rationale**: Explicit contracts prevent integration failures,
enable parallel work across front-end and back-end, and make
breaking changes visible.

### V. Testability

Every feature MUST define:

- Unit test scenarios
- Integration test scenarios
- Failure conditions
- Expected outputs

Tests MUST exist for each acceptance criterion before the
feature is considered complete.

**Rationale**: Testable specs produce verifiable software;
untestable specs produce unverifiable claims.

### VI. Edge Case Awareness

Behavior MUST be explicitly defined for:

- Null or missing data
- Network failures
- Permission errors (role-based access violations)
- Invalid inputs
- Concurrency issues (e.g., simultaneous attendance marks)

**Rationale**: Undefined edge cases become production incidents.
Explicit handling ensures graceful degradation.

### VII. Minimal Complexity

The simplest architecture that satisfies the spec MUST be
preferred. Unnecessary abstractions, frameworks, or indirection
layers MUST be avoided.

**Rationale**: Complexity is a liability. Every abstraction MUST
justify its existence with a concrete problem it solves.

### VIII. Documented Architecture

For each system or major feature, the following MUST be produced:

- High-level architecture overview
- Component diagram
- Data flow description
- Dependency boundaries

**Rationale**: Architecture documentation enables onboarding,
review, and informed decision-making without reverse-engineering
code.

### IX. Reproducibility

All development outputs MUST be deterministic and reproducible.
Builds, tests, and deployments MUST produce consistent results
given the same inputs.

**Rationale**: Non-reproducible processes undermine confidence
in releases and make debugging intractable.

### X. Clear Deliverable Structure

All feature outputs MUST follow this structure:

```
Feature/
    spec.md
    architecture.md
    api_contracts.md
    edge_cases.md
    tests.md
    implementation_plan.md
```

**Rationale**: A uniform structure makes features discoverable,
reviewable, and auditable without per-feature orientation.

## Engineering Standards

**Prefer:**

- Strong typing (Dart strict mode, typed Firestore models)
- Explicit schemas (Firestore rules, model classes)
- Modular architecture (services, models, screens separation)
- Observability (structured logging, error reporting)
- Clear logging (meaningful messages with context)
- Error transparency (no silent failures; every error
  MUST surface to the appropriate handler)

**Avoid:**

- Hidden assumptions (all behavior MUST be spec-declared)
- Unspecified behavior (if not in the spec, it does not exist)
- Overengineering (YAGNI — justify every abstraction)
- Silent failures (catch-and-ignore is prohibited)

**Technology Stack:**

- **Language**: Dart / Flutter (latest stable)
- **Backend**: Firebase (Firestore, Authentication, Storage,
  Cloud Functions)
- **Platform targets**: Android (primary), iOS, Web
- **Testing**: `flutter test`, integration tests
- **CI/CD**: Firebase deploy for rules and functions

## Development Workflow

When asked to build a feature, the following order MUST be
followed:

1. Clarify missing requirements
2. Produce the specification (`spec.md`)
3. Define data models (`data-model.md`)
4. Define APIs/contracts (`api_contracts.md`)
5. Identify edge cases (`edge_cases.md`)
6. Produce test cases (`tests.md`)
7. Provide an implementation plan (`implementation_plan.md`)
8. Only then generate code

No step may be skipped. If a prior step is incomplete, work
MUST NOT proceed to the next step.

## Governance

This constitution supersedes all other development practices
for the KSEB App project. Amendments require:

1. A documented rationale for the change.
2. Review of impact on existing specs and implementations.
3. A migration plan if the change affects in-flight work.
4. Version bump following semantic versioning:
   - **MAJOR**: Backward-incompatible principle removal or
     redefinition.
   - **MINOR**: New principle/section added or materially
     expanded guidance.
   - **PATCH**: Clarifications, wording, or non-semantic
     refinements.

**Compliance:**

- All PRs and reviews MUST verify constitution compliance.
- Complexity MUST be justified against Principle VII.
- The spec deliverable structure (Principle X) MUST be
  validated before feature sign-off.

**Goal**: Ensure software is predictable, maintainable, and
spec-compliant before implementation begins.

**Version**: 1.0.0 | **Ratified**: 2026-03-08 | **Last Amended**: 2026-03-08
