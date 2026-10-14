# AGENTS.md — Agentic Inbox mobile app

Scope: `mobile/`. The Worker in the repository root is the upstream `cloudflare/agentic-inbox` project. The app talks to any stock deployment of it and must not depend on changes to it.

The structure follows the Mutuals app (`../mutuals-app/app/AGENTS.md`). Where this file differs, the reason is stated.

**No code comments and no doc comments.**

---

## 1. Workspace

Dart pub workspace: one root `pubspec.yaml`, one lockfile, one `dart pub get`. Every package sets `resolution: workspace`. Flutter is pinned with fvm (`.fvmrc`).

```
mobile/
  app/lib/     app/ di/ models/ notifier/ repositories/ screens/ widgets/ utils/
  packages/    api/            Dio client, Access sign-in transfer, agent channel, chat protocol
               core/           non-UI shared: stores, mail text, search parser, URL parsing, debouncer
               design_system/  tokens, theme (light + dark), In-prefixed components
  mockups/     approved screen designs (input, not code)
```

Dependencies flow one way: `app → packages`. A package never imports `app/`. `design_system` never imports `api` or `core`.

## 2. The API client is hand-written

The Worker has no OpenAPI spec, so there is no generated client. `packages/api` is the only place that knows paths, the Access cookie and the wire format.

- Endpoint methods return JSON (`Json`, `List<Object?>`). Repositories own the JSON → domain mapping.
- Wire details that are not obvious are covered by tests in `packages/api/test`: the raw `@` in agent paths, the `CF_Authorization` cookie, a 302 to `/cdn-cgi/access/` as an expired session.
- The agent chat protocol (`cf_agent_*`) is internal to `@cloudflare/ai-chat`. `buildChatRequest` must send the full history, because the server replaces its stored history with what it receives.

## 3. Dependency injection — `get_it`, not Riverpod

- `di/service_locator.dart` holds `setUp()`, awaited in `main()` before `runApp`.
- Never construct infrastructure outside `di/`.
- Every vendor SDK sits behind an interface with one adapter file: `Browser` (url_launcher), `Files` (file_picker, share_plus, path_provider), `AgentChannel` (web_socket_channel).
- `ref` is for state only.

## 4. State — Riverpod codegen

- Async state is `AsyncValue`. Mutations go through `AsyncValue.guard` or rethrow to the screen. Never swallow an error.
- Notifiers hold state and orchestration. They do not build widgets or contain network code.
- Models are plain `@immutable` classes and sealed classes, the same as Mutuals in practice.
- Prefer a notifier to `setState`. `setState` is for a pressed state, an expanded row or a text field.
- A mutation that the user can reverse returns an `Outcome` with an `undo`.

## 5. Sign-in and session

- Sign-in uses the Access token transfer that `cloudflared access login` uses: `AccessTransfer` in `packages/api`, the system browser through `Browser`.
- `IdentityRepository` owns the whole sign-in flow. No screen calls `AccessTransfer` or the browser directly.
- Any Access rejection (401, 403, 302 to Access) expires the session through `IdentityRepository.expired`. The router then shows the expired state.

## 6. Local data

- `flutter_secure_storage` — the Access session, the last inbox URL and the chosen mailbox. Nothing else.
- No mail is cached on the device.

## 7. Tests

- `app/test/helpers/fakes.dart`: `registerFakes()` re-registers `get_it` with the real repositories over a `FakeServer` Dio adapter. Tests assert on real requests.
- Package tests live in `packages/*/test`.

## 8. Commands

```
fvm dart pub get                                   (mobile/)
cd app && fvm dart run build_runner build
fvm flutter analyze                                (each package; api: fvm dart analyze)
fvm dart format --set-exit-if-changed .            (mobile/)
fvm flutter test                                   (app, core, design_system; api: fvm dart test)
```

All pass, with real output reported, before a task is called complete.

App icons come from the vectors in `app/assets/brand/` (the "Spark envelope" mark). After you change a vector, regenerate every Android and iOS size with `app/tool/generate_icons.sh`; it needs `rsvg-convert` and `magick`. `InLogo` in `design_system` paints the same mark in Flutter, so keep its geometry in step with `icon.svg`.

## 9. Review gate

The Plannotator review gate in the global agent instructions applies here without change.
