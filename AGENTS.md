# AGENTS.md

Working notes for an agent in this repo, which holds `besm2_fmt`, an
Oberon-2 program (compiled with voc, Vishap Oberon) that reads YAML
files describing BESM 2nd Edition characters, templates and items, and
writes them as reStructuredText (grid tables, terse, raw ms/tbl) or as
an h-m-m outline.

It is a rewrite of the Oberon-2 port in `~/Repos/RPG/Tools/obesm2_fmt`
("the Buffer port"), with that port's `Besm2Str.Mod` removed and every
string a `Ropes.Rope`. The Buffer port is itself a port of the Ada
`besm2_fmt`, which is a port of `besm2-rst.scm` from
[besm-tools](https://github.com/tkurtbond/besm-tools).

See PLAN.md for what changed from the Buffer port, the module layout
and the build order. The design of the program itself, and every known
way the Ada version differs, are in the Buffer port's `PLAN.md` and
`ADA-DIFFERENCES.md`; they still hold and aren't copied here. This
file is operational notes, not a design doc.

## Reference material

| What | Where |
|---|---|
| The Buffer port being rewritten | `~/Repos/RPG/Tools/obesm2_fmt/` (`src/`, `PLAN.md`, `ADA-DIFFERENCES.md`, `VOC-GC-BUG.md`) |
| Its binary (the oracle for `make compare`) | `~/Repos/RPG/Tools/obesm2_fmt/obesm2_fmt` (build with `make` there) |
| Ropes | `~/Repos/Oberon/Ropes/` (`AGENTS.md`, `Ropes.Mod`, `RopeTest.Mod`); installed copy in `$OBERON_MODULES` |
| Ada program | `~/Repos/RPG/Tools/besm2_fmt/` |
| Ada binary (the oracle for `make golden`) | `~/Repos/RPG/Tools/besm2_fmt/besm2_fmt` |
| Original Scheme binary | `~/local/bin/besm2-rst` (on `PATH`) |
| ArgParser (command-line parsing) | `~/Repos/Oberon/ArgParser/`; installed copies in `$OBERON_MODULES` (default `/usr/local/sw/versions/oberon/include`) |
| olibfyaml (YAML) | `~/Repos/Oberon/olibfyaml/` (`AGENTS.md`, `src/FyThin.Mod`, `src/Fyaml.Mod`, `src/FyamlStreams.Mod`) |
| voc compiler | `/usr/local/sw/versions/voc/git/bin/voc`; not on the default `PATH` |
| voc source and runtime | `/usr/local/sw/src/lang/Oberon/vishap/compiler/` |

Read the Ropes, olibfyaml and ArgParser `AGENTS.md` files before
working around any of those libraries.

## Build / test

```sh
export PATH=/usr/local/sw/versions/voc/git/bin:$PATH
make            # obj/ (voc output) and ./obesm2_fmt2
make test       # unit tests, test/regs.sh, test/cli.sh, test/golden.sh check
make compare    # stdout, stderr and status against the Buffer port's binary
make golden     # regenerate test/golden/ from the reference programs
make valgrind   # the program under valgrind over every fixture and path
make benchmark  # timing against the Ada binary and the Buffer port
make perfdata   # measure this program alone: build/perfdata.tsv
make perfcompare  # perfdata here and in the Buffer port, then PERFORMANCE-ROPES-VS-BUFFERS.md
make rst        # build/*.gen.rst from test/data/*-2e.yaml
make pdf        # build/*.ms.pdf from those (pandoc, --template=tkb)
make install    # to $(PREFIX)/bin, default ~/local/bin (DESTDIR for staging)
make uninstall
make clean      # rm -rf obj besm2_fmt build
make testclean  # rm -rf build
make print-VAR  # show a makefile variable
```

- **Don't run `make install` with the default `PREFIX` unless asked**:
  it puts `obesm2_fmt2` in `~/local/bin`, beside the installed Ada
  `besm2_fmt`. Check the target with `make install DESTDIR=<scratch>`.
- **Everything is compiled with `-OC`**, as the first voc option,
  because olibfyaml requires it, and size models can't be mixed.
  Under `-OC`, `INTEGER` is 32 bits and `LONGINT` 64. `Ropes` is
  developed under the default model (32-bit `LONGINT`) but works under
  `-OC`: see PLAN.md, step 1.
- **Don't copy `Ropes.Mod`, `ArgParser.Mod`, `Err.Mod` or olibfyaml's
  modules into this repo.** The makefile finds the first three through
  `vpath` in `OBERON_MODULES` and olibfyaml's through `OLIBFYAML`
  (default `~/Repos/Oberon/olibfyaml`), and voc compiles them into
  `obj/`. A change `Ropes` needs is made in its own repo, tested and
  installed there (`make test`, `make install`), and needs the user's
  go-ahead.
- **voc's `Args` module exists only in the `-O2` library**, but
  `ArgParser` imports it; `rtl/Args.Mod` is the shim.
- voc writes `Mod.c`/`.h`/`.sym`/`.o` into the current directory, so
  every voc call runs inside `obj/`. Modules must be compiled in import
  order. Make targets are the `.o` files. **Adding a module means
  adding it to the makefile's module list in import order and adding
  an `obj/New.o: obj/Imported.o` line for each import.**
- `LDLIBS=$(pkg-config --libs libfyaml)` and `CFLAGS` (below) must be
  exported; the makefile does both.
- The main module is `Besm2Fmt`; the makefile copies `obj/Besm2Fmt` to
  `./obesm2_fmt2`, named for this repo so it can be installed beside the
  Ada `besm2_fmt` and the Buffer port's `obesm2_fmt`. Its messages still
  say `besm2_fmt`, as the Ada version's do. Link main modules with `-m`, not `-M`.
- A new library module goes in `PROGMODS` (in import order), a unit
  test in `TESTS`.
- **`tools/perfdata.sh` is shared**: the Buffer port has an identical
  copy, so both programs are measured the same way. Change both
  together (`cmp` them), and bump its `FORMAT_VERSION` when the data
  format changes; `tools/perfcompare.sh` refuses files whose versions
  differ. Compare performance by instruction counts first: they barely
  move between runs, where CPU times on this laptop move by 10% or
  more. `make perfcompare` takes several minutes; `PERF_COPIES`,
  `PERF_RUNS_SMALL` and `PERF_RUNS_BIG` make a quick trial run.

## Testing policy

- **Two oracles.** The golden files (`test/golden/`, from the Ada
  binary, or `besm2-rst` for `scheme` cases) fix standard output.
  `make compare` (`test/compare.sh`) checks standard output, standard
  error and exit status against the Buffer port's binary, over every
  fixture and every flag set in `test/golden.cases`; it is what checks
  the error messages byte for byte. Run both after any change. `make
  compare` needs the Buffer port built, so it isn't part of `make test`.
- **Regenerate golden files with `make golden`; never hand-edit one.**
  Add a line to `test/golden.cases` for new coverage and review the new
  files before committing them.
- A new behaviour worth testing gets a fixture in `test/data/` and a
  line in the golden flag matrix, not a one-off manual diff. Fixtures
  named `*-2e.yaml` are picked up by every `*-2e` case.
- `test/cli.sh` checks the command line: exit statuses and a line each
  case's output must contain.
- Unit tests (`test/Test*.Mod`) print `ok   - <label>` / `FAIL -
  <label>` and end with `All checks passed.` or `<N> check(s) failed.`,
  exiting 1 on failure. Never end a passing test with
  `Platform.Exit(0)`: it skips finalizers.
- **Prove a new check can fail**: plant the bug it targets and watch it
  fail.
- **Test ropes of more than one leaf.** `Ropes.Cat` merges leaves up to
  `ShortLeafLength` (16) characters, so a rope built from short pieces
  is often a single leaf and hides a bug in code that walks leaves.

## Working with ropes here

- **The empty rope is NIL.** There is no "present but empty" rope, so
  "absent" needs its own flag: `e.hasName`, `Besm2Config.hasHmmRoot`
  and so on (PLAN.md, section 2). Test emptiness with `r = NIL`.
  Never add a flagless optional string.
- **voc doesn't zero locals.** Start a rope built up in a local with
  `r := NIL`, and `Besm2Text.Clear` a `List` before using it.
- **Use `Ropes` directly for what it has** (`Cat`, `AppendChar`,
  `FromString`, `Length`, `EqualString`, `Make`, `Map`, `Substring`,
  `FindToken`, ...). `Besm2Text` holds only what it lacks: `Add`,
  `Int`/`AddInt`, `DisplayLength`, `Trim`, `FoldCI`/`LessCI`, `List`
  with `Join` and `SortCI`, `Chars`.
- **Not `Ropes.Trim`**: it also strips form feed. `Besm2Text.Trim`
  strips blank, tab, LF and CR, as the Ada version does.
- **Not `Ropes.CompareNoCase`** for sorting names: it folds ASCII only.
  `Besm2Text.FoldCI` is the Ada `To_Lower` byte fold the golden files
  depend on.
- **`Ropes.Length` counts bytes.** Column widths use
  `Besm2Text.DisplayLength`; header underlines use bytes, as the Ada
  version does.
- **Never walk a rope with a `Fetch` per character.** Use
  `Ropes.FindToken`/`IndexSet`/`CountSet`/`Map`/`IterateChunks`.
- **Callbacks (`Ropes.Mapper`, `Ropes.ChunkVisitor`) must be
  module-level procedures**; a nested procedure can't be a procedure
  value.
- **Output is `Besm2Out.Rope(r)`**, never `Ropes.Write` (it goes to
  `Out`, which `-o` can't redirect) and never through `Ropes.ToString`
  into a fixed array (it truncates silently).
- **`Besm2Text.Chars(r)` is for the few places that need an `ARRAY OF
  CHAR`**: `Err.String`, `Besm2Out.ToFile`, `FyamlStreams.OpenFile`.
  Assign it to a variable and pass `v^`: voc won't pass a dereferenced
  function result, `F()^`, as an open array (`err 59`).
- **`Ropes.FromString` stops at the first 0X**, so a YAML scalar with
  an embedded 0X is cut short, as in the Buffer port.

## voc / Oberon-2 facts this program depends on

Confirmed in the Buffer port, olibfyaml, ArgParser or Ropes; see their
notes for the details.

- **voc's GC can free a pointer held only in a callee-saved register**
  (the Buffer port's `VOC-GC-BUG.md`). The GNUmakefile's `CFLAGS`
  forbids those registers in every module compiled here, `Ropes`
  included, and `test/regs.sh` checks the objects. Rope code nests
  allocating calls everywhere (`Cat(Cat(a, b), c)`), so this matters
  more here than it did with buffers. Keep `CFLAGS` exported.
  valgrind can't see this bug; only output checks on inputs big enough
  for many collections can (`cli.sh`'s 1000-copy check).
- **No exceptions.** Loaders return `BOOLEAN` and pass an error back.
  `ASSERT`/`HALT` are for programmer errors only, never bad input.
- **No generics, closures or call chaining.** Use a variable per step.
- **olibfyaml indexes sequences from 0.**
- **`Out` can't be redirected, buffers until `Out.Ln`/`Out.Flush`, and
  `Platform.Exit` doesn't flush it.** All program output goes through
  `Besm2Out`; flush before exiting.
- **Argument evaluation order is unspecified** (voc compiles to C).
- **`*)` ends a comment anywhere, and `(*` inside a comment opens a
  nested one.**
- **UTF-8 in string literals passes through unchanged.** `CHAR` is a
  byte.
- **No string concatenation operator.** A `FOR` loop needs an integer
  control variable, not `CHAR`.
- **Every `CONST`, `TYPE` and `VAR` of a module comes before its first
  procedure**, and a procedure must be declared before it is used.
- **A read-only exported field (`e.stats-`) can't be passed as a `VAR`
  parameter** outside its module; pass it by value.
- **voc's `Files` caches files by inode**; use a new file name for each
  capture in tests.
- **A voc runtime trap exits with status 254**, distinct from a
  module's own `HALT(n)`. `Ropes` HALTs on a bad `Fetch` index.

## Conventions

- Keep each module traceable to the Buffer port's module of the same
  name, and keep its comments that explain *why* something matches
  `besm2-rst.scm` or the Ada version. A comment citing "the Buffer
  port's PLAN.md, step N" means `~/Repos/RPG/Tools/obesm2_fmt/PLAN.md`.
- Comments explain why, and only claim what has been verified. If a
  comment depends on how voc, Ropes, libfyaml or ArgParser behaves,
  test it with a throwaway program in the scratchpad first.
- A difference from the Ada version, new or newly found, is recorded in
  the Buffer port's `ADA-DIFFERENCES.md`: this repo sits beside the
  Buffer port and doesn't keep its own copy (PLAN.md, open questions).
  A difference from the Buffer port is a bug here unless PLAN.md
  records it as deliberate.
- Record decisions and findings in PLAN.md as they happen. Mark a
  finished step `[done]` and strike through an open question once it's
  decided.
