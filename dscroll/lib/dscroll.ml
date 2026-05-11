open Core

let rec loop text delay width =
  let wrds = String.slice text 0 width in
  print_endline wrds;
  Time_float_unix.pause delay;
  let nw =
    String.concat
      [ String.slice text 1 (String.length text); String.slice wrds 0 1 ]
  in
  loop nw delay width

let run text width direction prefix suffix endcap_char endcap_len sleep
    no_newline =
  let words = text |> String.concat ~sep:" " in
  let endcap =
    String.make
      (Int.max (width - String.length words) (Int.min (width - 1) endcap_len))
      endcap_char
  in
  print_endline (words ^ endcap);

  let delay =
    [ sleep |> string_of_int; "ms" ]
    |> String.concat |> Time_float_unix.Span.of_string
  in

  loop (words ^ endcap) delay width

(* let run text width direction prefix suffix endcap_char endcap_len sleep no_newline =
    List.iter text ~f:(fun word -> printf "%s " word);
    width |> string_of_int |> print_endline;
    direction |> print_endline;
    prefix |> print_endline;
    suffix |> print_endline;
    "vvv" ^ String.make endcap_len endcap_char ^ "bbbb" |> print_endline;
    sleep |> string_of_int |> print_endline;
    no_newline |> printf "%B\n" *)
