import std/[httpclient, asyncdispatch, strutils, json, strformat, random, base64]


import ../config

# see https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/API
# http://127.0.0.1:7860/docs
# for batching you apparently need to pass all_prompts and all_seeds instead
# of "prompt" and "seed"
let payload = %*{
  "steps": 20,
  "cfg_scale": 7,
  "width": 512,
  "height": 512,
}

randomize()

let host = cfg.webuiHost
let headers = newHttpHeaders({"Content-Type":"application/json"})

proc genImage*(prompt: string): Future[(bool, string)] {.async.} = 
  let c = newAsyncHttpClient()
  c.headers = headers

  var payload = payload
  if cfg.uc.len > 0:
    payload["negative_prompt"] = %cfg.uc
  payload["prompt"] = %fmt"{cfg.prepend}{prompt}{cfg.append}"
  payload["width"] = %cfg.width
  payload["height"] = %cfg.height
  payload["seed"] = %rand(0'i32..int32.high-1)
  payload["steps"] = %cfg.steps # default, maybe change in the future
  try:
    let resp = await c.post(fmt"{host}/sdapi/v1/txt2img", $payload)
    if resp.code != Http200:
      echo fmt"Got an error from SD: {await resp.body}"
      return (false, "")
    
    let body = parseJson(await resp.body)
    let imageData = body["images"][0].getStr().split(",")[0].decode()

    return (true, imageData)
  finally:
    c.close()

proc genImagesBatch*(prompts: seq[string]): Future[(bool, seq[string])] {.async.} = 
  let c = newAsyncHttpClient()
  c.headers = headers

  var payload = payload
  # XXX: broken because auto's webui checks that prompt is str even though code
  # further down allows for a list of prompts...
  payload["prompt"] = %prompts
  
  if cfg.uc.len > 0:
    payload["negative_prompt"] = %cfg.uc
  
  # I don't think there's a need to specify multiple seeds, it doesn't matter, right?
  payload["seed"] = %rand(0'i32..int32.high-1)
  payload["batch_size"] = %cfg.batch_size
  payload["steps"] = %cfg.steps # default, maybe change in the future
  try:
    let resp = await c.post(fmt"{host}/sdapi/v1/txt2img", $payload)
    if resp.code != Http200:
      echo resp.code
      echo await resp.body
      return (false, @[])
    
    let body = parseJson(await resp.body)
    result = (true, @[])
    for image in body["images"]:
      result[1].add image.getStr().split(",")[1].decode()
    
  finally:
    c.close()
