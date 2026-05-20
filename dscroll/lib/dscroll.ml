open Core
module Direction = Direction
module Ints = Ints

type cliflags = {
  cycles : int;
  direction : Direction.t;
  endcap_char : char;
  endcap_len : int;
  no_newline : Bool.t;
  prefix : string;
  speed : int;
  suffix : string;
  width : int;
}

(* let rec loop text delay width cnt =
  match cnt = 0 with
  | true -> exit 0
  | false ->
      let open String in
      let wrds = slice text 0 width in
      print_string (string_of_int (length text) ^ " ");
      print_endline wrds;
      Time_float_unix.pause delay;
      (loop [@tailcall])
        (concat [ slice text 1 (length text); slice wrds 0 1 ])
        delay width (cnt - 1)

let run text flags =
  let words = text |> String.concat ~sep:" " in
  let endcap =
    String.make
      (Int.max
         (flags.width - String.length words)
         (Int.min (flags.width - 1) flags.endcap_len))
      flags.endcap_char
  in
  print_endline (words ^ endcap);

  let delay =
    [ flags.speed |> string_of_int; "ms" ]
    |> String.concat |> Time_float_unix.Span.of_string
  in

  loop (words ^ endcap) delay flags.width 500 *)

let run text flags =
  List.iter text ~f:(fun word -> printf "%s " word);
  flags.width |> string_of_int |> print_endline;
  flags.direction |> Direction.sexp_of_t |> print_s;
  flags.prefix |> print_endline;
  flags.suffix |> print_endline;
  "vvv" ^ String.make flags.endcap_len flags.endcap_char ^ "bbbb"
  |> print_endline;
  flags.speed |> string_of_int |> print_endline;
  flags.no_newline |> printf "%B\n"
