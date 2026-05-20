open Core

type t = Left | Right | Bounce [@@deriving sexp]

let map =
  String.Map.of_alist_exn
    [ ("left", Left); ("right", Right); ("bounce", Bounce) ]

let arg =
  Command.Arg_type.of_map ~accept_unique_prefixes:true ~case_sensitive:false
    ~list_values_in_help:true map
