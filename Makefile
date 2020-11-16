RELEASE_NAME = chat
DEBUG=1

console:
	./rebar3 as default compile
	./rebar3 as default release
	./_build/default/rel/$(RELEASE_NAME)/bin/$(RELEASE_NAME) console