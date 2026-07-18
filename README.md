# TextFriend

**The friendly editor for the config files nobody else cares about.**

TextFriend is a small, fast text editor for iPhone and iPad that opens the
"exotic" plain-text formats real projects are made of — `docker-compose.yml`,
`Cargo.toml`, `.env`, `php.ini`, `Info.plist` — with proper syntax
highlighting and built-in sanity checks. It works directly with the Files app
(open in place, no import, no projects, no lock-in) and is designed to be a
99¢ one-time purchase: no subscription, no accounts, no data collection.

## Why another editor?

Doing market research on the iPad editor category (Textastic, Runestone,
Koder, Buffer Editor, Kodex, …) showed two things:

1. **Nobody advertises TOML, INI, or .env highlighting.** The big editors
   stop at YAML/JSON. "Edit my `.env` or `config.toml` on iPad" is an
   unserved query.
2. **The category drifted to subscriptions.** Textastic is $19.99/year,
   Buffer Editor is subscription-only, Runestone Premium is $9.99. A focused,
   honest 99¢ tool is a real position.

TextFriend deliberately does **not** build SSH, FTP, Git, or terminals. Pair
it with Working Copy or the Files app — that's what open-in-place is for.

## Features

- **Syntax highlighting** for YAML, JSON/JSONC, TOML, INI, `.env`, Markdown,
  XML/plist/SVG, and shell scripts — powered by a small, fully unit-tested
  tokenizer engine (no heavyweight dependencies)
- **Problem detection**: JSON parse errors with line numbers, YAML
  tab-indentation errors and duplicate-key warnings, `.env` duplicate keys
- **Files-app native**: document browser, open-in-place, autosave — your
  files stay where they are
- **Smart filename detection**: `.env.local`, `Dockerfile`, `Makefile`,
  `.gitignore`, `.editorconfig` and friends are recognized without extensions
- **Find & replace**, live line/word/character counts, adjustable monospaced
  type, three color themes, and a keyboard accessory row with the symbols
  YAML actually needs (`-` `:` `#` `"` `|` `>` …)
- Built entirely with **SwiftUI** on iOS 26 (`TextEditor` with
  `AttributedString`), settings persisted with **SwiftData**

## Building

Requirements: Xcode with the iOS 26 SDK, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
make generate   # xcodegen generate → TextFriend.xcodeproj
make build      # build for the iOS simulator
make test       # run the unit test suite
make lint       # swift format lint
make format     # swift format --in-place
make icon       # regenerate the app icon (Python 3 + Pillow)
```

## Architecture

```
App/Sources/
  TextFriendApp.swift        DocumentGroup scene + SwiftData container
  Document/                  FileDocument (UTF-8 with Latin-1 fallback), UTTypes
  Editor/                    EditorView (iOS 26 TextEditor + AttributedString),
                             status bar, live stats
  Highlighting/              Token engine, per-language tokenizers, validation
  Theme/                     Color themes
  Settings/                  SwiftData model + settings sheet
Tests/TextFriendTests/       Swift Testing suites for every tokenizer,
                             validation, detection, themes, document I/O
```

The highlighting engine is a regex-rule pipeline with first-rule-wins range
claiming plus quote-aware comment splitting and per-line state for stateful
constructs (Markdown fences, XML comments). Every tokenizer guarantees a
lossless invariant: concatenating its tokens reproduces the input exactly.
Highlighting mutates *attributes only*, so the caret, selection, and undo
stack survive re-highlights.

## Roadmap

- Line numbers and an indentation guide (needs a custom text layout)
- YAML key-path breadcrumb (`services.web.ports`)
- JSON ↔ YAML conversion
- Quick-edit share extension

## License

MIT — see [LICENSE](LICENSE).
