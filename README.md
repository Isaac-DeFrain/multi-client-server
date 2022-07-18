# multi-client-server

Simple multi-client server which maintains a shared ledger of `(int, string)` pairs

## Run the server

Clone the repo and change to the repo directory

```bash
$ git clone https://github.com/Isaac-DeFrain/multi-client-server.git
$ cd multi-client-server
```

Install dependencies and build the project

```bash
$ opam install --deps-only .
$ dune build
```

Open a terminal from this directory and start the server

```bash
$ dune exec -- ./_build/default/bin/mcs.exe
```

Open a fresh terminal (or several), connect to the server, and send some messages

```bash
$ telnet localhost 9000
```

## Valid messages

Message | What it does
---|---
`#` | returns the server's current number of connections
`id` | returns the client's internal id number
`get <key>` | returns the ledger value associated with the key (if it exists)
`set <key> <value>` | sets the value for the key in the ledger
`del <key>` | deletes the key from the ledger
