# AI Tools Coding Space

A sandbox for experimenting with AI-assisted development. Projects here are built quickly to explore ideas, test stacks, and prototype features — not to ship production software.

---

## What this is

This repository is a collection of **proof-of-concept (POC) applications** created with AI coding tools. Each app is a starting point: enough structure to run, explore, and iterate on, but not necessarily complete or correct.

**Important:** These projects were generated with AI assistance and were **not hand-written by a human developer**. Treat everything here accordingly.

---

## Expectations

| | |
|---|---|
| **Purpose** | Rapid prototyping and experimentation |
| **Code quality** | Variable — may be incomplete, inconsistent, or outdated |
| **Reliability** | Not guaranteed; things may break or behave unexpectedly |
| **Tests & docs** | Often minimal or missing |
| **Security** | Do not use as-is in production without a full review |

If something does not work, that is expected. Fork it, fix it, or use it as inspiration.

---

## Projects

| App | Description | Stack |
|-----|-------------|-------|
| [**mac-vitals**](./mac-vitals/) | Desktop widget for live storage, battery, and RAM — event-driven, ~0% idle CPU | Swift 6, WidgetKit, IOKit, macOS 14+ |
| [**my-notes**](./my-notes/) | Native macOS notes app — local-first, plain text on disk, optional AES-256 encryption | Swift 6, SwiftUI, macOS 14+ |
| [**pirate**](./pirate/) | Social platform for small communities (feeds, posts, likes, comments) | Vue 3, Bun, Hono, MongoDB |

Each project has its own `README.md` with setup instructions.

---

## Getting started

1. Pick a project from the table above.
2. Open its folder and follow the local `README.md`.
3. Install dependencies and run the dev server as documented.

There is no shared tooling at the root — each app is self-contained.

---

## Disclaimer

All apps in this folder are **POC experiments built by AI**. They are provided as-is, with no warranty. Use them for learning and prototyping only. Do not deploy to production or handle real user data without proper hardening, review, and testing.
