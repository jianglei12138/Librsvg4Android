#! /usr/bin/env bash
# Copyright (C) 2017 Expat development team
# Licensed under the MIT license

case "aarch64-unknown-linux-gnu" in
*-mingw*)
    exec wine "$@"
    ;;
*)
    exec "$@"
    ;;
esac
