open Core

let run text width direction prefix suffix endcap sleep no_newline =
  let sp = "250ms" |> Time_float_unix.Span.of_string in
  (* List.iter text ~f:(fun word -> printf "%s " word);
  width |> string_of_int |> print_endline;
  direction |> print_endline;
  prefix |> print_endline;
  suffix |> print_endline;
  "vvv" ^ endcap ^ "bbbb" |> print_endline;
  sleep |> string_of_int |> print_endline;
  no_newline |> printf "%B\n" *)

  let rec infinite_loop () =
    print_endline "Looping...";
    Time_float_unix.pause sp;
    infinite_loop ()
  in
  infinite_loop ()
