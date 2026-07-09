open Core
open Dscroll
(* open Core_bench *)

let flags : cliflags Command.Param.t =
  let%map_open.Command cycles =
    flag_optional_with_default_doc "--cycles" ~aliases:[ "-c" ] Ints.nonneg
      (fun x -> Int.sexp_of_t x)
      ~default:Ints.quasi_inf ~doc:"int number of scroll cycles"
  and direction =
    flag_optional_with_default_doc "--direction" ~aliases:[ "-d" ] Direction.arg
      Direction.sexp_of_t ~default:Left
      ~doc:"string scroll left, right, or bounce"
  and endcap_char =
    flag_optional_with_default_doc "--endcap-char" ~aliases:[ "-h" ] char
      (fun x -> Char.sexp_of_t x)
      ~default:' ' ~doc:"char pad between end and start of TEXT"
  and endcap_len =
    flag_optional_with_default_doc "--endcap-len" ~aliases:[ "-l" ] Ints.oneplus
      (fun x -> Int.sexp_of_t x)
      ~default:1 ~doc:"int minimum length of endcap"
  and initial_pause =
    flag_optional_with_default_doc "--initial-pause" ~aliases:[ "-i" ]
      Ints.nonneg
      (fun x -> Int.sexp_of_t x)
      ~default:0 ~doc:"int wait in ms before scrolling begins"
  and output_mode =
    flag_optional_with_default_doc "--output-mode" ~aliases:[ "-o" ] Mode.arg
      Mode.sexp_of_t ~default:Newline
      ~doc:"string print with \\n, \\r, or spaces"
  and prefix =
    flag_optional_with_default_doc "--prefix" ~aliases:[ "-p" ] string
      (fun x -> String.sexp_of_t x)
      ~default:"" ~doc:"string prefix at left of display"
  and speed =
    flag_optional_with_default_doc "--speed" ~aliases:[ "-e" ] Ints.oneplus
      (fun x -> Int.sexp_of_t x)
      ~default:300 ~doc:"int sleep in ms per scroll of TEXT"
  and suffix =
    flag_optional_with_default_doc "--suffix" ~aliases:[ "-s" ] string
      (fun x -> String.sexp_of_t x)
      ~default:"" ~doc:"string suffix at right of display"
  and width =
    flag_optional_with_default_doc "--width" ~aliases:[ "-w" ] Ints.twoplus
      (fun x -> Int.sexp_of_t x)
      ~default:15 ~doc:"int display width"
  in
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
  }

let () =
  Command_unix.run ~version:"1.0" ~build_info:"RWO"
    (Command.basic ~summary:"Generate an MD5 hash of the input data"
       ~readme:(fun () -> "More detailed information")
       (let%map_open.Command text =
          anon (non_empty_sequence_as_list ("text" %: string))
        and flags in
        fun () -> run text flags))

let () =
  Gc.print_stat stderr;
  print_endline "---"

(* let () =
  let text = [ "mary had" ] in
  let flags =
    {
      cycles = 1;
      direction = Bounce;
      endcap_char = 'W';
      endcap_len = 2;
      initial_pause = 0;
      output_mode = Newline;
      prefix = "XX";
      speed = 32;
      suffix = "UU";
      width = 7;
    }
  in
  Command_unix.run
    (Bench.make_command
       [ Bench.Test.create ~name:"Optimized" (fun () -> run text flags) ]) *)

(* 
┌───────────┬──────────┬─────────┬────────────┐
│ Name      │ Time/Run │ mWd/Run │ Percentage │
├───────────┼──────────┼─────────┼────────────┤
│ Optimized │  96.61ms │  23.00w │    100.00% │
└───────────┴──────────┴─────────┴────────────┘ *)

(* let () =
  let s = Gc.quick_stat () in
  Printf.printf
    "minor_collections=%d major_collections=%d promoted_words=%f \
     minor_words=%f major_words=%f\n"
    s.minor_collections s.major_collections s.promoted_words s.minor_words
    s.major_words *)

(* perf record --call-graph dwarf --period=1000 --event=cycles:u *)

(* Performance counter stats for './_build/default/bin/main.exe mary had a little lamb -c 10 -w 17 -e 150' (10 runs):

                 0      context-switches:u               #      0.0 cs/sec  cs_per_second     
                 0      cpu-migrations:u                 #      0.0 migrations/sec  migrations_per_second
             2,042      page-faults:u                    #  51681.0 faults/sec  page_faults_per_second  ( +-  0.02% )
             39.51 msec task-clock:u                     #      0.0 CPUs  CPUs_utilized         ( +-  0.78% )
           123,283      L1-dcache-load-misses:u          #      6.6 %  l1d_miss_rate            ( +-  5.68% )  (46.65%)
           118,394      LLC-loads:u                      #     56.7 %  llc_miss_rate            ( +-  6.93% )  (12.84%)
            59,930      branch-misses:u                  #      2.1 %  branch_miss_rate         ( +-  7.67% )  (21.81%)
         4,397,519      branches:u                       #    111.3 M/sec  branch_frequency     ( +-  6.02% )  (20.77%)
        20,131,101      cpu-cycles:u                     #      0.5 GHz  cycles_frequency       ( +-  3.55% )  (29.82%)
        26,201,951      instructions:u                   #      1.2 instructions  insn_per_cycle  ( +-  4.13% )  (40.51%)

      34.718674823 +- 0.000585936 seconds time elapsed  ( +-  0.00% ) *)

(* Performance counter stats for 'zscroll mary had a little lamb -t 34.7 -l 17 -d .15 -p  ' (10 runs):

                 0      context-switches:u               #      0.0 cs/sec  cs_per_second     
                 0      cpu-migrations:u                 #      0.0 migrations/sec  migrations_per_second
             2,353      page-faults:u                    #  12030.9 faults/sec  page_faults_per_second  ( +-  0.02% )
            195.58 msec task-clock:u                     #      0.0 CPUs  CPUs_utilized         ( +-  1.23% )
         3,894,668      L1-dcache-load-misses:u          #      6.1 %  l1d_miss_rate            ( +-  1.68% )  (38.28%)
         1,901,466      LLC-loads:u                      #     31.6 %  llc_miss_rate            ( +-  3.00% )  (12.23%)
         2,033,074      branch-misses:u                  #      4.6 %  branch_miss_rate         ( +-  1.30% )  (24.72%)
        46,760,594      branches:u                       #    239.1 M/sec  branch_frequency     ( +-  2.60% )  (24.74%)
       201,168,430      cpu-cycles:u                     #      1.0 GHz  cycles_frequency       ( +-  2.19% )  (36.39%)
       228,338,894      instructions:u                   #      1.1 instructions  insn_per_cycle  ( +-  0.92% )  (49.49%)

      34.872235882 +- 0.002206712 seconds time elapsed  ( +-  0.01% ) *)

(* ---
minor_collections:      9
major_collections:      4
compactions:            0
forced_major_collections: 1

minor_words:    300624
promoted_words: 156652
major_words:    168310

top_heap_words: 250828
heap_words:     246409
live_words:     155224
free_words:      88589
largest_free:        0
fragments:        2596

live_blocks: 27442
free_blocks: 0
heap_chunks: 0 *)

(* Performance counter stats for './_build/default/bin/main.exe mary had a little lamb -c 800 -d bounce -w 17 -e 20':

         4,948,328      cache-references:u                                                    
         4,178,601      cache-misses:u                                                        
         1,484,166      LLC-loads:u                                                           
         1,266,559      LLC-load-misses:u                                                     

     161.940851705 seconds time elapsed

       0.274681000 seconds user
       0.583891000 seconds sys *)

(* Performance counter stats for './_build/default/bin/main.exe mary had a little lamb -c 800 -d bounce -w 17 -e 20':

       226,061,143      cycles:u                                                              
        50,717,344      instructions:u                                                        
         4,152,680      cache-misses:u                                                        
         1,261,119      LLC-load-misses:u                                                     

     161.752125860 seconds time elapsed

       0.243196000 seconds user
       0.616591000 seconds sys *)
