open Core

let command =
  Command.basic ~summary:"Generate an MD5 hash of the input data"
    ~readme:(fun () -> "More detailed information")
    (let%map_open.Command text = anon ("text" %: string)
     and length =
       flag_optional_with_default_doc "--length" int
         (fun x -> Int.sexp_of_t x)
         ~default:15 ~doc:"int width"
     in
     fun () -> do_hash hash_length filename)

let () = Command_unix.run ~version:"1.0" ~build_info:"RWO" command
