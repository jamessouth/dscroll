open Core

let run text width direction prefix suffix endcap sleep =
  List.iter text ~f:(fun word -> printf "%s " word);
  width |> string_of_int |> print_endline;
  direction |> print_endline;
  prefix |> print_endline;
  suffix |> print_endline;
  endcap |> print_endline;
  sleep |> string_of_int |> print_endline
