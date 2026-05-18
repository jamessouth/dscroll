(* open Core *)

QCheck_base_runner.run_tests_main
  [
    QCheck2.(
      Test.make ~count:1000 ~name:"nonnegint1"
        ~print:Print.(pair int int)
        ~collect:(fun (min, n) ->
          match (min < 10, n < 10) with
          | true, true -> "both small"
          | true, false -> "small min, large n"
          | false, true -> "large min, small n"
          | false, false -> "both large")
        ~stats:[ ("min min", fun (min, n) -> min) ]
        Gen.(pair nat int)
        (fun (min, n) ->
          let numstr = string_of_int n in
          let res = Dscroll.nonnegint ~min numstr in
          res >= min && res >= n && res >= 0));
  ]

(* 1. Valid Test: Generates ONLY non-negative mins (using Gen.nat) *)
(* let test_valid_inputs =
  QCheck2.Test.make ~count:1000 ~name:"nonnegint_valid_inputs"
    (* Gen.nat produces only integers >= 0 *)
    QCheck2.Gen.(pair nat int) 
    (fun (min, n) ->
       let num_str = string_of_int n in
       let result = My_lib.nonnegint ~min num_str in
       result >= min && result >= n)

(* 2. Invalid String Test: Keep this the same, but pass a valid min (0) *)
let test_invalid_string =
  QCheck2.Test.make ~count:1000 ~name:"nonnegint_invalid_string"
    QCheck2.Gen.(string)
    (fun s ->
       QCheck2.assume (int_of_string_opt s = None);
       try
         let _ = My_lib.nonnegint ~min:0 s in
         false
       with

       | Invalid_argument "not an int" -> true
       | _ -> false)

(* 3. NEW Test: Explicitly checks that negative min values trigger the crash *)
let test_invalid_min =
  QCheck2.Test.make ~count:1000 ~name:"nonnegint_invalid_min"
    (* Pair a strictly negative integer with any random string *)
    QCheck2.Gen.(pair (neg_int) string)
    (fun (invalid_min, any_str) ->
       try
         let _ = My_lib.nonnegint ~min:invalid_min any_str in
         false (* Fails if it accidentally accepts a negative min *)
       with

       | Invalid_argument "min must be >= 0" -> true
       | _ -> false (* Fails if it returns "not an int" first *))

(* Standalone runner entry point *)
let () =
  exit (QCheck_base_runner.run_tests_main [
      test_valid_inputs;
      test_invalid_string;
      test_invalid_min;
    ]) *)
