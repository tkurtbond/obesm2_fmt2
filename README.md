# obesm2_fmt2 - A port of obesm2_fmt to use Ropes instead of Buffers

`besm2_fmt` reads YAML files describing *Big Eyes, Small Mouth* 2nd
Edition characters, templates and items, and writes them as
reStructuredText (grid tables, terse paragraphs, or groff `tbl` tables
in a raw ms block) or as an [h-m-m](https://github.com/nadrad/h-m-m)
outline.

This is a rewrite of the Oberon-2 `besm2_fmt` in
`~/Repos/RPG/Tools/obesm2_fmt` (compiled with
[voc](https://github.com/vishaps/voc), Vishap Oberon), with its own
string module, `Besm2Str`, replaced by `Ropes.Mod` from
`~/Repos/Oberon/Ropes`: every string is a rope. That program is a port
of the Ada `besm2_fmt`, itself a port of `besm2-rst.scm` from
[besm-tools](https://github.com/tkurtbond/besm-tools).

The output is byte-for-byte the same as the Ada binary's (the golden
tests check this) and, standard error and exit statuses included, as
the Oberon-2 original's (`make compare` checks this).

## Usage

```
besm2_fmt [options] [files...]
```

With no files, standard input is read. Output goes to standard output,
or to the file given by `-o`.

| Format | Option |
|---|---|
| reST grid tables (the default) | |
| terse reST paragraphs | `-t`, `--terse` |
| groff `tbl` in a `.. raw:: ms` block | `-m`, `--raw-ms-tables` |
| h-m-m outline | `-H`, `--hmm` |

If more than one format option is given, the last one wins.
`besm2_fmt -h` lists every option. The original's README describes the
input format, the options and the exit statuses; they are unchanged.

## Building

You need:

- voc, by default at `/usr/local/sw/versions/voc/git/bin/voc`
  (override with `VOC=`).
- libfyaml, found through `pkg-config`.
- `ArgParser.Mod` and `Err.Mod` from ArgParser, and `Ropes.Mod` from
  Ropes, installed into `VOC_OBERON_MODULES` (default
  `/usr/local/sw/versions/oberon/voc/include`) by `make install` in each
  of those repos.
- A checkout of olibfyaml at `OLIBFYAML` (default
  `~/Repos/Oberon/olibfyaml`).

```sh
make                # ./obesm2_fmt2
make test           # unit tests, command-line checks, golden-output tests
make compare        # stdout, stderr and status against the original's binary
make valgrind       # the program under valgrind, over every fixture
make benchmark      # time against the Ada binary and the original
make perfcompare    # measure this and the original the same way; PERFORMANCE-ROPES-VS-BUFFERS.md
make install        # to $(PREFIX)/bin, default ~/local/bin
make uninstall
make rst            # build/*.gen.rst from the test fixtures
make hmm            # build/*.gen.hmm, h-m-m outlines from the same fixtures
make pdf            # build/*.ms.pdf from those, via pandoc and the tkb ms template
make clean          # everything built; make testclean removes only build/
```

The program is built as `obesm2_fmt2`, so it can be installed beside
the Ada `besm2_fmt` and the Buffer port's `obesm2_fmt`; its messages
and usage still call it `besm2_fmt`, as the Ada version's do.
`make install` puts it in `$HOME/local/bin` by default. Set `PREFIX`
(and `DESTDIR` for staging) to install elsewhere.

## Documents

- [AGENTS.md](AGENTS.md): working notes on the build, the tests, ropes
  and voc.
- [PLAN.md](PLAN.md): what changed from the original, the build order
  and the findings of each step.
- [PERFORMANCE-COMPARISON.md](PERFORMANCE-COMPARISON.md): timings
  against the Ada version and the original, from `make benchmark`.
- [PERFORMANCE-ROPES-VS-BUFFERS.md](PERFORMANCE-ROPES-VS-BUFFERS.md):
  this program against the original, measured the same way in both
  repos (instruction counts and CPU time), from `make perfcompare`.
