(** See https://coq.inria.fr/bugs/show_bug.cgi?id=4319 for updates *)

(** [set (x := y)] is about 50x slower than it needs to be in Coq 8.4,
    but is about 4x faster than the alternatives in 8.5.  See
    https://coq.inria.fr/bugs/show_bug.cgi?id=3280 (comment 13) for
    more details. *)
Ltac fast_set' x y := set (x := y).
Ltac fast_set'_in x y H := set (x := y) in H.
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" := fast_set' x y.
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" "in" hyp(H) := fast_set'_in x y H.


Require Coq.Lists.List.
Require Coq.Vectors.VectorDef.
Module Export Coq.
Module Export Lists.
Module List.
Module ListNotations.
Export Coq.Lists.List.ListNotations.
Notation " [ x ; .. ; y ] " := (cons x .. (cons y nil) ..) : list_scope.
End ListNotations.
End List.
End Lists.
Module Export Vectors.
Module VectorDef.
Module VectorNotations.
Export Coq.Vectors.VectorDef.VectorNotations.
Notation " [ x ; .. ; y ] " := (VectorDef.cons _ x _ .. (VectorDef.cons _ y _ (VectorDef.nil _)) ..) : vector_scope. (* actually only required in > 8.5pl1, not in >= 8.5pl1 *)
End VectorNotations.
End VectorDef.
End Vectors.
End Coq.
