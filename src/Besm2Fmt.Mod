MODULE Besm2Fmt; (* besm2_fmt: BESM 2E YAML to reStructuredText *)

(* Oberon-2 port of the Ada besm2_fmt (besm2_fmt_main.adb), itself a
   port of besm2-rst.scm, with every string a Ropes.Rope.  See PLAN.md,
   and the Buffer port's PLAN.md, section 7. *)

IMPORT Besm2Cli, Besm2Config, Besm2Entities, Besm2Grid, Besm2Hmm, Besm2Out, Besm2RawMs, Besm2Terse, Besm2Text,
  Err, Fyaml, FyamlStreams, Out, Platform, Ropes, SYSTEM;

(* strerror, for an -o/--output file that can't be created. *)
PROCEDURE -AincludeString '#include <string.h>';
PROCEDURE -strerror(e: INTEGER): SYSTEM.ADDRESS "(ADDRESS)strerror((int)e)";

(* Writes r to standard error. *)
PROCEDURE ErrRope(r: Ropes.Rope);
  VAR s: Besm2Text.String;
BEGIN s := Besm2Text.Chars(r); Err.String(s^)
END ErrRope;

(* Writes the OS's text for error code e, from strerror, to standard
   error. *)
PROCEDURE ErrReason(e: Platform.ErrorCode);
  VAR p: SYSTEM.ADDRESS; c: CHAR;
BEGIN
  p := strerror(e);
  IF p # 0 THEN
    SYSTEM.GET(p, c);
    WHILE c # 0X DO Err.Char(c); INC(p); SYSTEM.GET(p, c) END
  END
END ErrReason;

(* Reports an error this program found in processing source, in the
   Ada version's words: "besm2_fmt: error processing SOURCE: MESSAGE".
   Output so far is flushed first, so it comes before the error when
   both go to the terminal. *)
PROCEDURE Report(source, msg: Ropes.Rope);
BEGIN
  Besm2Out.Flush;
  Err.String("besm2_fmt: error processing "); ErrRope(source); Err.String(": ");
  ErrRope(msg); Err.Ln
END Report;

(* Reports an error from olibfyaml.  Its message already names the file,
   gcc style ("FILE:LINE:COLUMN: error: TEXT", one line per error, each
   ending in a newline), so it gets only the program's name in front:
   a deliberate difference from the Ada wording (the Buffer port's
   PLAN.md, section 5). *)
PROCEDURE ReportYaml(err: Fyaml.Error);
BEGIN
  Besm2Out.Flush;
  Err.String("besm2_fmt: "); Err.String(err.msg^)
END ReportYaml;

(* The entities of one document.  count runs on across the documents of
   a file: 1 for the file's first entity, whichever document it is in.
   Each entity is loaded completely before any of it is written, so one
   that fails writes nothing; those before it are already written.
   FALSE after reporting an error, which ends the file, as in the Ada
   version. *)
PROCEDURE ProcessDocument(d: Fyaml.Document; source: Ropes.Rope; VAR count: INTEGER): BOOLEAN;
  VAR root, item: Fyaml.Node; it: Fyaml.ItemIter; e: Besm2Entities.Entity;
    yerr: Fyaml.Error; msg: Ropes.Rope;
BEGIN
  root := d.Root();
  IF (root = NIL) OR ~root.IsSequence() THEN
    msg := Ropes.Cat(Ropes.FromString("expected a top-level YAML sequence of entities in "), source);
    Report(source, msg);
    RETURN FALSE
  END;
  root.Items(it);
  WHILE it.Next(item) DO
    IF ~Besm2Entities.Load(item, e, yerr, msg) THEN
      IF yerr # NIL THEN ReportYaml(yerr) ELSE Report(source, msg) END;
      RETURN FALSE
    END;
    INC(count);
    CASE Besm2Config.format OF
      Besm2Config.Terse: Besm2Terse.ProcessEntity(e, count)
    | Besm2Config.Grid: Besm2Grid.ProcessEntity(e, count)
    | Besm2Config.Hmm: Besm2Hmm.ProcessEntity(e, count)
    | Besm2Config.RawMs: Besm2RawMs.ProcessEntity(e, count)
    ELSE HALT(20)   (* Besm2Cli sets no other format *)
    END
  END;
  RETURN TRUE
END ProcessDocument;

(* One file, or standard input if stdin.  As besm2-rst.scm's
   process-file: an error ends this file, not the run. *)
PROCEDURE ProcessOne(name: Ropes.Rope; stdin: BOOLEAN);
  VAR s: FyamlStreams.Stream; d: Fyaml.Document; err: Fyaml.Error;
    source: Ropes.Rope; path: Besm2Text.String; count: INTEGER; ok: BOOLEAN;
BEGIN
  IF stdin THEN source := Ropes.FromString(Fyaml.stdinName); s := FyamlStreams.OpenStdin(err)
  ELSE source := name; path := Besm2Text.Chars(name); s := FyamlStreams.OpenFile(path^, err)
  END;
  IF s = NIL THEN ReportYaml(err); RETURN END;
  count := 0; ok := TRUE;
  d := s.Next(err);
  WHILE ok & (d # NIL) DO
    ok := ProcessDocument(d, source, count);
    d.Close;
    IF ok THEN d := s.Next(err) END
  END;
  IF ok & (err # NIL) THEN ReportYaml(err) END;
  s.Close
END ProcessOne;

PROCEDURE ProcessAll;
  VAR i: INTEGER;
BEGIN
  IF Besm2Cli.files.n = 0 THEN
    ProcessOne(NIL, TRUE)
  ELSE
    FOR i := 0 TO Besm2Cli.files.n - 1 DO ProcessOne(Besm2Cli.files.items[i], FALSE) END
  END
END ProcessAll;

PROCEDURE Main;
  VAR e: Platform.ErrorCode; path: Besm2Text.String;
BEGIN
  Besm2Cli.Parse;   (* exits with status 2 on a command-line mistake *)
  IF Besm2Cli.helpShown THEN
    (* besm2-rst.scm's usage always exits 1, even for --help. *)
    Out.Flush; Platform.Exit(1)
  END;

  (* The -R/--hmm-root line: once per run, not per entity, and -- as in
     besm2-rst.scm's main, which writes it before redirecting output
     for -o -- always to standard output, even under -o/--output.
     Confirmed against the real besm2-rst binary by the Ada port, and
     kept. *)
  IF Besm2Config.hmmOutput & Besm2Config.hasHmmRoot THEN
    Besm2Out.Repeat(09X, Besm2Config.hmmDepth);
    Besm2Out.Rope(Besm2Config.hmmRoot); Besm2Out.Ln;
    Besm2Out.Flush
  END;

  IF Besm2Config.hasOutputFile THEN
    path := Besm2Text.Chars(Besm2Config.outputFile);
    e := Besm2Out.ToFile(path^);
    IF e # 0 THEN
      (* The Ada version dies here with an unhandled Name_Error, status
         1; this reports the same OS reason and status. *)
      Err.String("besm2_fmt: can't create "); Err.String(path^);
      Err.String(": "); ErrReason(e); Err.Ln;
      Platform.Exit(1)
    END
  END;

  ProcessAll;

  e := Besm2Out.Close();
  IF e # 0 THEN
    Err.String("besm2_fmt: error writing output: "); ErrReason(e); Err.Ln;
    Platform.Exit(1)
  END
END Main;

BEGIN
  Main
END Besm2Fmt.
