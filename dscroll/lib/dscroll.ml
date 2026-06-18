open Core

module Direction = struct
  type t = Left | Right | Bounce [@@deriving equal, sexp]

  let arg =
    Command.Arg_type.of_alist_exn ~accept_unique_prefixes:true
      ~case_sensitive:false ~list_values_in_help:false
      [ ("left", Left); ("right", Right); ("bounce", Bounce) ]
end

module Ints = struct
  (* The only zeroless pandigital number where the first n digits are divisible by n, used as 'infinity' *)
  let quasi_inf = 381_654_729

  let getint ~min num =
    if min |> Int.is_negative then invalid_arg "min must be >= 0"
    else
      match num |> int_of_string_opt with
      | Some n -> Int.max min n
      | None -> invalid_arg "not an int"

  let nonneg = Command.Arg_type.create (getint ~min:0)
  let oneplus = Command.Arg_type.create (getint ~min:1)
  let twoplus = Command.Arg_type.create (getint ~min:2)
end

module Loop = struct
  external unsafe_long_nanosleep : int -> unit = "caml_long_nanosleep"
  [@@noalloc]
end

module Mode = struct
  type t = Newline | Return of string | Sequence of string [@@deriving sexp]

  let arg =
    Command.Arg_type.of_alist_exn ~accept_unique_prefixes:true
      ~case_sensitive:false ~list_values_in_help:false
      [
        ("newline", Newline); ("return", Return "\r"); ("sequence", Sequence " ");
      ]
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

let getfinaltext text endcap_char endcap_len width direction =
  let text_len =
    List.fold text ~init:(-1) ~f:(fun acc s -> acc + String.length s + 1)
  in
  let width_minus_text_len = width - text_len in

  let ecl =
    if Direction.equal direction Bounce then Int.max 0 width_minus_text_len
    else
      Int.clamp_exn
        (Int.max endcap_len width_minus_text_len)
        ~min:1 ~max:(pred width)
  in
  let halflen = text_len + ecl in
  let total_len =
    match direction with
    | Bounce -> ecl + halflen
    | Left | Right -> halflen lsl 1
  in

  let rec blit_text_list ~dst text pos =
    match text with
    | [] -> ()
    | [ s ] ->
        let len = String.length s in
        Bytes.From_string.blit ~src:s ~src_pos:0 ~dst ~dst_pos:pos ~len
    | s :: ts ->
        let len = String.length s in
        Bytes.From_string.blit ~src:s ~src_pos:0 ~dst ~dst_pos:pos ~len;
        Bytes.set dst (pos + len) ' ';
        blit_text_list ~dst ts (pos + len + 1)
  in
  let buf = Bytes.create total_len in

  (match direction with
  | Bounce ->
      Bytes.fill buf ~pos:0 ~len:ecl endcap_char;
      blit_text_list ~dst:buf text ecl;
      Bytes.fill buf ~pos:(ecl + text_len) ~len:ecl endcap_char
  | Left ->
      blit_text_list ~dst:buf text 0;
      Bytes.fill buf ~pos:text_len ~len:ecl endcap_char;
      Bytes.blit ~src:buf ~src_pos:0 ~dst:buf ~dst_pos:halflen ~len:halflen
  | Right ->
      Bytes.fill buf ~pos:0 ~len:ecl endcap_char;
      blit_text_list ~dst:buf text ecl;
      Bytes.blit ~src:buf ~src_pos:0 ~dst:buf ~dst_pos:halflen ~len:halflen);

  Bytes.unsafe_to_string ~no_mutation_while_string_reachable:buf

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
  let finaltext = getfinaltext text endcap_char endcap_len width direction in
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
  let rec loop ticks frame =
    if ticks <= 0 then
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
  loop ticks 0
