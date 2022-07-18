open Lib_mcs

let () =
  Stdio.print_endline "Hello! Please send me messages";
  Multi_client_server.run ()
