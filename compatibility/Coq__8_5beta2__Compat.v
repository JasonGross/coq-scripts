(** See https://coq.inria.fr/bugs/show_bug.cgi?id=4319 for updates *)
(** This is required in Coq 8.5 to use the [omega] tactic; in Coq 8.4, it's automatically available.  But ZArith_base puts infix ~ at level 7, and we don't want that, so we don't [Import] it. *)
Require Coq.omega.Omega.
Ltac omega := Coq.omega.Omega.omega.

(** The number of arguments given in [match] statements has changed from 8.4 to 8.5. *)
Global Set Asymmetric Patterns.

(** See bug 3545 *)
Global Set Universal Lemma Under Conjunction.

(** In 8.4, [admit] created a new axiom; in 8.5, it just shelves the goal. *)
Axiom proof_admitted : False.
Ltac admit := clear; abstract case proof_admitted.

(** In 8.5, [refine] leaves over dependent subgoals. *)
Tactic Notation "refine" uconstr(term) := refine term; shelve_unifiable.

Require Coq.Program.Tactics.
Ltac rapply term := Coq.Program.Tactics.rapply term; shelve_unifiable.

(** In 8.4, [constructor (tac)] allowed backtracking across the use of [constructor]; it has been subsumed by [constructor; tac]. *)
Ltac constructor_84 := constructor.
Ltac constructor_84_n n := constructor n.
Ltac constructor_84_tac tac := once (constructor; tac).

Tactic Notation "constructor" := constructor_84.
Tactic Notation "constructor" int_or_var(n) := constructor_84_n n.
Tactic Notation "constructor" "(" tactic(tac) ")" := constructor_84_tac tac.

Global Set Regular Subst Tactic.

(** Some names have changed in the standard library, so we add aliases. *)
Require Coq.ZArith.Int.
Module Export Coq.
  Module Export ZArith.
    Module Int.
      Module Z_as_Int.
        Include Coq.ZArith.Int.Z_as_Int.
        Notation plus := Coq.ZArith.Int.Z_as_Int.add (only parsing).
        Notation minus := Coq.ZArith.Int.Z_as_Int.sub (only parsing).
        Notation mult := Coq.ZArith.Int.Z_as_Int.mul (only parsing).
      End Z_as_Int.
    End Int.
  End ZArith.
End Coq.

(** Many things now import [PeanoNat] rather than [NPeano], so we require it so that the old absolute names in [NPeano.Nat] are available. *)
Require Coq.Numbers.Natural.Peano.NPeano.

(** https://coq.inria.fr/bugs/show_bug.cgi?id=4461 *)
Require Coq.Classes.RelationClasses.
Global Arguments Coq.Classes.RelationClasses.Antisymmetric A eqA {_} _.
Global Arguments Coq.Classes.RelationClasses.symmetry {A} {R} {_} [x] [y] _.
Global Arguments Coq.Classes.RelationClasses.asymmetry {A} {R} {_} [x] [y] _ _.
Global Arguments Coq.Classes.RelationClasses.transitivity {A} {R} {_} [x] [y] [z] _ _.

(** [set (x := y)] is about 50x slower than it needs to be in Coq 8.4,
    but is about 4x faster than the alternatives in 8.5.  See
    https://coq.inria.fr/bugs/show_bug.cgi?id=3280 (comment 13) for
    more details. *)
Ltac fast_set' x y := set (x := y).
Ltac fast_set'_in x y H := set (x := y) in H.
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" := fast_set' x y.
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" "in" hyp(H) := fast_set'_in x y H.
