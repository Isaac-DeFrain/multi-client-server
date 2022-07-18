(** Multi-client server example. Clients can get/set/del values in a shared
    ledger. *)

open! Core
open! Lwt
open! Hashtbl
open! Lwt.Syntax

(* shared ledger *)
let ledger = create (module Int)

let listen_address = UnixLabels.inet_addr_loopback

let port = 9000

let backlog = 10

type msg =
  | Id
  | Empty
  | Num_conn
  | Get of int
  | Set of int * string
  | Del of int
  | Malformed of string

let display_msg =
  "  #       - number of server's connections\n\
  \  id      - your connection id\n\
  \  get i   - get value at key i\n\
  \  set i v - set key i's value to v\n\
  \  del i   - delete value at key i"

let try_get k l =
  let b = ref true in
  let i =
    try
      b := true;
      int_of_string k
    with Failure _ ->
      b := false;
      0
  in
  if !b then Get i else Malformed (String.concat ~sep:" " l)

let try_set k v l =
  let b = ref true in
  let i =
    try
      b := true;
      int_of_string k
    with Failure _ ->
      b := false;
      0
  in
  if !b then Set (i, v) else Malformed (String.concat ~sep:" " l)

let try_del k l =
  let b = ref true in
  let i =
    try
      b := true;
      int_of_string k
    with Failure _ ->
      b := false;
      0
  in
  if !b then Del i else Malformed (String.concat ~sep:" " l)

let parse = function
  | [] -> Empty
  | [ "#" ] -> Num_conn
  | [ "id" ] -> Id
  | "get" :: [ k ] as l -> try_get k l
  | "set" :: [ k; v ] as l -> try_set k v l
  | "del" :: [ k ] as l -> try_del k l
  | l -> Malformed (String.concat ~sep:" " l)

let handle_message id = function
  | Get k -> (
    if k = -1 then Printf.sprintf "invalid key to get - try another"
    else
      match find ledger k with
      | Some v -> v
      | None -> Printf.sprintf "%d not found" k)
  | Set (key, data) -> (
    if key = -1 then Printf.sprintf "invalid key to set - try another"
    else
      match add ledger ~key ~data with
      | `Ok -> Printf.sprintf "%d has been set to %s" key data
      | `Duplicate ->
        let old = find_exn ledger key in
        remove ledger key;
        add_exn ledger ~key ~data;
        Printf.sprintf "%d has been reset from %s to %s" key old data)
  | Del k ->
    if k = -1 then Printf.sprintf "invalid key to delete - try another"
    else (
      remove ledger k;
      Printf.sprintf "%d has been deleted" k)
  | Num_conn ->
    let n = int_of_string @@ find_exn ledger (-1) in
    Printf.sprintf "there are currently %d connections" n
  | Id -> Printf.sprintf "%d" id
  | Empty -> ""
  | Malformed s ->
    Printf.sprintf "%s is a malformed command\nvalid commands:\n%s" s
      display_msg

let decr_conn_count () =
  match find ledger (-1) with
  | None -> ()
  | Some sn ->
    let n = int_of_string sn in
    remove ledger (-1);
    add_exn ledger ~key:(-1) ~data:(string_of_int @@ (n - 1))

let rec handle_connection id ic oc () =
  Lwt_io.read_line_opt ic >>= function
  | Some msg ->
    let split =
      Str.split (Str.regexp "[ ]+") msg |> List.map ~f:String.lowercase
    in
    let reply = handle_message id @@ parse split in
    let msg = String.concat ~sep:" " split in
    let* _ = Logs_lwt.info (fun m -> m "New message from %d: %s" id msg) in
    Lwt_io.write_line oc reply >>= handle_connection id ic oc
  | None ->
    decr_conn_count ();
    Logs_lwt.info (fun m -> m "Connection %d closed" id) >>= return

let incr_conn_count () =
  match find ledger (-1) with
  | None -> add_exn ledger ~key:(-1) ~data:"1"
  | Some sn ->
    let n = int_of_string sn in
    remove ledger (-1);
    add_exn ledger ~key:(-1) ~data:(string_of_int @@ (n + 1))

let accept_connection id conn =
  incr_conn_count ();
  let fd, _ = conn in
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input fd in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output fd in
  Lwt.on_failure (handle_connection id ic oc ()) (fun e ->
      Logs.err (fun m -> m "%s" @@ Stdlib.Printexc.to_string e));
  Logs_lwt.info (fun m -> m "New connection %d" id) >>= return

let create_socket () =
  let open Lwt_unix in
  let sock = socket PF_INET SOCK_STREAM 0 in
  bind sock @@ ADDR_INET (listen_address, port) >>= fun () ->
  listen sock backlog;
  return sock

let create_server sock =
  let id = ref 0 in
  let rec serve () =
    id := !id + 1;
    Lwt_unix.accept sock >>= accept_connection !id >>= serve
  in
  serve

let run () =
  let () = Logs.set_reporter @@ Logs.format_reporter () in
  let () = Logs.set_level @@ Some Logs.Info in
  Lwt_main.run
    ( create_socket () >>= fun sock ->
      create_server sock () >>= fun serve -> serve () )
