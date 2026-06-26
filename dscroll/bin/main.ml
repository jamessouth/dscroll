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
        fun () ->
          for i = 1 to 1 do
            run text flags
          done))

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

(* % time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 90.46   10.742094           9   1100000           write
  9.52    1.130571          11    100000           nanosleep
  0.02    0.001872        1872         1           execve
  0.01    0.000703           9        76           mmap
  0.00    0.000081          20         4           mprotect
  0.00    0.000061          20         3           openat
  0.00    0.000047           7         6           brk
  0.00    0.000035          35         1           munmap
  0.00    0.000026          26         1           readlink
  0.00    0.000025           8         3           fstat
  0.00    0.000014           4         3         3 lseek
  0.00    0.000013           6         2           read
  0.00    0.000012           4         3           sigaltstack
  0.00    0.000012          12         1           prlimit64
  0.00    0.000012          12         1           getrandom
  0.00    0.000011           3         3           close
  0.00    0.000010          10         1           getcwd
  0.00    0.000009           9         1           newfstatat
  0.00    0.000005           5         1           rt_sigaction
  0.00    0.000000           0         2           pread64
  0.00    0.000000           0         1         1 access
  0.00    0.000000           0         1           arch_prctl
  0.00    0.000000           0         1           set_tid_address
  0.00    0.000000           0         1           set_robust_list
  0.00    0.000000           0         1           rseq
------ ----------- ----------- --------- --------- ----------------
100.00   11.875613           9   1200118         4 total *)

(* % time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 90.75    1.698869          10    165000           write
  9.21    0.172400          11     15000           nanosleep
  0.03    0.000539           7        76           mmap
  0.00    0.000044          14         3           openat
  0.00    0.000043          43         1           readlink
  0.00    0.000039           9         4           mprotect
  0.00    0.000028           9         3         3 lseek
  0.00    0.000024          24         1         1 access
  0.00    0.000023           3         6           brk
  0.00    0.000020           6         3           fstat
  0.00    0.000018           9         2           read
  0.00    0.000016           5         3           close
  0.00    0.000012          12         1           newfstatat
  0.00    0.000011           5         2           pread64
  0.00    0.000009           3         3           sigaltstack
  0.00    0.000008           8         1           munmap
  0.00    0.000006           6         1           rseq
  0.00    0.000005           5         1           arch_prctl
  0.00    0.000004           4         1           getcwd
  0.00    0.000004           4         1           set_tid_address
  0.00    0.000004           4         1           set_robust_list
  0.00    0.000002           2         1           prlimit64
  0.00    0.000002           2         1           getrandom
  0.00    0.000001           1         1           rt_sigaction
  0.00    0.000000           0         1           execve
------ ----------- ----------- --------- --------- ----------------
100.00    1.872131          10    180118         4 total *)

(* Samples: 12K of event 'cpu/cycles/Pu', Event count (approx.): 2731928503
  Children      Self  Command   Shared O  Symbol
+    1.77%     0.93%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.53%     0.25%  main.exe  main.exe  [.] Dscroll.run_4588
     0.43%     0.33%  main.exe  main.exe  [.] Dscroll.getframe_4606
     0.35%     0.11%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936
     0.25%     0.18%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328
     0.08%     0.08%  main.exe  main.exe  [.] Dscroll.fun_4796 *)

(* Samples: 16K of event 'cpu/cycles/Pu', Event count (approx.): 3257564109
  Children      Self  Command   Shared O  Symbol
     1.32%     1.32%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.32%     0.32%  main.exe  main.exe  [.] Dscroll.nff_4610
     0.30%     0.30%  main.exe  main.exe  [.] Dscroll.run_4588
     0.28%     0.28%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328
     0.13%     0.13%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936
     0.07%     0.07%  main.exe  main.exe  [.] Dscroll.fun_4801 *)

(* --------------------------------------- *)

(* Samples: 18K of event 'cpu/cycles/Pu', Event count (approx.): 4710224922
  Children      Self  Command   Shared O  Symbol
     1.11%     0.90%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.26%     0.23%  main.exe  main.exe  [.] Dscroll.run_4588
     0.22%     0.22%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328
     0.14%     0.14%  main.exe  main.exe  [.] Dscroll.getframe_4606
     0.06%     0.03%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936
     0.04%     0.04%  main.exe  main.exe  [.] Dscroll.fun_4796 *)

(* Samples: 23K of event 'cpu/cycles/Pu', Event count (approx.): 5322417423
  Children      Self  Command   Shared O  Symbol
     1.08%     1.02%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.22%     0.21%  main.exe  main.exe  [.] Dscroll.run_4588
     0.16%     0.16%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328
     0.14%     0.14%  main.exe  main.exe  [.] Dscroll.nff_4610
     0.08%     0.08%  main.exe  main.exe  [.] Dscroll.fun_4801
     0.07%     0.05%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936 *)

(* Samples: 16K of event 'cpu/cycles/Pu', Event count (approx.): 4485388381
  Children      Self  Command   Shared O  Symbol
+    1.79%     0.93%  main.exe  main.exe  [.] Dscroll.loop_4613           
     0.42%     0.13%  main.exe  main.exe  [.] Dscroll.run_4588               
     0.35%     0.12%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936   
     0.29%     0.24%  main.exe  main.exe  [.] Dscroll.getframe_4606       
     0.24%     0.17%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328 
     0.04%     0.04%  main.exe  main.exe  [.] Dscroll.fun_4796     *)

(* Samples: 22K of event 'cpu/cycles/Pu', Event count (approx.): 5247013487
  Children      Self  Command   Shared O  Symbol
     1.26%     1.11%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.25%     0.17%  main.exe  main.exe  [.] Dscroll.run_4588
     0.21%     0.21%  main.exe  main.exe  [.] Dscroll.nff_4610
     0.19%     0.17%  main.exe  main.exe  [.] Dscroll.blit_text_list_4328
     0.15%     0.08%  main.exe  main.exe  [.] Dscroll.getfinaltext_3936
     0.07%     0.07%  main.exe  main.exe  [.] Dscroll.fun_4801 *)

(* left *)
(* 0  context-switches:u          #  0.0 cs/sec  cs_per_second 
0  cpu-migrations:u            #  0.0 migrations/sec  migrations_per_second
2,363  page-faults:u           #   1648.7 faults/sec  page_faults_per_second
1,433.29 msec task-clock:u     #  0.5 CPUs  CPUs_utilized   
560,190  branch-misses:u       #  0.4 %  branch_miss_rate (69.25%)
131,787,818  branches:u        # 91.9 M/sec  branch_frequency (68.83%)
343,737,399  cpu-cycles:u      #  0.2 GHz  cycles_frequency   (63.28%)
548,247,401  instructions:u    #  1.6 instructions  insn_per_cycle  (62.91%)

   3.021963600 seconds time elapsed
   0.676858000 seconds user
   0.681318000 seconds sys *)

(* bounce *)
(* 0  context-switches:u       #  0.0 cs/sec  cs_per_second 
0  cpu-migrations:u            #  0.0 migrations/sec  migrations_per_second
1,849  page-faults:u           #   1670.4 faults/sec  page_faults_per_second
1,106.92 msec task-clock:u     #  0.4 CPUs  CPUs_utilized   
569,486  branch-misses:u       #  0.8 %  branch_miss_rate (61.23%)
66,021,959  branches:u         # 59.6 M/sec  branch_frequency (71.41%)
200,046,341  cpu-cycles:u      #  0.2 GHz  cycles_frequency   (60.95%)
296,084,456  instructions:u    #  1.5 instructions  insn_per_cycle  (60.37%)

2.853682142 seconds time elapsed
0.361082000 seconds user
0.681369000 seconds sys *)

(* right *)
(* 0  context-switches:u        #  0.0 cs/sec  cs_per_second 
0  cpu-migrations:u             #  0.0 migrations/sec  migrations_per_second
2,363  page-faults:u            #   1676.8 faults/sec  page_faults_per_second
1,409.25 msec task-clock:u      #  0.5 CPUs  CPUs_utilized   
476,591  branch-misses:u        #  0.4 %  branch_miss_rate (66.97%)
132,450,994  branches:u         # 94.0 M/sec  branch_frequency (69.44%)
338,148,809  cpu-cycles:u       #  0.2 GHz  cycles_frequency   (66.90%)
547,778,277  instructions:u     #  1.6 instructions  insn_per_cycle  (63.74%)

       3.086884819 seconds time elapsed
       0.724064000 seconds user
       0.613753000 seconds sys *)
