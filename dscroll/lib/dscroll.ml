open Core
module Bench = Bench
module Direction = Direction
module Ints = Ints
module Mode = Mode

module Loop = struct
  external unsafe_long_nanosleep : int -> unit = "caml_long_nanosleep"
  [@@noalloc]
end

type cliflags = {
  cycles : int;
  direction : Direction.t;
  endcap_char : char;
  endcap_len : int;
  initial_pause : int;
  output_mode : Mode.t;
  prefix : string;
  speed : int;
  suffix : string;
  width : int;
}

let rec tloop text lentext ticks width direction =
  match direction with
  | Direction.Bounce -> String.slice text ticks (ticks + width)
  | Left -> (
      let wrds = String.slice text 0 width in
      let nextwrds =
        String.concat [ String.slice text 1 lentext; String.slice wrds 0 1 ]
      in
      match ticks = 0 with
      | true -> wrds
      | false -> tloop nextwrds lentext (pred ticks) width Left)
  | Right -> (
      let wrds = String.suffix text width in
      let nextwrds =
        String.concat
          [ String.suffix wrds 1; String.slice text 0 (lentext - 1) ]
      in
      match ticks = 0 with
      | true -> wrds
      | false -> tloop nextwrds lentext (pred ticks) width Right)

let getfinaltext text endcap_char endcap_len width direction =
  let ecl =
    if Direction.equal direction Bounce then
      Int.max 0 (width - String.length text)
    else
      Int.clamp_exn
        (Int.max endcap_len (width - String.length text))
        ~min:1 ~max:(pred width)
  in
  let ec = String.make ecl endcap_char in
  match direction with
  | Bounce -> String.concat [ ec; text; ec ]
  | Left -> String.concat [ text; ec; text; ec ]
  | Right -> String.concat [ ec; text; ec; text ]

(* let getnextoutput text pos len = String.sub text ~pos ~len *)

let runn text
    {
      cycles;
      direction;
      endcap_char;
      endcap_len;
      initial_pause;
      output_mode;
      prefix;
      speed;
      suffix;
      width;
    } =
  let finaltext =
    getfinaltext
      (text |> String.concat ~sep:" ")
      endcap_char endcap_len width direction
  in
  let lentext = String.length finaltext in
  let lenminuswidth = lentext - width in
  let halflen = lentext asr 1 in
  let ticks =
    match direction with
    | Direction.Bounce -> succ ((lenminuswidth * cycles) lsl 1)
    | Left -> succ (halflen * cycles)
    | Right -> succ (halflen * cycles)
  in
  let getframe frame =
    match direction with
    | Direction.Bounce ->
        if lenminuswidth = 0 then 0
        else
          lenminuswidth - abs ((frame % (lenminuswidth lsl 1)) - lenminuswidth)
    | Left -> frame % halflen
    | Right -> lenminuswidth - (frame % halflen)
  in
  (* print_endline ("ft: " ^ string_of_int lentext ^ " " ^ finaltext); *)
  (* let delay = Time_float_unix.Span.of_int_ms speed in *)
  (* let initial_delay = float_of_int initial_pause /. 1000.0 in *)
  let len = width in
  let buf = finaltext in
  let printxxx =
    match output_mode with
    | Newline -> fun () -> print_endline suffix
    | Return str | Sequence str ->
        fun () ->
          print_string suffix;
          print_string str;
          Out_channel.flush stdout
  in
  print_endline (string_of_int (getframe 1));
  ignore printxxx;
  print_endline (string_of_int len);
  print_endline buf;
  let rec loop ticks frame = () in
  loop ticks 0
(* if ticks <= 0 then
      let _ = match output_mode with Newline -> () | _ -> print_endline "" in
      (* exit 0 *)
      ()
    else begin
      let pos = getframe frame in
      (* print_string (string_of_int pos ^ " " ^ string_of_int ticks ^ "  "); *)
      if frame = 1 then Loop.unsafe_long_nanosleep initial_pause;
      (* let op = getnextoutput finaltext pos width in *)
      print_string prefix;
      Out_channel.output_substring stdout ~buf ~pos ~len;
      printxxx ();
      (* Time_float_unix.pause delay; *)
      Loop.unsafe_long_nanosleep speed;
      (loop [@tailcall]) (pred ticks) (succ frame)
    end
  in
  let (), metrics = Bench.profile_allocation_precise (fun () -> loop ticks 0) in
  printf "\n=== Benchmark Results ===\n";
  printf "Minor words: %d\n" metrics.minor_words_allocated;
  printf "Major words: %d\n%!" metrics.major_words_allocated;
  exit 0 *)

let run text
    {
      cycles;
      direction;
      endcap_char;
      endcap_len;
      initial_pause;
      output_mode;
      prefix;
      speed;
      suffix;
      width;
    } =
  let (), elapsed_us =
    Bench.profile_startup_ns (fun () ->
        runn text
          {
            cycles;
            direction;
            endcap_char;
            endcap_len;
            initial_pause;
            output_mode;
            prefix;
            speed;
            suffix;
            width;
          })
  in

  Printf.printf "Startup and transition took: %d microseconds\n" elapsed_us
