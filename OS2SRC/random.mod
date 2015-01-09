IMPLEMENTATION MODULE Random;
(*
    Title     : An implementation of pseudo random numbers
    Author    : I.R. Matters (Ian.Matters@anu.edu.au)
    System    : Juergen Neuhoff's Modula-2 compiler on OS/2
    Reference : Alan R. Miller,
                "Pascal Programs for Scientists and Engineers",
                Sybex, 1981, pp 29
    Version   : 1.00
    Last Edit : 30 July 1995
*)


FROM MathLib0 IMPORT exp, ln;
FROM OS2DEF   IMPORT APIRET;

(*$XL+ language extensions: allow extended import syntax *)

IMPORT FROM DOS;


PROCEDURE Randomize;
(*
  Initialize the random number generator seed with a
  pseudo-random value (obtained from the system clock).
*)
VAR t  : DATETIME;
    rc : APIRET;
BEGIN
  rc := DosGetDateTime (t);
  Seed := ((FLOAT (t.seconds) * 100.0) + FLOAT (t.hundredths)) / 750.0;
END Randomize;


PROCEDURE RandomReal(): REAL;
(*
   Return a random number in the range 0.0 <= RandomReal < 1.0 
*)
CONST Pi = 3.14159265358979;
VAR x : REAL;
BEGIN
  x := Seed + Pi;
  x := exp (5.0 * ln (x));
  Seed := x - FLOAT (LONGTRUNC (x));
  RETURN (Seed);
END RandomReal;


PROCEDURE RandomGaussReal(): REAL;
(*
   Return a random number with a Gaussian distribution
   in the range 0.0 <= RandomGaussReal < 1.0 
*)
VAR r : REAL;

  PROCEDURE RandomGauss(): REAL;
  CONST IdealMean      = 0.5;  (* for a range 0.0 .. 1.0 *)
        IdealDeviation = 0.2887;
  VAR i   : CARDINAL;
      sum : REAL;
  BEGIN
    sum := 0.0;
    FOR i := 1 TO 12 DO
      sum := sum + RandomReal();
    END;  (* FOR *)
    RETURN ((sum - 6.0) * IdealDeviation + IdealMean);
  END RandomGauss;

BEGIN

  (* Make absolutely sure that the value lies within the desired range *)

  REPEAT
    r := RandomGauss();
  UNTIL ((r >= 0.0) AND (r < 1.0));

  RETURN (r);
END RandomGaussReal;


PROCEDURE RandomCard (Range: CARDINAL): CARDINAL;
(*
   Return a random number in the range 0 <= RandomCard < Range 
*)
VAR i : LONGCARD;
BEGIN
  i := LONGTRUNC (RandomReal() * FLOAT (Range));
  RETURN (SHORT (i));
END RandomCard;


PROCEDURE RandomGaussCard (Range: CARDINAL): CARDINAL;
(*
   Return a random number with a Gaussian distribution
   in the range 0 <= RandomGaussCard < Range 
*)
VAR i : LONGCARD;
BEGIN
  i := LONGTRUNC (RandomGaussReal() * FLOAT (Range));
  RETURN (SHORT (i));
END RandomGaussCard;


BEGIN  (* Initialization *)
  Seed := 4.0;
END Random.
