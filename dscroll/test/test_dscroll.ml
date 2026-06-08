QCheck_base_runner.run_tests_main
  [
    (* QCheck2.(
      Test.make ~count:1_000_000 ~name:"gnol"
        ~print:Print.(quad string int int int)
        Gen.(
          quad
            (string_size_of (int_range 1 150) printable)
            (int_range 1 130) (int_range 2 350) (int_range 0 740))
        (fun (text, ecl, wid, frm) ->
          assume
            (text
            = Core.String.filter text ~f:(fun s ->
                not (Core.Char.is_whitespace s)));
          let open Core in
          let ft =
            Dscroll.getfinaltext text ' ' ecl wid Dscroll.Direction.Left
          in
          let ftlen = String.length ft / 2 in
          let res = Dscroll.getnextoutput ft (frm % ftlen) wid in
          String.length res = wid
          && String.equal
               (Dscroll.tloop
                  (String.sub ft ~pos:0 ~len:ftlen)
                  ftlen (frm % ftlen) wid Dscroll.Direction.Left)
               res
          && wid - String.count res ~f:Char.is_whitespace >= 1)); *)
    (* QCheck2.(
      Test.make ~count:1_000_000 ~name:"gnor"
        ~print:Print.(quad string int int int)
        Gen.(
          quad
            (string_size_of (int_range 1 150) printable)
            (int_range 1 130) (int_range 2 350) (int_range 0 740))
        (fun (text, ecl, wid, frm) ->
          assume
            (text
            = Core.String.filter text ~f:(fun s ->
                not (Core.Char.is_whitespace s)));
          let open Core in
          let ft =
            Dscroll.getfinaltext text ' ' ecl wid Dscroll.Direction.Right
          in
          let ftlen = String.length ft / 2 in
          let res =
            Dscroll.getnextoutput ft ((ftlen * 2) - wid - (frm % ftlen)) wid
          in
          String.length res = wid
          && String.equal
               (Dscroll.tloop
                  (String.sub ft ~pos:0 ~len:ftlen)
                  ftlen (frm % ftlen) wid Dscroll.Direction.Right)
               res
          && wid - String.count res ~f:Char.is_whitespace >= 1)); *)
    (* QCheck2.(
      Test.make ~count:1000 ~name:"nonnegint1"
        ~print:Print.(pair int int)
        ~collect:(fun (min, n) ->
          match (min < 3, n < 10) with
          | true, true -> "both small"
          | true, false -> "small min, large n"
          | false, true -> "large min, small n"
          | false, false -> "both large")
        ~stats:[ ("min", fun (min, n) -> min); ("n", fun (min, n) -> n) ]
        Gen.(pair (Gen.int_bound 2) (Gen.int_bound 2000))
        (fun (min, n) ->
          let numstr = string_of_int n in
          let res = Dscroll.Ints.getint ~min numstr in
          res >= min && res >= n && res >= 0));
    QCheck2.(
      Test.make ~count:1000 ~name:"nonnegint2"
        ~print:Print.(string)
        Gen.(string_small_of printable)
        (fun s ->
          assume (int_of_string_opt s = None);
          try
            let _ = Dscroll.Ints.getint ~min:0 s in
            false
          with
          | Invalid_argument _ -> true
          | _ -> false));
    QCheck2.(
      Test.make ~count:1000 ~name:"nonnegint3"
        ~print:Print.(pair int string)
        Gen.(pair int_neg string)
        (fun (min, n) ->
          try
            let _ = Dscroll.Ints.getint ~min n in
            false
          with
          | Invalid_argument _ -> true
          | _ -> false)); *)
    QCheck2.(
      Test.make ~count:1_000_000 ~name:"gftl"
        ~print:Print.(triple string int int)
        Gen.(
          triple
            (string_size_of (int_range 1 100) printable)
            (int_range 1 100) (int_range 2 250))
        (fun (text, ecl, wid) ->
          assume
            (text
            = Core.String.filter text ~f:(fun s ->
                not (Core.Char.is_whitespace s)));
          let open Core in
          let res =
            Dscroll.getfinaltext text ' ' ecl wid Dscroll.Direction.Left
          in
          let reslen = String.length res / 2 in
          let padlen = reslen - String.length text in
          String.is_suffix res ~suffix:" "
          && reslen >= wid && padlen < wid && padlen > 0));
    QCheck2.(
      Test.make ~count:1_000_000 ~name:"gftr"
        ~print:Print.(triple string int int)
        Gen.(
          triple
            (string_size_of (int_range 1 100) printable)
            (int_range 1 100) (int_range 2 250))
        (fun (text, ecl, wid) ->
          assume
            (text
            = Core.String.filter text ~f:(fun s ->
                not (Core.Char.is_whitespace s)));
          let open Core in
          let res =
            Dscroll.getfinaltext text ' ' ecl wid Dscroll.Direction.Right
          in
          let reslen = String.length res / 2 in
          let padlen = reslen - String.length text in
          String.is_prefix res ~prefix:" "
          && reslen >= wid && padlen < wid && padlen > 0));
    QCheck2.(
      Test.make ~count:1_000_000 ~name:"gftb"
        ~print:Print.(triple string int int)
        Gen.(
          triple
            (string_size_of (int_range 1 100) printable)
            (int_range 1 100) (int_range 2 250))
        (fun (text, ecl, wid) ->
          assume
            (text
            = Core.String.filter text ~f:(fun s ->
                not (Core.Char.is_whitespace s)));
          let open Core in
          let res =
            Dscroll.getfinaltext text ' ' ecl wid Dscroll.Direction.Bounce
          in
          let padlen = (String.length res - String.length text) / 2 in
          let reslen = padlen + String.length text in
          match padlen = 0 with
          | false ->
              String.is_prefix res ~prefix:" "
              && String.is_suffix res ~suffix:" "
              && reslen = wid && padlen < wid && padlen > 0
          | true -> (
              (not (String.is_prefix res ~prefix:" "))
              && (not (String.is_suffix res ~suffix:" "))
              &&
              match String.length text = wid with
              | true -> reslen = wid
              | false -> reslen > wid)));
  ]
