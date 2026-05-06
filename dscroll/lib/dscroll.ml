open Core

let run text length direction =
  List.iter text ~f:(fun word -> printf "%s " word);
  length |> string_of_int |> print_endline;
  direction |> print_endline
