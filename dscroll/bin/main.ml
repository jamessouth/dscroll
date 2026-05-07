open Core

let direction =
  Command.Arg_type.create (fun dir ->
      match dir with
      | "left" | "right" | "bounce" -> dir
      | _ -> failwith "invalid direction")

let sleep =
  Command.Arg_type.create (fun time ->
      let mils = time |> int_of_string_opt in
      match mils with
      | Some t -> (
          match t with t when t > 0 -> t | _ -> failwith "invalid sleep value")
      | None -> failwith "not an int")

let command =
  Command.basic ~summary:"Generate an MD5 hash of the input data"
    ~readme:(fun () -> "More detailed information")
    (let%map_open.Command text =
       anon (non_empty_sequence_as_list ("text" %: string))
     and width =
       flag_optional_with_default_doc "--width" ~aliases:[ "-w" ] int
         (fun x -> Int.sexp_of_t x)
         ~default:15 ~doc:"int display width"
     and direction =
       flag_optional_with_default_doc "--direction" ~aliases:[ "-d" ] direction
         (fun x -> String.sexp_of_t x)
         ~default:"left" ~doc:"string left, right, or bounce"
     and prefix =
       flag_optional_with_default_doc "--prefix" ~aliases:[ "-p" ] string
         (fun x -> String.sexp_of_t x)
         ~default:"" ~doc:"string prefix at left of display"
     and suffix =
       flag_optional_with_default_doc "--suffix" ~aliases:[ "-s" ] string
         (fun x -> String.sexp_of_t x)
         ~default:"" ~doc:"string suffix at right of display"
     and endcap =
       flag_optional_with_default_doc "--endcap" ~aliases:[ "-e" ] string
         (fun x -> String.sexp_of_t x)
         ~default:" " ~doc:"string pad between end and start of TEXT"
     and sleep =
       flag_optional_with_default_doc "--sleep" ~aliases:[ "-sl" ] sleep
         (fun x -> Int.sexp_of_t x)
         ~default:300 ~doc:"int sleep in ms per scroll of TEXT"
     in
     fun () -> Dscroll.run text width direction prefix suffix endcap sleep)

let () = Command_unix.run ~version:"1.0" ~build_info:"RWO" command

(*Time_unix.pause*)
