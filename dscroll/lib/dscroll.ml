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

let getnextoutput text pos len = String.sub text ~pos ~len

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
        let totlen = lenminuswidth in
        if totlen = 0 then 0
        else totlen - abs ((frame % (lenminuswidth lsl 1)) - totlen)
    | Left -> frame % halflen
    | Right -> lenminuswidth - (frame % halflen)
  in
  print_endline ("ft: " ^ string_of_int lentext ^ " " ^ finaltext);
  let delay = Time_float_unix.Span.of_string [%string "%{speed#Int}ms"] in
  let rec loop ticks frame =
    let frms = getframe frame in
    if ticks = 0 then (
      if no_newline then print_endline "";
      exit 0)
    else print_string (string_of_int frms ^ " ");
    let _ =
      if frame = 1 then
        Time_float_unix.Span.of_string [%string "%{initial_pause#Int}ms"]
        |> Time_float_unix.pause
      else ()
    in
    if no_newline then print_string (getnextoutput finaltext frms width);Out_channel.flush stdout;
    else print_endline (getnextoutput finaltext frms width);
    Time_float_unix.pause delay;
    (loop [@tailcall]) (pred ticks) (succ frame)
  in
  loop ticks 0

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

(* ------------------------------------------ *)

(* ----------------------------------------------*)

(* open Core

type t = {
  (* We use an internal mutable buffer that expands if new text is longer *)
  mutable buffer   : bytes;
  mutable orig_len : int;
}

(* Creates a scroller. Allocates exactly twice the text length. *)
let create (initial_text : string) : t =
  let len = String.length initial_text in
  let double_len = len * 2 in
  let buffer = Bytes.create double_len in
  if len > 0 then begin
    Bytes.blit_string ~src:initial_text ~src_pos:0 ~dst:buffer ~dst_pos:0 ~len;
    Bytes.blit_string ~src:initial_text ~src_pos:0 ~dst:buffer ~dst_pos:len ~len;
  end;
  { buffer; orig_len = len }

(* Update the text on the fly. 
   Only re-allocates a buffer if the new text is strictly larger. *)
let update_text (s : t) (new_text : string) : unit =
  let len = String.length new_text in
  let required_space = len * 2 in
  s.orig_len <- len;
  
  if len > 0 then begin
    (* Resize internal buffer only if it's too small *)
    if Bytes.length s.buffer < required_space then begin
      s.buffer <- Bytes.create required_space
    end;
    (* Mirror the text into our reusable memory buffer *)
    Bytes.blit_string ~src:new_text ~src_pos:0 ~dst:s.buffer ~dst_pos:0 ~len;
    Bytes.blit_string ~src:new_text ~src_pos:0 ~dst:s.buffer ~dst_pos:len ~len;
  end

(* Zero-allocation draw. Extracts the rotated text slice without allocations. *)
let blit_frame (s : t) (offset : int) (dst : bytes) ~dst_pos ~view_len : unit =
  if s.orig_len = 0 then ()
  else begin
    let safe_offset = offset % s.orig_len in
    (* Limit rendering length to whichever is smaller: the screen view or text *)
    let render_len = Int.min view_len s.orig_len in
    Bytes.blit 
      ~src:s.buffer ~src_pos:safe_offset 
      ~dst ~dst_pos ~len:render_len
  end


  Zero Allocations During Scroll: When your main animation tick loops and calls blit_frame, it reads directly out of the existing buffer and puts it straight into your UI/terminal rendering array (dst). The OCaml GC does completely zero work.Cheap Track Changes: When your music player switches tracks, you simply call update_text scroller "Now Playing: Daft Punk - One More Time".Smart Memory Management: Notice the if Bytes.length s.buffer < required_space check inside update_text. If the new song title is shorter than or equal to the previous song, it doesn't allocate any new memory at all. It just overwrites the bytes already sitting on the heap.

    (* 1. Initialize once *)
let scroller = create "Initial Booting Text... "
let screen_output = Bytes.create 20 (* Your fixed window screen size *)

(* 2. Inside your 60FPS or sub-second timer loop *)
let run_tick frame_count =
  (* Draw frame into screen_output completely garbage-free *)
  blit_frame scroller frame_count screen_output ~dst_pos:0 ~view_len:20;
  render_to_screen screen_output

(* 3. Inside your asynchronous music player hook *)
let on_song_change new_track_title =
  update_text scroller (new_track_title ^ "   ***   ")


  Since you are writing straight to stdout, we can optimize this further by avoiding allocations during string printing.In OCaml, functions like print_string or printf have to allocate memory internally or do conversions. To keep your loop completely garbage-collector free, you should write your bytes buffer directly to the terminal's file descriptor using Out_channel.output_bytes.Here is how to set up a clean, non-allocating render loop using plain stdout.

  open Core

(* Reusing the scroller module from our previous conversation *)
let scroller = create "Now Playing: Daft Punk - One More Time  ***  "
let view_width = 20
let screen_output = Bytes.create view_width

(* This terminal escape code moves the cursor back to the start of the line *)
let carriage_return = "\r"

let run_animation_loop () =
  let offset = ref 0 in
  
  while true do
    (* 1. Pull the correct frame into our reusable bytes container *)
    blit_frame scroller !offset screen_output ~dst_pos:0 ~view_len:view_width;
    
    (* 2. Reset terminal cursor back to column 0 without allocating *)
    Out_channel.output_string stdout carriage_return;
    
    (* 3. Blast the binary bytes directly into stdout *)
    Out_channel.output_bytes stdout screen_output;
    
    (* 4. Force the OS to flush the stdout buffer immediately *)
    Out_channel.flush stdout;
    
    (* 5. Advance frame counter & sleep (e.g., 150ms for smooth scroll) *)
    offset := !offset + 1;
    Time_float.sleep 0.150
  done


  \r vs \n: Using the carriage return (\r) brings the cursor back to the beginning of the current row instead of starting a new line (\n). This makes the text cleanly overwrite itself in place on your terminal window.Out_channel.output_bytes: This function copies bytes directly out of your pre-allocated screen_output variable and hands them to the operating system's kernel buffer. It completely skips OCaml's string-building features, ensuring zero memory overhead.Out_channel.flush: By default, standard output buffers data and only pushes it to the monitor when it sees a newline character. Since we are using \r, we manually call flush to force the text onto the screen instantly every single frame.

  open Core

let scroller = create "Now Playing: Daft Punk - One More Time  ***  "
let view_width = 25
let screen_output = Bytes.create view_width

let run_animation_loop () =
  let offset = ref 0 in
  while true do
    (* 1. Pull the frame data completely allocation-free *)
    blit_frame scroller !offset screen_output ~dst_pos:0 ~view_len:view_width;
    
    (* 2. Send the exact slice directly to stdout *)
    Out_channel.output_bytes stdout screen_output;
    
    (* 3. Polybar updates *only* when it hits a fresh newline character *)
    Out_channel.output_string stdout "\n";
    
    (* 4. Instantly force the payload out of the runtime buffer *)
    Out_channel.flush stdout;
    
    offset := !offset + 1;
    Time_float.sleep 0.200 (* 200ms gives a natural ticker speed *)
  done *)
