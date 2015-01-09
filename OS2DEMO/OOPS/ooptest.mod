MODULE OopTest;

(* Type-bound procedure demo. Copyright 1995 (c) by Anthony Busigin *)

(*$XL+ *)

IMPORT
  InOut, RealInOut;

TYPE
  TName = ARRAY[0..255] OF CHAR;

  TAnimal = RECORD
    weight : LONGREAL;
  END;

  TDog = RECORD( TAnimal )
    Breed : TName;
  END;

  TCat = RECORD( TAnimal )
    Breed : TName;
  END;

  PROCEDURE ( VAR o: TAnimal ) GetWeight() : LONGREAL;
  BEGIN
    RETURN o.weight;
  END GetWeight;

  PROCEDURE ( VAR o: TDog ) MakeNoise;
  BEGIN
    InOut.WriteString("DOG: Bark Bark!");
    InOut.WriteLn;
  END MakeNoise;

  PROCEDURE ( VAR o: TCat ) MakeNoise;
  BEGIN
    InOut.WriteString("CAT: Meow, Meow!");
    InOut.WriteLn;
  END MakeNoise;

VAR
  d : TDog;
  c : TCat;
BEGIN
  InOut.WriteLn;
  d.MakeNoise();
  c.MakeNoise();
END OopTest.
