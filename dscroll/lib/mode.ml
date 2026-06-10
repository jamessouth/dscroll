open Core

(* compare,equal *)
type t = Newline | Return | Sequence [@@deriving sexp]

let arg =
  Command.Arg_type.of_alist_exn ~accept_unique_prefixes:true
    ~case_sensitive:false ~list_values_in_help:false
    [ ("newline", Newline); ("return", Return); ("sequence", Sequence) ]
