open Core
open Dscroll

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
    flag_optional_with_default_doc "--endcap-char" ~aliases:[ "-ecc" ] char
      (fun x -> Char.sexp_of_t x)
      ~default:' ' ~doc:"char pad between end and start of TEXT"
  and endcap_len =
    flag_optional_with_default_doc "--endcap-len" ~aliases:[ "-ecl" ]
      Ints.posint
      (fun x -> Int.sexp_of_t x)
      ~default:1 ~doc:"int minimum length of endcap"
  and no_newline =
    flag "--no-newline" ~aliases:[ "-nnl" ] no_arg
      ~doc:" do not add newline to output"
  and prefix =
    flag_optional_with_default_doc "--prefix" ~aliases:[ "-p" ] string
      (fun x -> String.sexp_of_t x)
      ~default:"" ~doc:"string prefix at left of display"
  and speed =
    flag_optional_with_default_doc "--speed" ~aliases:[ "-sp" ] Ints.posint
      (fun x -> Int.sexp_of_t x)
      ~default:300 ~doc:"int sleep in ms per scroll of TEXT"
  and suffix =
    flag_optional_with_default_doc "--suffix" ~aliases:[ "-s" ] string
      (fun x -> String.sexp_of_t x)
      ~default:"" ~doc:"string suffix at right of display"
  and width =
    flag_optional_with_default_doc "--width" ~aliases:[ "-w" ] Ints.posint
      (fun x -> Int.sexp_of_t x)
      ~default:15 ~doc:"int display width"
  in
  {
    cycles;
    direction;
    endcap_char;
    endcap_len;
    no_newline;
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
