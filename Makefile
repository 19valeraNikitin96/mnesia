PROJECT = mnesia_cache
PROJECT_DESCRIPTION = New project
PROJECT_VERSION = 0.1.0

LOCAL_DEPS = mnesia

#
DEPS = cowboy jsx
dep_cowboy_commit = 2.7.0
dep_jsx_commit = 2.9.0

DEP_PLUGINS = cowboy jsx

include erlang.mk
