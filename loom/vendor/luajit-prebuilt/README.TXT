LuaJIT android build on Windows is currently extremely problematic.  It does build with dwimperl gcc in path, however building from
vanilla NDK does not work due to a combination of NDK make/gcc and magic flags.  In the meantime, we use this prebuilt LuaJIT android
build which the Rakefile copies into the proper location instead of building Android luaJIT on Windows