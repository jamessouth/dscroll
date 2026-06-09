(* open Core *)

type t = {
  direction : Direction.t;
  ticks : int;
  modlen : int;
  totlen : int option;
}

(* [@@deriving equal, sexp] *)
