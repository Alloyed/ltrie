package = "ltrie"
version = "scm-1"
source = {
   url = "git://github.com/Alloyed/ltrie"
}
description = {
   summary = "A collection of immutable datastructures",
   -- detailed = "*** please enter a detailed description ***",
   homepage = "https://github.com/Alloyed/ltrie",
   license = "MIT"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      hashcode = {
         sources = "ltrie/hashcode.c"
      },
      ['ltrie.list']     = "ltrie/list.lua",
      ['ltrie.subvec']   = "ltrie/subvec.lua",
      ['ltrie.vector']   = "ltrie/vector.lua",
      ['ltrie.fun']      = "ltrie/fun.lua",
      ['ltrie.tablemap'] = "ltrie/tablemap.lua",
   }
}
