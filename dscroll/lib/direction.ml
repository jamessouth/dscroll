open Core

(* compare *)
type t = Left | Right | Bounce [@@deriving equal, sexp]

let arg =
  Command.Arg_type.of_alist_exn ~accept_unique_prefixes:true
    ~case_sensitive:false ~list_values_in_help:false
    [ ("left", Left); ("right", Right); ("bounce", Bounce) ]
