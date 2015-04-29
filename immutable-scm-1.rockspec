package = "immutable"
version = "scm-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   summary = "*** please specify description summary ***",
   detailed = "*** please enter a detailed description ***",
   homepage = "*** please enter a project homepage ***",
   license = "MIT/Expat"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "builtin",
   modules = {
      hashcode = {
         sources = "src/hashcode.c"
      },
      list = "src/list.lua",
      subvec = "src/subvec.lua",
      vector = "src/vector.lua"
   }
}
