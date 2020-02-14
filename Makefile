PROJECT = mnesia_cache
PROJECT_DESCRIPTION = New project
PROJECT_VERSION = 0.1.0

LOCAL_DEPS = mnesia

#https://github.com/marianoguerra/jwt-erl/releases
DEPS = cowboy jsx jwt
dep_cowboy_commit = 2.7.0
dep_jsx_commit = 2.9.0
dep_jwt = git https://github.com/marianoguerra/jwt-erl
DEP_PLUGINS = cowboy jsx jwt

include erlang.mk
