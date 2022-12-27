import std/[strutils]

import parsetoml

import types

var cfg*: Config

proc readConfig* = 
  let parsed = parseFile("config.toml")
  cfg = Config(
    port: parsed["port"].getInt,
    backend: parseEnum[ImageBackend](parsed["backend"].getStr),
    steps: parsed["steps"].getInt,
    naiToken: parsed["NovelAI"]["token"].getStr,
    batchSize: parsed["AutoWebUI"]["batch_size"].getInt,
    uc: parsed["negative_prompt"].getStr,
    naiModel: parsed["NovelAI"]["model"].getStr,
    webuiHost: parsed["AutoWebUI"]["host"].getStr,
    prepend: parsed["prepend_prompt"].getStr,
    append: parsed["append_prompt"].getStr
  )

  let res = parsed["resolution"]
  (cfg.width, cfg.height) = (res[0].getInt(), res[1].getInt())

readConfig()
