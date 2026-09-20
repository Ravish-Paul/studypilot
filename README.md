# StudyPilot ✈️

**An AI adaptive study planner for students** — built for [RevenueCat Shipaton 2026](https://revenuecat-shipaton-2026.devpost.com/) (Next Gen Award).

> To-do apps track tasks. StudyPilot keeps your plan **alive** — it adapts when life happens.

## The problem

Students have notes, PDFs and syllabi — but plans never survive contact with reality. Miss one day, and the whole plan collapses into guilt. Existing planners don't reschedule; they just show you what you failed to do.

## What StudyPilot does

- **AI plan generation** — add subjects, topics, exam dates and your daily study capacity. The AI builds a realistic day-by-day plan, prioritising subjects with the nearest exams.
- **Adaptive replanning** — skipped or missed tasks? One tap re-adapts the entire remaining plan around your actual progress and deadlines.
- **Today view** — a clear answer to "what should I study right now?", with streaks, exam countdowns and per-subject progress.
- **Focus timer** — a pomodoro-style timer per task that logs focused minutes.
- **Smart offline fallback** — if the AI is unreachable, a deterministic local scheduler (urgency-sorted greedy) builds the plan instead. The app never dead-ends.

## Monetization (RevenueCat)

- **Free**: 1 subject, 3 AI plan generations, unlimited offline planning.
- **Pro** (monthly / lifetime): unlimited subjects, unlimited AI replanning.

The paywall, packages, entitlement checks, purchase flow and restore are fully wired through the **RevenueCat SDK** (`purchases_flutter`). Since this build is not attached to a paid store account, purchases run in test mode and unlock Pro locally — see the Paywall screen for details.

## Tech

| Layer | Choice |
|---|---|
| Framework | Flutter (Android) |
| State | Riverpod |
| Storage | Hive (offline-first) |
| AI | OpenRouter chat completions with strict-JSON output + repair retry |
| Fallback | Local greedy scheduler (deterministic, no network needed) |
| Payments | RevenueCat SDK |

### Architecture

```
UI (screens/widgets)
  ↓
Controllers (ChangeNotifier + Riverpod providers)
  ↓
Services
  ├── AiService          OpenRouter call, JSON parse + repair retry
  ├── LocalScheduler     deterministic fallback planner
  ├── PlanService        orchestrates AI/fallback + gap coverage + persistence
  ├── RevenueCatService  offerings, purchases, entitlements
  └── Repository         Hive persistence
```

### Notable engineering details

- **AI reliability**: the model is prompted for strict JSON; parse failures trigger a repair call; a second failure falls back to the local scheduler. Any topics the AI skipped are detected and re-inserted (`_coverGaps`).
- **Urgency heuristic**: `daysUntilExam × 10 + priority` drives both the fallback scheduler ordering and gap re-insertion.
- **No dead ends**: every plan generation path persists locally, so the app is fully usable offline after a plan exists.
- **Secrets**: API keys live in `.env` (gitignored); `.env.example` documents the keys.

## Run it

```bash
# 1. Copy env template and add your keys (optional — app works without them
#    using the offline planner)
cp .env.example .env

# 2. Install and run
flutter pub get
flutter run
```

Keys you can add:

- `OPENROUTER_API_KEY` — from [openrouter.ai](https://openrouter.ai) (enables AI planning)
- `REVENUECAT_GOOGLE_API_KEY` — from your RevenueCat dashboard (enables real purchases)

Run tests:

```bash
flutter test
```

## License

MIT — see [LICENSE](LICENSE).
