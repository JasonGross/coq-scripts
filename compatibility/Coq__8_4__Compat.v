Ltac shelve_unifiable := idtac.
Ltac shelve :=
  let G := match goal with |- ?G => G end in
  let e := fresh in
  evar (e : G);
  eexact e.

(** [set (x := y)] is about 50x slower than it needs to be in Coq 8.4,
    but is about 4x faster than the alternatives in 8.5.  See
    https://coq.inria.fr/bugs/show_bug.cgi?id=3280 (comment 13) for
    more details. *)
Ltac fast_set' x y :=
  pose y as x;
  first [ progress change y with x
        | progress repeat match goal with
                          | [ |- appcontext G[?e] ]
                            => constr_eq y e;
                               let G' := context G[x] in
                               change G'
                          end ].
Ltac fast_set'_in x y H :=
  pose y as x;
  first [ progress change y with x in H
        | progress repeat match type of H with
                          | appcontext G[?e]
                            => constr_eq y e;
                               let G' := context G[x] in
                               change G' in H
                          end ].
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" := fast_set' x y.
Tactic Notation "fast_set" "(" ident(x) ":=" constr(y) ")" "in" hyp(H) := fast_set'_in x y H.

(** Add Coq 8.4+8.5 notations, so that we don't accidentally make use of Coq 8.4-only notations *)
Require Coq.Lists.List.
Require Coq.Vectors.Vector.
Module Export LocalListNotations.
Notation " [ ] " := nil (format "[ ]") : list_scope.
Notation " [ x ; .. ; y ] " := (cons x .. (cons y nil) ..) : list_scope.
Notation " [ x ; y ; .. ; z ] " := (cons x (cons y .. (cons z nil) ..)) : list_scope.
End LocalListNotations.
Module Export LocalVectorNotations.
Notation " [ ] " := (Vector.nil _) (format "[ ]") : vector_scope.
Notation " [ x ; .. ; y ] " := (Vector.cons _ x _ .. (Vector.cons _ y _ (Vector.nil _)) ..) : vector_scope.
Notation " [ x ; y ; .. ; z ] " := (Vector.cons _ x _ (Vector.cons _ y _ .. (Vector.cons _ z _ (Vector.nil _)) ..)) : vector_scope.
End LocalVectorNotations.
