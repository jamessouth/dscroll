open Core

let run text length =
  text |> print_endline;
  length |> string_of_int |> print_endline
