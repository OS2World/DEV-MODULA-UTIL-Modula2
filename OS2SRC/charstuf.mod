IMPLEMENTATION MODULE CharStuff;
(*
    Title     : Various string and character goodies
    Author    : I.R. Matters  (Ian.Matters@anu.edu.au)
    System    : Juergen Neuhoff's Modula-2 compiler on OS/2
    Last Edit : 27 May 1995
*)


IMPORT ASCII, Strings;  (* this line updated 24 July 1995 J.Neuhoff *)


PROCEDURE AppendChar (ch: CHAR; VAR s: ARRAY OF CHAR);
(*
  Append a character to a string
*)
VAR temp : ARRAY [0..1] OF CHAR;
BEGIN
  temp [0] := ch;
  temp [1] := ASCII.nul;
  Strings.Concat (s, temp, s);
END AppendChar;


PROCEDURE Pad (VAR s: ARRAY OF CHAR; len: CARDINAL; style: PadStyles);
(*
   Pad a string with spaces until it is the nominated length
*)
BEGIN
  WHILE (Strings.Length (s) < len) DO

    IF ((style = PadLeft) OR (style = PadBoth)) THEN
      Strings.Concat (' ', s, s);
    END;  (* IF *)

    IF ((Strings.Length (s) < len) AND ((style = PadRight) OR (style = PadBoth))) THEN
      Strings.Concat (s, ' ', s);
    END;  (* IF *)

  END;  (* WHILE *)
END Pad;


PROCEDURE StrOfChars (n: CARDINAL; ch: CHAR; VAR s: ARRAY OF CHAR);
(*
    Create a string containing a number of characters
*)
VAR I: CARDINAL;
BEGIN
  s [0] := ASCII.nul;
  FOR I := 1 TO n DO
    AppendChar (ch, s);
  END;  (* FOR *)
END StrOfChars;


PROCEDURE Spaces (n: CARDINAL; VAR s: ARRAY OF CHAR);
(*
    Create a string containing a number of spaces
*)
BEGIN
  StrOfChars (n, ' ', s);
END Spaces;


PROCEDURE Dots (n: CARDINAL; VAR s: ARRAY OF CHAR);
(*
    Create a string containing a number of dot characters
*)
BEGIN
  StrOfChars (n, CHR (183), s);
END Dots;


PROCEDURE Trim (VAR s: ARRAY OF CHAR);
(*
  Remove leading and trailing spaces from a string
*)
BEGIN

  (* Remove the leading white space *)

  WHILE (s [0] = ' ') DO
    Strings.Delete (s, 1, 1);
  END;  (* WHILE *)

  (* Remove the trailing white space *)

  WHILE ((s [Strings.Length (s) - 1] = ' ') AND (Strings.Length (s) > 0)) DO
    Strings.Delete (s, Strings.Length (s) - 1, 1);
  END;  (* WHILE *)
END Trim;


PROCEDURE Upper (VAR s: ARRAY OF CHAR);
(*
  Convert a string to upper case
*)
VAR i: LONGCARD;
BEGIN
  IF (Strings.Length (s) > 0) THEN
    FOR i := 1 TO Strings.Length (s) DO
      s [i - 1] := CAP (s [i - 1]);
    END;  (* FOR *)
  END;  (* IF *)
END Upper;


END CharStuff.

