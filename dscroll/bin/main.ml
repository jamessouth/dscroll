open Core

let direction =
  Command.Arg_type.create (fun dir ->
      match dir with
      | "left" | "right" | "bounce" -> dir
      | _ ->
          failwith "invalid direction - must be one of left, right, or bounce")

let nonnegint ~msg ~min num =
  match num |> int_of_string_opt with
  | Some n -> (
      match n with
      | n when n >= min -> n
      | _ ->
          failwith
            ("invalid " ^ msg ^ " - must be an int >= " ^ string_of_int min))
  | None -> failwith "not an int"

let cycles = Command.Arg_type.create (nonnegint ~msg:"cycles" ~min:0)

let ecl =
  Command.Arg_type.create (nonnegint ~msg:"minimum endcap length" ~min:1)

let speed = Command.Arg_type.create (nonnegint ~msg:"speed" ~min:1)
let width = Command.Arg_type.create (nonnegint ~msg:"width" ~min:1)

let command =
  Command.basic ~summary:"Generate an MD5 hash of the input data"
    ~readme:(fun () -> "More detailed information")
    (let%map_open.Command text =
       anon (non_empty_sequence_as_list ("text" %: string))
     and cycles =
       flag_optional_with_default_doc "--cycles" ~aliases:[ "-c" ] cycles
         (fun x -> Int.sexp_of_t x)
         ~default:Int.max_value ~doc:"int # of scroll cycles"
     and direction =
       flag_optional_with_default_doc "--direction" ~aliases:[ "-d" ] direction
         (fun x -> String.sexp_of_t x)
         ~default:"left" ~doc:"string left, right, or bounce"
     and endcap_char =
       flag_optional_with_default_doc "--endcap-char" ~aliases:[ "-ec" ] char
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
     and sleep =
       flag_optional_with_default_doc "--speed" ~aliases:[ "-sp" ] speed
         (fun x -> Int.sexp_of_t x)
         ~default:300 ~doc:"int sleep in ms per scroll of TEXT"
     and suffix =
       flag_optional_with_default_doc "--suffix" ~aliases:[ "-s" ] string
         (fun x -> String.sexp_of_t x)
         ~default:"" ~doc:"string suffix at right of display"
     and width =
       flag_optional_with_default_doc "--width" ~aliases:[ "-w" ] width
         (fun x -> Int.sexp_of_t x)
         ~default:15 ~doc:"int display width"
     in
     fun () ->
       Dscroll.run text width direction prefix suffix endcap_char endcap_len
         sleep no_newline)

let () = Command_unix.run ~version:"1.0" ~build_info:"RWO" command
