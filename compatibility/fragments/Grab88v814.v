(** Compatibility file for making Coq act similar to Coq v8.8 *)
Local Set Warnings "-deprecated".

Require Export Coq.Compat.Coq814.

Unset Private Polymorphic Universes.

(** Unsafe flag, can hide inconsistencies. *)
Global Unset Template Check.

(** In Coq 8.9, prim token notations follow [Import] rather than
    [Require].  So we make all of the relevant notations accessible in
    compatibility mode. *)
Require Coq.Strings.Ascii Coq.Strings.String.
Export String.StringSyntax Ascii.AsciiSyntax.
Require Coq.ZArith.BinIntDef Coq.PArith.BinPosDef Coq.NArith.BinNatDef.
Require Coq.Reals.Rdefinitions.
Require Coq.Numbers.Cyclic.Int63.Int63.
Require Coq.Numbers.Cyclic.Int31.Int31.
Number Notation BinNums.Z BinIntDef.Z.of_num_int BinIntDef.Z.to_num_int : Z_scope.
Number Notation BinNums.positive BinPosDef.Pos.of_num_int BinPosDef.Pos.to_num_int : positive_scope.
Number Notation BinNums.N BinNatDef.N.of_num_int BinNatDef.N.to_num_int : N_scope.
Number Notation Int31.int31 Int31.phi_inv_nonneg Int31.phi : int31_scope.

Local Set Warnings "-deprecated".
Global Set Firstorder Solver auto with *.
Global Set Instance Generalized Output.

Require Coq.micromega.Lia.
Module Export Coq.
  Module Export omega.
    Module Export Omega.
      #[deprecated(since="8.12", note="The omega tactic was removed in v8.14.  You're now relying on the lia tactic.")]
      Ltac omega := Lia.lia.
    End Omega.
  End omega.
End Coq.
