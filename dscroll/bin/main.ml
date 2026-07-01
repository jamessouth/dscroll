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

(* __asm__(
".global caml_long_nanosleep\n"
".type caml_long_nanosleep, @function\n"
"caml_long_nanosleep:\n"
"    sar $1, %rdi\n"
"    imul $1000000, %rdi, %rax\n"
"    push %r11\n"
"    xor %rdx, %rdx\n"
"    mov $1000000000, %rcx\n"
"    div %rcx\n"
"    push %rdx\n"
"    push %rax\n"
"    mov $35, %rax\n"
"    mov %rsp, %rdi\n"
"    xor %rsi, %rsi\n"
"    syscall\n"
"    add $16, %rsp\n"
"    pop %r11\n"
"    mov $1, %rax\n"
"    ret\n"
); *)

(* profiling,fix loop
     3.44%     3.44%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.33%     0.33%  main.exe  main.exe  [.] Dscroll.getframe_4606 *)

(* asm,c
+    9.43%     3.55%  main.exe  main.exe  [.] Dscroll.loop_4262
+    1.27%     0.70%  main.exe  main.exe  [.] Dscroll.next_4258
     0.06%     0.00%  main.exe  main.exe  [.] Dscroll.45
     0.00%     0.00%  main.exe  main.exe  [.] Dscroll.43 *)

(* +    8.43%     2.88%  main.exe  main.exe  [.] Dscroll.loop_4255 *)
(* +    8.88%     2.99%  main.exe  main.exe  [.] Dscroll.run_4233
     0.00%     0.00%  main.exe  main.exe  [.] Dscroll.entry
-------------------------------------------------


profiling,fix loop
     1.25%     1.25%  main.exe  main.exe  [.] caml_call_gc
     0.75%     0.75%  main.exe  main.exe  [.] caml_handle_gc_interrupt
     0.59%     0.59%  main.exe  main.exe  [.] caml_poll_gc_work
     0.03%     0.00%  main.exe  main.exe  [.] caml_init_gc
     0.00%     0.00%  main.exe  main.exe  [.] caml_alloc_shr_check_gc


asm,c
+ 3.97%  0.72%  main.exe  main.exe  [.] caml_call_gc  
  0.70%  0.48%  main.exe  main.exe  [.] caml_poll_gc_work
  0.28%  0.00%  main.exe  main.exe  [.] classify_gc_root (inlined) 
  0.24%  0.23%  main.exe  main.exe  [.] caml_handle_gc_interrupt
  0.06%  0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)
  0.03%  0.00%  main.exe  main.exe  [.] caml_init_gc  
  0.00%  0.00%  main.exe  main.exe  [.] caml_alloc_shr_check_gc 

+ 7.61%  1.58%  main.exe  main.exe  [.] caml_call_gc
+ 0.79%  0.77%  main.exe  main.exe  [.] caml_handle_gc_interrupt 
0.57%  0.46%  main.exe  main.exe  [.] caml_poll_gc_work  
 0.27%  0.00%  main.exe  main.exe  [.] classify_gc_root (inlined)  
0.05%  0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)
 0.03% 0.00%  main.exe  main.exe  [.] caml_init_gc   
 0.00% 0.00%  main.exe  main.exe  [.] caml_alloc_shr_check_gc   
+ 7.60%  1.52%  main.exe  main.exe  [.] caml_call_gc  
+ 0.92%  0.89%  main.exe  main.exe  [.] caml_handle_gc_interrupt
  0.57%  0.49%  main.exe  main.exe  [.] caml_poll_gc_work 
  0.32%  0.00%  main.exe  main.exe  [.] classify_gc_root (inlined)
  0.05%  0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)
  0.02%  0.00%  main.exe  main.exe  [.] caml_init_gc    
------------------------------------------------------------

0.07%  0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_s
 0.07%  0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inlin
0.07%  0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once 
0.07%  0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_dom

  0.06% 0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once
 0.06% 0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_doma
 0.06% 0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_sl
 0.06% 0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inline
 0.00% 0.00%  main.exe  main.exe  [.] reserve_minor_heaps_from_stw_single
 0.05% 0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once 
 0.05% 0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_dom
 0.05% 0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_s
 0.05% 0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inli



+0.59 1.77 2.09%  0.52%  main.exe  main.exe[.] caml_thread_enter_blocking_section
+0.35 1.67 1.28%  0.38%  main.exe  main.exe[.] caml_memprof_enter_thread
+ 1.32 _ 1.13%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_trylock (inlined)
+1.3 _ 1.09%  1.09%  main.exe  libc.so.6  [.] pthread_mutex_trylock
+1.15 _ 0.99%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)
+ 0.94%  0.94%  main.exe  libc.so.6  [.] pthread_mutex_lock
+0.17 1.15 0.94%  0.14%  main.exe  main.exe[.] caml_thread_leave_blocking_section
+ 0.84%  0.00%  main.exe  main.exe[.] thread_lock_acquire (inlined)
+ 0.73%  0.00%  main.exe  libc.so.6  [.] ___pthread_getspecific (inlined)
+ 0.71%  0.71%  main.exe  libc.so.6  [.] pthread_getspecific
  0.30%  0.00%  main.exe  main.exe[.] thread_config (inlined)
  0.26%  0.26%  main.exe  libc.so.6  [.] pthread_cond_signal
  0.26%  0.00%  main.exe  libc.so.6  [.] ___pthread_cond_signal (inlined)
  0.25%  0.25%  main.exe  main.exe[.] pthread_mutex_unlock@plt
  0.22%  0.22%  main.exe  main.exe[.] pthread_getspecific@plt
  0.19%  0.19%  main.exe  main.exe[.] pthread_mutex_lock@plt
  0.19%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_unlock (inlined)
  0.18%  0.18%  main.exe  libc.so.6  [.] pthread_mutex_unlock
  0.08%  0.08%  main.exe  main.exe[.] pthread_mutex_trylock@plt
  0.01%  0.01%  main.exe  main.exe[.] pthread_cond_signal@plt
  0.01%  0.00%  main.exe  main.exe[.] thread_lock_release (inlined)
  0.00%  0.00%  main.exe  main.exe[.] backup_thread_running (inlined)

+ 2.22%  0.62%  main.exe  main.exe[.] caml_thread_enter_blocking_section 
+ 1.24%  0.39%  main.exe  main.exe[.] caml_memprof_enter_thread
+ 1.16%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_trylock (inlined) 
+ 1.13%  1.13%  main.exe  libc.so.6  [.] pthread_mutex_trylock 
+ 1.12%  0.34%  main.exe  main.exe[.] caml_thread_leave_blocking_section 
+ 0.89%  0.00%  main.exe  main.exe[.] thread_lock_acquire (inlined)  
+ 0.80%  0.00%  main.exe  libc.so.6  [.] ___pthread_getspecific (inlined
+ 0.77%  0.77%  main.exe  libc.so.6  [.] pthread_getspecific
+ 0.64%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)
+ 0.61%  0.61%  main.exe  libc.so.6  [.] pthread_mutex_lock 
  0.32%  0.31%  main.exe  main.exe[.] pthread_getspecific@plt  
  0.29%  0.29%  main.exe  main.exe[.] pthread_mutex_unlock@plt 
  0.26%  0.00%  main.exe  libc.so.6  [.] ___pthread_cond_signal (inlined
  0.26%  0.00%  main.exe  main.exe[.] thread_config (inlined)  
  0.26%  0.26%  main.exe  libc.so.6  [.] pthread_cond_signal
  0.19%  0.19%  main.exe  main.exe[.] pthread_mutex_lock@plt
  0.18%  0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_unlock (inlined)
  0.16%  0.16%  main.exe  libc.so.6  [.] pthread_mutex_unlock  
  0.03%  0.03%  main.exe  main.exe[.] pthread_mutex_trylock@plt
  0.02%  0.00%  main.exe  main.exe[.] thread_lock_release (inlined)  
  0.01%  0.00%  main.exe  main.exe[.] backup_thread_running (inlined)
  0.00%  0.00%  main.exe  main.exe[.] pthread_cond_signal@plt     *)

(* 1 dscroll 3.3 1.05
  +    2.66%     0.98%  main.exe  main.exe  [.] caml_call_gc                                          
     0.29%     0.25%  main.exe  main.exe  [.] caml_poll_gc_work                                                      
     0.21%     0.00%  main.exe  main.exe  [.] classify_gc_root (inlined)                                             
     0.08%     0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)                                      
     0.04%     0.03%  main.exe  main.exe  [.] caml_handle_gc_interrupt                                               
     0.01%     0.00%  main.exe  main.exe  [.] caml_init_gc  

          0.03%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once                                       ◆
     0.03%     0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_domains (inlined)             
     0.03%     0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_slice (inlined)             
     0.03%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inlined)   

     +    2.16%     0.24%  main.exe  main.exe   [.] caml_thread_leave_blocking_section                                     ◆
+    1.58%     0.00%  main.exe  main.exe   [.] thread_lock_acquire (inlined)                                       
+    1.09%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)                                     
+    1.08%     1.08%  main.exe  libc.so.6  [.] pthread_mutex_lock                                                  
+    0.91%     0.43%  main.exe  main.exe   [.] caml_memprof_enter_thread                                           
+    0.82%     0.19%  main.exe  main.exe   [.] caml_thread_enter_blocking_section                                  
+    0.73%     0.00%  main.exe  libc.so.6  [.] ___pthread_getspecific (inlined)                                    
+    0.72%     0.72%  main.exe  libc.so.6  [.] pthread_getspecific                                                 
+    0.68%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_trylock (inlined)                                  
+    0.66%     0.66%  main.exe  libc.so.6  [.] pthread_mutex_trylock                                               
     0.29%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_unlock (inlined)                                   
     0.29%     0.29%  main.exe  libc.so.6  [.] pthread_mutex_unlock                                                
     0.16%     0.00%  main.exe  libc.so.6  [.] ___pthread_cond_signal (inlined)                                    
     0.16%     0.16%  main.exe  libc.so.6  [.] pthread_cond_signal                                                 
     0.14%     0.14%  main.exe  main.exe   [.] pthread_mutex_unlock@plt                                            
     0.13%     0.13%  main.exe  main.exe   [.] pthread_mutex_lock@plt                                              
     0.07%     0.00%  main.exe  main.exe   [.] thread_config (inlined)                                             
     0.07%     0.07%  main.exe  main.exe   [.] pthread_mutex_trylock@plt                                           
     0.07%     0.00%  main.exe  main.exe   [.] thread_lock_release (inlined)                                       
     0.06%     0.06%  main.exe  main.exe   [.] pthread_getspecific@plt                                             
     0.01%     0.00%  main.exe  main.exe   [.] backup_thread_running (inlined)                                     
     0.01%     0.01%  main.exe  main.exe   [.] pthread_cond_signal@plt      

     ----------------------------------------------------------------------------------------------------------------

     2 +    1.45%     0.00%  main.exe  main.exe  [.] Dscroll.run_4233 (inlined)
+    1.03%     0.00%  main.exe  main.exe  [.] Dscroll.loop_4255 (inlined)
+    0.95%     0.83%  main.exe  main.exe  [.] Dscroll.loop_4262
+    0.58%     0.58%  main.exe  main.exe  [.] Dscroll.next_4258
     0.43%     0.00%  main.exe  main.exe  [.] Dscroll.data_end+0x1dc
     0.19%     0.00%  main.exe  main.exe  [.] Dscroll.run_4233 (inlined)
     0.05%     0.00%  main.exe  main.exe  [.] Dscroll.45
     0.01%     0.00%  main.exe  main.exe  [.] Dscroll.43

     +    1.21%     0.98%  main.exe  main.exe  [.] caml_call_gc
     0.23%     0.23%  main.exe  main.exe  [.] caml_poll_gc_work
     0.10%     0.00%  main.exe  main.exe  [.] entry_update_after_minor_gc (inlined)
     0.05%     0.05%  main.exe  main.exe  [.] caml_handle_gc_interrupt
     0.04%     0.00%  main.exe  main.exe  [.] caml_request_minor_gc (inlined)
     0.01%     0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)
     0.00%     0.00%  main.exe  main.exe  [.] caml_adjust_minor_gc_speed (inlined)

          0.38%     0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_domains (inlined)
     0.12%     0.00%  main.exe  main.exe  [.] stw_resize_minor_heap_reservation (inlined)
     0.10%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once (inlined)
     0.09%     0.00%  main.exe  main.exe  [.] domain_resize_heap_reservation_from_stw_single (inlined)
     0.06%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_no_major_slice_from_stw (inlined)
     0.06%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_setup (inlined)
     0.02%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_no_major_slice_from_stw (inlined)
     0.02%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_setup (inlined)
     0.02%     0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_slice (inlined)
     0.02%     0.00%  main.exe  main.exe  [.] unreserve_minor_heaps_from_stw_single (inlined)
     0.01%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inlined)
     0.00%     0.00%  main.exe  main.exe  [.] caml_adopt_all_orphan_heaps (inlined)
     0.00%     0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_slice.isra.0
     0.00%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_domain_clear (inlined)

     +    1.20%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)           
     1.18%     1.18%  main.exe  libc.so.6  [.] pthread_mutex_lock                        
+    1.08%     0.29%  main.exe  main.exe   [.] caml_thread_leave_blocking_section        
+    0.80%     0.00%  main.exe  main.exe   [.] thread_lock_acquire (inlined)             
+    0.77%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_trylock (inlined)        
     0.75%     0.75%  main.exe  libc.so.6  [.] pthread_mutex_trylock                     
+    0.72%     0.00%  main.exe  main.exe   [.] thread_yield (inlined)                    
+    0.61%     0.00%  main.exe  main.exe   [.] thread_yield (inlined)                    
+    0.57%     0.00%  main.exe  libc.so.6  [.] ___pthread_getspecific (inlined)          
+    0.56%     0.00%  main.exe  main.exe   [.] st_thread_yield (inlined)                 
     0.56%     0.56%  main.exe  libc.so.6  [.] pthread_getspecific                       
+    0.54%     0.00%  main.exe  main.exe   [.] st_thread_yield (inlined)                 
     0.37%     0.00%  main.exe  main.exe   [.] pthread_np_getaffinity_self (inlined)     
     0.29%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_unlock (inlined)         
     0.28%     0.28%  main.exe  libc.so.6  [.] pthread_mutex_unlock                      
     0.24%     0.24%  main.exe  main.exe   [.] caml_memprof_enter_thread                 
     0.19%     0.00%  main.exe  libc.so.6  [.] ___pthread_cond_signal (inlined)          
     0.18%     0.18%  main.exe  libc.so.6  [.] pthread_cond_signal                       
     0.16%     0.16%  main.exe  main.exe   [.] caml_thread_enter_blocking_section        
     0.13%     0.13%  main.exe  main.exe   [.] pthread_mutex_unlock@plt                  
     0.12%     0.00%  main.exe  main.exe   [.] caml_memprof_new_thread (inlined)         
     0.10%     0.10%  main.exe  main.exe   [.] pthread_mutex_lock@plt                    
     0.09%     0.09%  main.exe  main.exe   [.] pthread_getspecific@plt                   
     0.09%     0.08%  main.exe  main.exe   [.] pthread_mutex_trylock@plt                 
     0.08%     0.00%  main.exe  main.exe   [.] caml_threadstatus_compare (inlined)       
     0.03%     0.03%  main.exe  main.exe   [.] pthread_cond_signal@plt                   
     0.02%     0.00%  main.exe  main.exe   [.] thread_create (inlined)                   
     0.02%     0.00%  main.exe  main.exe   [.] thread_lock_release (inlined)             
     0.02%     0.00%  main.exe  main.exe   [.] backup_thread_running (inlined)           
     0.02%     0.00%  main.exe  main.exe   [.] backup_thread_running (inlined)           
     0.01%     0.00%  main.exe  main.exe   [.] pthread_equal (inlined)                   
     0.01%     0.00%  main.exe  main.exe   [.] caml_thread_leave_blocking_section (inlined)    
     0.00%     0.00%  main.exe  main.exe   [.] backup_thread_running (inlined)           
     0.00%     0.00%  main.exe  main.exe   [.] pthread_cond_init@plt                     
     0.00%     0.00%  main.exe  main.exe   [.] thread_alloc_and_add (inlined)     *)

(* -------------------------------------------------------------------------------------------- *)

(* 3 +    0.92%     0.92%  main.exe  main.exe  [.] Dscroll.loop_4613
     0.44%     0.44%  main.exe  main.exe  [.] Dscroll.getframe_4606 *)

(* +    2.72%     1.09%  main.exe  main.exe  [.] caml_call_gc
     0.27%     0.27%  main.exe  main.exe  [.] caml_poll_gc_work
     0.10%     0.00%  main.exe  main.exe  [.] classify_gc_root (inlined)
     0.08%     0.00%  main.exe  main.exe  [.] caml_check_gc_interrupt (inlined)
     0.05%     0.05%  main.exe  main.exe  [.] caml_handle_gc_interrupt *)

(* 0.03%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heaps_once
     0.03%     0.00%  main.exe  main.exe  [.] caml_try_empty_minor_heap_on_all_domains (inlined)
     0.03%     0.00%  main.exe  main.exe  [.] caml_stw_empty_minor_heap_no_major_slice (inlined)
     0.03%     0.00%  main.exe  main.exe  [.] caml_empty_minor_heap_promote (inlined) *)

(* +    1.10%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)  
+    1.09%     1.09%  main.exe  libc.so.6  [.] pthread_mutex_lock                
+    0.83%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_trylock (inlined)
+    0.81%     0.81%  main.exe  libc.so.6  [.] pthread_mutex_trylock             
     0.68%     0.31%  main.exe  main.exe   [.] caml_memprof_enter_thread         
+    0.54%     0.00%  main.exe  libc.so.6  [.] ___pthread_getspecific (inlined)  
+    0.53%     0.53%  main.exe  libc.so.6  [.] pthread_getspecific               
     0.24%     0.24%  main.exe  main.exe   [.] caml_thread_leave_blocking_section
     0.24%     0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_unlock (inlined) 
     0.24%     0.24%  main.exe  libc.so.6  [.] pthread_mutex_unlock              
     0.19%     0.00%  main.exe  libc.so.6  [.] ___pthread_cond_signal (inlined)  
     0.18%     0.18%  main.exe  libc.so.6  [.] pthread_cond_signal               
     0.16%     0.16%  main.exe  main.exe   [.] pthread_mutex_unlock@plt          
     0.14%     0.14%  main.exe  main.exe   [.] pthread_mutex_lock@plt            
     0.13%     0.13%  main.exe  main.exe   [.] caml_thread_enter_blocking_section
     0.11%     0.11%  main.exe  main.exe   [.] pthread_mutex_trylock@plt         
     0.07%     0.07%  main.exe  main.exe   [.] pthread_getspecific@plt           
     0.06%     0.00%  main.exe  main.exe   [.] thread_config (inlined)           
     0.02%     0.02%  main.exe  main.exe   [.] pthread_cond_signal@plt   *)

(* 1
     +   91.62%     0.51%  main.exe  main.exe              [.] caml_c_call      
+   89.35%     0.63%  main.exe  main.exe              [.] caml_ml_flush    
+   88.13%     0.60%  main.exe  main.exe              [.] flush_partial    
+   87.58%     0.54%  main.exe  main.exe              [.] caml_write_fd    
+  80.52%     0.00%  main.exe  libc.so.6    [.] __libc_write (inlined)   
+   79.71%     0.00%  main.exe  libc.so.6    [.] 0x00007fa1b7294ade       
+   79.60%     0.00%  main.exe  libc.so.6    [.] 0x00007fa1b7294b03       
+   79.30%    79.30%  main.exe  [unknown]    [k] 0xffffffff8d4001c8       
+    4.94%   0.34%  main.exe  main.exe  [.] caml_leave_blocking_section       
+    3.30%     1.05%  main.exe  main.exe    [.] Dscroll.loop_4255  *)

(* 2
+   80.30%     0.00%  main.exe  main.exe   [.] caml_sys_isatty (inlined)      
+   79.83%     0.00%  main.exe  libc.so.6  [.] __libc_write (inlined)    
+   79.04%     0.00%  main.exe  libc.so.6  [.] 0x00007f98bce94ade        
+   78.93%     0.00%  main.exe  libc.so.6  [.] 0x00007f98bce94b03        
+   78.62%    78.62%  main.exe  [unknown]  [k] 0xffffffff8d4001c8        
+    2.76%     0.75%  main.exe  main.exe   [.] caml_c_call    
+    2.10%     0.00%  main.exe  [unknown]  [.] 0x0000000000000011        
+    2.02%     1.10%  main.exe  main.exe   [.] caml_ml_output_bytes      
+    1.45%     0.00%  main.exe  main.exe   [.] Dscroll.run_4233 (inlined)
+  1.44%  0.00%  main.exe  main.exe   [.] Base.Exn.print_with_backtrace_2106 (inlined)        
+    1.40%     0.00%  main.exe  main.exe   [.] Stdlib.38      
+    1.22%     0.54%  main.exe  main.exe   [.] caml_write_fd  
+    1.21%     0.98%  main.exe  main.exe   [.] caml_call_gc   
+    1.20%   0.00%  main.exe  libc.so.6  [.] ___pthread_mutex_lock (inlined)   
     1.18%     1.18%  main.exe  libc.so.6  [.] pthread_mutex_lock        
+    1.08%  0.29%  main.exe  main.exe   [.] caml_thread_leave_blocking_section 
+    1.03%     0.00%  main.exe  main.exe   [.] Dscroll.loop_4255 (inlined) ▒
+    0.95%     0.83%  main.exe  main.exe   [.] Dscroll.loop_4262   *)

(* 3
+   90.55%     0.53%  main.exe  main.exe    [.] caml_c_call   
+   88.25%     0.64%  main.exe  main.exe    [.] caml_ml_flush     
+   86.98%     0.56%  main.exe  main.exe    [.] flush_partial     
+   86.44%     0.51%  main.exe  main.exe    [.] caml_write_fd     
+   80.19%     0.00%  main.exe  libc.so.6   [.] __libc_write (inlined)  ▒
+   79.34%     0.00%  main.exe  libc.so.6   [.] 0x00007efd0c094ade
+   79.22%     0.00%  main.exe  libc.so.6   [.] 0x00007efd0c094b03
+   78.91%    78.91%  main.exe  [unknown]   [k] 0xffffffff8d4001c8
+   4.50%   0.37%  main.exe  main.exe    [.] caml_leave_blocking_section    
+    4.33%   0.00%  main.exe  main.exe    [.] Time_float_unix.entry (inlined) 
+    4.29%     0.00%  main.exe  main.exe    [.] Time_float_unix.Time_functor.Make_31526 (inlined)     
+    4.28%     0.00%  main.exe  main.exe    [.] caml_start_program
+    4.27%   0.00%  main.exe  main.exe    [.] Time_float_unix.entry (inlined)  
+    4.27%   0.00%  main.exe  main.exe    [.] Base.Info.to_exn_2236 (inlined)  
+    4.27%     0.00%  main.exe  main.exe    [.] Int_repr.entry (inlined)▒
+    4.27%   0.00%  main.exe  main.exe    [.] Time_float_unix.entry (inlined)  
+    2.72%     1.09%  main.exe  main.exe    [.] caml_call_gc    *)

(* current:
                 0      context-switches:u               #      0.0 cs/sec  cs_per_second     
                 0      cpu-migrations:u                 #      0.0 migrations/sec  migrations_per_second
             1,795      page-faults:u                    #    912.7 faults/sec  page_faults_per_second
          1,966.59 msec task-clock:u                     #      1.0 CPUs  CPUs_utilized       
           446,686      L1-dcache-load-misses:u          #      0.1 %  l1d_miss_rate            (37.41%)
           167,693      LLC-loads:u                      #     47.5 %  llc_miss_rate            (12.50%)
           553,592      branch-misses:u                  #      0.1 %  branch_miss_rate         (25.06%)
       494,863,431      branches:u                       #    251.6 M/sec  branch_frequency     (25.05%)
     1,150,665,768      cpu-cycles:u                     #      0.6 GHz  cycles_frequency       (37.57%)
     2,083,282,237      instructions:u                   #      1.8 instructions  insn_per_cycle  (50.07%)

       1.969750350 seconds time elapsed

       1.478514000 seconds user
       0.463912000 seconds sys *)

(* mid:
                     0      context-switches:u               #      0.0 cs/sec  cs_per_second     
                 0      cpu-migrations:u                 #      0.0 migrations/sec  migrations_per_second
             1,808      page-faults:u                    #    918.8 faults/sec  page_faults_per_second
          1,967.68 msec task-clock:u                     #      1.0 CPUs  CPUs_utilized       
         1,245,504      L1-dcache-load-misses:u          #      0.2 %  l1d_miss_rate            (37.43%)
           263,386      LLC-loads:u                      #     62.8 %  llc_miss_rate            (12.50%)
           579,363      branch-misses:u                  #      0.1 %  branch_miss_rate         (25.06%)
       505,331,822      branches:u                       #    256.8 M/sec  branch_frequency     (25.06%)
     1,160,350,661      cpu-cycles:u                     #      0.6 GHz  cycles_frequency       (37.57%)
     2,159,554,874      instructions:u                   #      1.8 instructions  insn_per_cycle  (50.07%)

       1.970287935 seconds time elapsed

       1.494401000 seconds user
       0.447636000 seconds sys *)

(* old:
                    0      context-switches:u               #      0.0 cs/sec  cs_per_second     
                 0      cpu-migrations:u                 #      0.0 migrations/sec  migrations_per_second
             1,810      page-faults:u                    #    921.5 faults/sec  page_faults_per_second
          1,964.28 msec task-clock:u                     #      1.0 CPUs  CPUs_utilized       
           310,298      L1-dcache-load-misses:u          #      0.0 %  l1d_miss_rate            (37.40%)
           203,991      LLC-loads:u                      #     58.5 %  llc_miss_rate            (12.54%)
         1,183,354      branch-misses:u                  #      0.2 %  branch_miss_rate         (25.07%)
       515,703,652      branches:u                       #    262.5 M/sec  branch_frequency     (25.07%)
     1,153,801,353      cpu-cycles:u                     #      0.6 GHz  cycles_frequency       (37.58%)
     2,169,854,888      instructions:u                   #      1.9 instructions  insn_per_cycle  (50.05%)

       1.966666781 seconds time elapsed

       1.487327000 seconds user
       0.454583000 seconds sys *)

(* let dump msg =
  let s = Gc.quick_stat () in
  Printf.printf "%s: minor=%.0f promoted=%.0f major=%.0f\n" msg s.minor_words
    s.promoted_words s.major_words *)
