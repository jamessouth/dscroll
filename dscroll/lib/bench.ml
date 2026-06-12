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

external unsafe_clock_nanosleep_abs : int -> int -> unit
  = "caml_raw_clock_nanosleep_monotonic_abs"
[@@noalloc]
