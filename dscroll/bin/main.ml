open Core

(* The only zeroless pandigital number where the first n digits are divisible by n, used as 'infinity' *)
let quasi_inf = 381_654_729

let direction =
  Command.Arg_type.create (fun dir ->
      match dir with
      | "left" | "right" | "bounce" -> dir
      | _ ->
          failwith "invalid direction - must be one of left, right, or bounce")

let nonnegint ~min num =
  match num |> int_of_string_opt with
  | Some n -> Int.max min n
  | None -> failwith "not an int"

let cyc = Command.Arg_type.create (nonnegint ~min:0)
let ecl = Command.Arg_type.create (nonnegint ~min:1)
let spd = Command.Arg_type.create (nonnegint ~min:1)
let wid = Command.Arg_type.create (nonnegint ~min:1)

let flags : Dscroll.cliflags Command.Param.t =
  let%map_open.Command cycles =
    flag_optional_with_default_doc "--cycles" ~aliases:[ "-c" ] cyc
      (fun x -> Int.sexp_of_t x)
      ~default:quasi_inf ~doc:"int number of scroll cycles"
  and direction =
    flag_optional_with_default_doc "--direction" ~aliases:[ "-d" ] direction
      (fun x -> String.sexp_of_t x)
      ~default:"left" ~doc:"string left, right, or bounce"
  and endcap_char =
    flag_optional_with_default_doc "--endcap-char" ~aliases:[ "-ecc" ] char
      (fun x -> Char.sexp_of_t x)
      ~default:' ' ~doc:"char pad between end and start of TEXT"
  and endcap_len =
    flag_optional_with_default_doc "--endcap-len" ~aliases:[ "-ecl" ] ecl
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
    flag_optional_with_default_doc "--speed" ~aliases:[ "-sp" ] spd
      (fun x -> Int.sexp_of_t x)
      ~default:300 ~doc:"int sleep in ms per scroll of TEXT"
  and suffix =
    flag_optional_with_default_doc "--suffix" ~aliases:[ "-s" ] string
      (fun x -> String.sexp_of_t x)
      ~default:"" ~doc:"string suffix at right of display"
  and width =
    flag_optional_with_default_doc "--width" ~aliases:[ "-w" ] wid
      (fun x -> Int.sexp_of_t x)
      ~default:15 ~doc:"int display width"
  in
  {
    Dscroll.cycles;
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
        fun () -> Dscroll.run text flags))
