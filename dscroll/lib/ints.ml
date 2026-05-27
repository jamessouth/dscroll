open Core

(* The only zeroless pandigital number where the first n digits are divisible by n, used as 'infinity' *)
let quasi_inf = 381_654_729

let getint ~min num =
  if min |> Int.is_negative then invalid_arg "min must be >= 0"
  else
    match num |> int_of_string_opt with
    | Some n -> Int.max min n
    | None -> invalid_arg "not an int"

let nonneg = Command.Arg_type.create (getint ~min:0)
let oneplus = Command.Arg_type.create (getint ~min:1)
let twoplus = Command.Arg_type.create (getint ~min:2)
