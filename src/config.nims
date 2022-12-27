# --d:release # uncomment to build release optimized version (smaller, slightly faster, takes longer to build)
--d:ssl
--threadAnalysis:off
--opt:speed
--threads:off

import std/strutils
# Cross-compile to a Windows .exe
when defined(crosswin):
  switch("cc", "gcc")
  let mingwExe = 
    if hostCPU == "amd64":
      "x86_64-w64-mingw32-gcc"
    elif hostCPU == "i386":
      "i686-w64-mingw32-gcc"
    else: 
      "error"
  switch("gcc.linkerexe", mingwExe)
  switch("gcc.exe", mingwExe)
  switch("gcc.path", findExe(mingwExe).rsplit("/", 1)[0])
  switch("gcc.options.linker", "")
  switch("os", "windows")
  switch("define", "windows")