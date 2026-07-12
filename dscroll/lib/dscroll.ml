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

module Sleep = struct
  external caml_clock_nanosleep : int -> unit = "caml_clock_nanosleep"
  [@@noalloc]
end

module Mode = struct
  type t = Newline | Return | Spaces [@@deriving sexp]

  let arg =
    Command.Arg_type.of_alist_exn ~accept_unique_prefixes:true
      ~case_sensitive:false ~list_values_in_help:false
      [ ("newline", Newline); ("return", Return); ("spaces", Spaces) ]
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

external unsafe_output_bytes : Out_channel.t -> bytes -> int -> int -> unit
  = "caml_ml_output_bytes"
[@@noalloc]

let rec gettextlen acc = function
  | [] -> acc
  | str :: rest -> gettextlen (acc + String.length str + 1) rest

let rec blittext ~dst pos = function
  | [] -> ()
  | s :: ts -> (
      let len = String.length s in
      let poslen = pos + len in
      Bytes.From_string.blit ~src:s ~src_pos:0 ~dst ~dst_pos:pos ~len;
      match ts with
      | [] -> ()
      | _ ->
          Bytes.set dst poslen ' ';
          blittext ~dst (succ poslen) ts)

let getfinaltext text endcap_char endcap_len width direction =
  let text_len = gettextlen (-1) text in
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

  let buf = Bytes.create total_len in

  (match direction with
  | Bounce ->
      Bytes.fill buf ~pos:0 ~len:ecl endcap_char;
      blittext ~dst:buf ecl text;
      Bytes.fill buf ~pos:(ecl + text_len) ~len:ecl endcap_char
  | Left ->
      blittext ~dst:buf 0 text;
      Bytes.fill buf ~pos:text_len ~len:ecl endcap_char;
      Bytes.blit ~src:buf ~src_pos:0 ~dst:buf ~dst_pos:halflen ~len:halflen
  | Right ->
      Bytes.fill buf ~pos:0 ~len:ecl endcap_char;
      blittext ~dst:buf ecl text;
      Bytes.blit ~src:buf ~src_pos:0 ~dst:buf ~dst_pos:halflen ~len:halflen);
  buf

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
  let lentext = Bytes.length finaltext in
  (* cli help info doesn't look right so these chars are here *)
  let lastchar =
    match output_mode with Newline -> '\n' | Return -> '\r' | Spaces -> ' '
  in
  let prefbytes = Bytes.of_string prefix in
  let suffbytes = Bytes.of_string suffix in
  let print pos =
    Out_channel.output_bytes stdout prefbytes;
    unsafe_output_bytes stdout finaltext pos width;
    Out_channel.output_bytes stdout suffbytes;
    Out_channel.output_char stdout lastchar;
    Out_channel.flush stdout
  in
  begin match direction with
  | Direction.Bounce ->
      let lenminuswidth = lentext - width in
      let ticks = succ ((lenminuswidth * cycles) lsl 1) in
      let rec loop ticks pos dir =
        if ticks <= 0 then ()
        else begin
          print pos;
          let ipos = pos + dir in
          let npos =
            if ipos <= 0 then 0
            else if ipos >= lenminuswidth then lenminuswidth
            else ipos
          in
          let ndir =
            if ipos <= 0 then 1 else if ipos >= lenminuswidth then -1 else dir
          in
          Sleep.caml_clock_nanosleep speed;
          (loop [@tailcall]) (pred ticks) npos ndir
        end
      in
      loop ticks 0 1
  | Left ->
      let halflen = lentext asr 1 in
      let ticks = succ (halflen * cycles) in
      let rec loop ticks pos =
        if ticks <= 0 then ()
        else begin
          print pos;
          let ipos = succ pos in
          let npos = if ipos >= halflen then 0 else ipos in
          Sleep.caml_clock_nanosleep speed;
          (loop [@tailcall]) (pred ticks) npos
        end
      in
      loop ticks 0
  | Right ->
      let lenminuswidth = lentext - width in
      let halflen = lentext asr 1 in
      let minpos = lenminuswidth - halflen in
      let ticks = succ (halflen * cycles) in
      let rec loop ticks pos =
        if ticks <= 0 then ()
        else begin
          print pos;
          let ipos = pred pos in
          let npos = if ipos <= minpos then lenminuswidth else ipos in
          Sleep.caml_clock_nanosleep speed;
          (loop [@tailcall]) (pred ticks) npos
        end
      in
      loop ticks lenminuswidth
  end;
  match output_mode with
  | Newline -> ()
  | _ ->
      Out_channel.output_byte stdout 10;
      Out_channel.flush stdout
