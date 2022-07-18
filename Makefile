lint:
	dune build @lint
	dune build @fmt

test:
	dune runtest

clean:
	dune clean
	git clean -dfX
	rm -rf docs/

doc:
	make clean
	dune build @doc
	mkdir docs/
	cp -r ./_build/default/_doc/_html* docs/

format:
	dune build @fmt --auto-promote

coverage:
	make clean
	BISECT_ENABLE=yes dune build
	dune runtest
	bisect-ppx-report html
	bisect-ppx-report summary
