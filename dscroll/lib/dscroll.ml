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
  (* cli help info doesn't look right so these chars are here *)
  let lastchar =
    match output_mode with Newline -> '\n' | Return -> '\r' | Spaces -> ' '
  in
  let preflen = String.length prefix in
  let sufflen = String.length suffix in
  let finalbuf = Bytes.create (preflen + width + sufflen + 1) in
  Bytes.From_string.blit ~src:prefix ~src_pos:0 ~dst:finalbuf ~dst_pos:0
    ~len:preflen;
  Bytes.From_string.blit ~src:suffix ~src_pos:0 ~dst:finalbuf
    ~dst_pos:(preflen + width) ~len:sufflen;
  Bytes.set finalbuf (preflen + width + sufflen) lastchar;

  let rec loop ticks frame =
    (* if frame = 1 then Loop.caml_clock_nanosleep initial_pause else (); *)
    if ticks <= 0 then
      let _ = match output_mode with Newline -> () | _ -> print_endline "" in
      ()
    else begin
      Bytes.blit ~src:finaltext ~src_pos:(getframe frame) ~dst:finalbuf
        ~dst_pos:preflen ~len:width;
      Out_channel.output_bytes stdout finalbuf;
      Out_channel.flush stdout;

      Loop.caml_clock_nanosleep speed;
      (loop [@tailcall]) (pred ticks) (succ frame)
    end
  in
  loop ticks 0

(* Explicit state track loop: tracks current position 'pos' and a step delta 'delta' *)
(* let rec loop ticks pos delta =
  if ticks <= 0 then
    let _ = match output_mode with Newline -> () | _ -> print_endline "" in
    ()
  else begin
    Bytes.blit ~src:finaltext ~src_pos:pos ~dst:finalbuf ~dst_pos:preflen ~len:width;
    Out_channel.output_bytes stdout finalbuf;
    Out_channel.flush stdout;
    Loop.caml_clock_nanosleep speed;

    (* Pre-calculate your bounce positions in 1 cycle without using % or abs *)
    let next_pos = pos + delta in
    let next_delta = 
      if lenminuswidth = 0 then 0
      else if next_pos >= lenminuswidth then -1
      else if next_pos <= 0 then 1
      else delta
    in
    (loop [@tailcall]) (pred ticks) next_pos next_delta
  end
in
(* Initialize loop: if left/right scroll, use specialized loop or step wraps *)
loop ticks 0 1 *)

(* Fix B: Unbox and Isolate Variant LayoutsInside your loop, you read output_mode inside a conditional match check. In OCaml, unless a variant is heavily optimized by the compiler, matching a global variant configuration block can pull pointers from the heap. Because your terminal loop has a fixed output_mode, resolve that match statement outside the recursive loop block, or pass an unboxed primitive flag (like a boolean or integer mapping) to avoid memory lookups inside the hot track. *)

(* Fix C: Group Writes Using Buffered PipelinesInstead of executing an explicit kernel flush operation on every individual character shift (Out_channel.flush stdout), let the OCaml standard library cache output data tables natively. Only call flush periodically or allow the OS shell pipe to consume bytes in batches. This minimizes kernel context switching transitions, dropping your context thrashing instantly. *)
