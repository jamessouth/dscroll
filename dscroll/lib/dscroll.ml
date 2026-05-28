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

let getfinaltext text endcap_char endcap_len width =
  text
  ^ String.make
      (Int.clamp_exn
         (Int.max endcap_len (width - String.length text))
         ~min:1 ~max:(width - 1))
      endcap_char

let rec loop text ticks direction delay width frame =
  match ticks = 0 with
  | true -> exit 0
  | false ->
      let open String in
      let wrds = slice text 0 width in
      print_string
        (string_of_int (length text)
        ^ " " ^ string_of_int ticks ^ " "
        ^ string_of_int (frame % length text)
        ^ " "
        ^ sub text
            ~pos:(frame % length text)
            ~len:(length text - (frame % length text))
        ^ ": ");
      print_endline wrds;
      Time_float_unix.pause delay;
      let nextwrds = concat [ slice text 1 (length text); slice wrds 0 1 ] in
      (loop [@tailcall]) nextwrds (ticks - 1) direction delay width (frame + 1)

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
  let finaltext =
    getfinaltext (text |> String.concat ~sep:" ") endcap_char endcap_len width
  in
  print_endline finaltext;
  let delay =
    [ speed |> string_of_int; "ms" ]
    |> String.concat |> Time_float_unix.Span.of_string
  in
  loop finaltext
    ((String.length finaltext * cycles) + 1)
    direction delay width 0

(* let run text { endcap_char; endcap_len; width; _ } =
  print_endline
    (getfinaltext (text |> String.concat ~sep:" ") endcap_char endcap_len width) *)

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
