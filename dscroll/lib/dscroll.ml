open Core

let rec loop words delay =
  print_endline words;
  Time_float_unix.pause delay;
  loop words delay

let run text width direction prefix suffix endcap sleep no_newline =
  let words = text |> String.concat in

  let delay =
    [ sleep |> string_of_int; "ms" ]
    |> String.concat |> Time_float_unix.Span.of_string
    (* List.iter text ~f:(fun word -> printf "%s " word);
  width |> string_of_int |> print_endline;
  direction |> print_endline;
  prefix |> print_endline;
  suffix |> print_endline;
  "vvv" ^ endcap ^ "bbbb" |> print_endline;
  sleep |> string_of_int |> print_endline;
  no_newline |> printf "%B\n" *)
  in
  loop words delay
