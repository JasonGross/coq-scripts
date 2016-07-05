(** Add Coq 8.4+8.5 notations, so that we don't accidentally make use of Coq 8.4-only notations *)
Require Coq.Lists.List.
Require Coq.Vectors.VectorDef.
Module Export LocalListNotations.
Notation " [ ] " := nil (format "[ ]") : list_scope.
Notation " [ x ; .. ; y ] " := (cons x .. (cons y nil) ..) : list_scope.
Notation " [ x ; y ; .. ; z ] " := (cons x (cons y .. (cons z nil) ..)) : list_scope.
End LocalListNotations.
Module Export LocalVectorNotations.
Notation " [ ] " := (VectorDef.nil _) (format "[ ]") : vector_scope.
Notation " [ x ; .. ; y ] " := (VectorDef.cons _ x _ .. (VectorDef.cons _ y _ (VectorDef.nil _)) ..) : vector_scope.
Notation " [ x ; y ; .. ; z ] " := (VectorDef.cons _ x _ (VectorDef.cons _ y _ .. (VectorDef.cons _ z _ (VectorDef.nil _)) ..)) : vector_scope.
End LocalVectorNotations.
