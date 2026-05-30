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

let rec tloop text lentext ticks width =
  match ticks = 0 with
  | true -> text
  | false ->
      let wrds = Core.String.slice text 0 width in
      let nextwrds =
        Core.String.concat
          [ Core.String.slice text 1 lentext; Core.String.slice wrds 0 1 ]
      in
      tloop nextwrds lentext (pred ticks) width

let getfinaltext text endcap_char endcap_len width =
  text
  ^ String.make
      (Int.clamp_exn
         (Int.max endcap_len (width - String.length text))
         ~min:1 ~max:(pred width))
      endcap_char

let getnextoutput text lentext frame width =
  let pos = frame % lentext in
  let len = Int.min width (lentext - pos) in
  String.sub text ~pos ~len ^ String.sub text ~pos:0 ~len:(width - len)

let rec loop text lentext ticks direction delay width frame =
  match ticks = 0 with
  | true -> exit 0
  | false ->
      print_endline (getnextoutput text lentext frame width);
      Time_float_unix.pause delay;
      (loop [@tailcall]) text lentext (pred ticks) direction delay width
        (succ frame)

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
  let lentext = String.length finaltext in
  loop finaltext lentext
    (succ (String.length finaltext * cycles))
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
