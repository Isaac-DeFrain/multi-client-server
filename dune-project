(lang dune 3.3)

(name mcs)

(generate_opam_files true)

(source
 (github Isaac-DeFrain/multi-client-server))

(authors "Isaac DeFrain")

(maintainers "Isaac DeFrain")

(license LICENSE)

(documentation https://github.com/Isaac-DeFrain/multi-client-server)

(package
 (name mcs)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune core lwt logs str)
 (tags
  (topics "multi-client server" your project))
 (allow_empty))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
