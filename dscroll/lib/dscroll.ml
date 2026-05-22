open Core
module Direction = Direction
module Ints = Ints

type cliflags = {
  cycles : int;
  direction : Direction.t;
  endcap_char : char;
  endcap_len : int;
  initial_pause : int;
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

let run text
    {
      cycles;
      direction;
      endcap_char;
      endcap_len;
      initial_pause;
      no_newline;
      prefix;
      speed;
      suffix;
      width;
    } =

  in
  print_endline (words ^ endcap);
  let delay =
    [ speed |> string_of_int; "ms" ]
    |> String.concat |> Time_float_unix.Span.of_string
  in
  loop (words ^ endcap) delay width 500 *)

let getfinaltext text endcap_char endcap_len width =
  let words = text |> String.concat ~sep:" " in
  let endcap =
    String.make
      (* prevents same char being shown twice *)
      (* kokoko jojojo -ecc W *)
      (* prevents showing only endcap_char (blank display)*)
      (* kokoko jojojo gogogo -ecl 18 -ecc W *)
      (* separates end and beginning of text *)
      (* kokoko jojojo gogogo -ecc W *)
      (Int.max (width - String.length words) (Int.min (width - 1) endcap_len))
      endcap_char
  in
  words ^ endcap

let run text { endcap_char; endcap_len; width; _ } =
  print_endline (getfinaltext text endcap_char endcap_len width)

(* let run text flags =
  List.iter text ~f:(fun word -> printf "%s " word);
  flags.width |> string_of_int |> print_endline;
  flags.direction |> Direction.sexp_of_t |> print_s;
  flags.prefix |> print_endline;
  flags.suffix |> print_endline;
  "vvv" ^ String.make flags.endcap_len flags.endcap_char ^ "bbbb"
  |> print_endline;
  flags.speed |> string_of_int |> print_endline;
  flags.no_newline |> printf "%B\n" *)
