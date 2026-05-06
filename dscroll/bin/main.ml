open Core

let direction =
  Command.Arg_type.create (fun dir ->
      match dir with
      | "l" | "r" | "b" -> dir
      | _ -> failwith "invalid direction")

let command =
  Command.basic ~summary:"Generate an MD5 hash of the input data"
    ~readme:(fun () -> "More detailed information")
    (let%map_open.Command text =
       anon (non_empty_sequence_as_list ("text" %: string))
     and length =
       flag_optional_with_default_doc "-length" int
         (fun x -> Int.sexp_of_t x)
         ~default:15 ~doc:"int width"
     and direction =
       flag_optional_with_default_doc "-direction" direction
         (fun x -> String.sexp_of_t x)
         ~default:"l" ~doc:"direction"
     in
     fun () -> Dscroll.run text length direction)

let () = Command_unix.run ~version:"1.0" ~build_info:"RWO" command
