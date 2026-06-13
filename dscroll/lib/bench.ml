open Core

type gc_snapshot = { minor_alloc : float; major_alloc : float }

let profile_allocation f =
  Gc.full_major ();
  let start_stats = Gc.quick_stat () in
  let result = f () in
  Gc.minor ();
  let end_stats = Gc.quick_stat () in
  let snapshot =
    {
      minor_alloc = end_stats.minor_words -. start_stats.minor_words;
      major_alloc = end_stats.major_words -. start_stats.major_words;
    }
  in
  (result, snapshot)

external unsafe_nanosleep_ms : int -> unit = "caml_raw_nanosleep_ms" [@@noalloc]

external unsafe_nanosleep_ns_fast : int -> unit = "caml_raw_nanosleep_ns_fast"
[@@noalloc]

let benchmark loops =
  (* Benchmark Millisecond Version *)
  let t0 = Caml_unix.gettimeofday () in
  for _ = 1 to loops do
    unsafe_nanosleep_ms 999
  done;
  let t1 = Caml_unix.gettimeofday () in
  let ms_time = t1 -. t0 in

  (* Benchmark Optimized Nanosecond Version *)
  let t2 = Caml_unix.gettimeofday () in
  for _ = 1 to loops do
    unsafe_nanosleep_ns_fast 999999999
  done;
  let t3 = Caml_unix.gettimeofday () in
  let ns_time = t3 -. t2 in

  Printf.printf "=== Execution Time for %d iterations ===\n" loops;
  Printf.printf "Millisecond version (with div): %fs\n" ms_time;
  Printf.printf "Nanosecond version (no div):    %fs\n" ns_time;
  Printf.printf "Performance Improvement:        %.2f%%\n"
    ((ms_time -. ns_time) /. ms_time *. 100.0)

(* external unsafe_clock_nanosleep_abs : int -> int -> unit
  = "caml_raw_clock_nanosleep_monotonic_abs"
[@@noalloc] *)
