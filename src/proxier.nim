import std/[strutils, httpclient, asyncdispatch, strformat, os, tables, sequtils]
import uuid4
import prologue


import types
import config
import backends/[novelai, auto_webui]

var 
  tasks: Table[string, ImageTask]
  # Tasks waiting to start generating, only used with webui + batching
  toStartGenerate: seq[string]

const myHost = "https://paint.api.wombo.ai"

proc generateMultiple*() {.async.} = 
  while true:
    if toStartGenerate.len == 0: 
      await sleepAsync(1000)
      continue
    var toGen: seq[string]
    for _ in 0..<cfg.batchSize:
      if toStartGenerate.len == 0:
        break
      toGen.add toStartGenerate.pop()
    echo fmt"Generating a batch of {toGen.len} images"
    let prompts = toGen.mapIt(tasks[it].prompt)
    let (isOk, results) = await auto_webui.genImagesBatch(prompts)
    if isOk:
      for i, id in toGen.pairs():
        tasks[id].content = results[i]
        tasks[id].state = Generated

proc genImageWrapper*(taskId: string, prompt: string) {.async.} =
  tasks[taskId] = ImageTask(state: ImageTaskState.Pending, prompt: prompt)
  let (isOk, content) = 
    case cfg.backend
    of NovelAI: await novelai.genImage(prompt)
    of AutoWebUI: await auto_webui.genImage(prompt)

  if isOk:
    #echo "Added generated task to tasks list!"
    tasks[taskId] = ImageTask(content: content, state: ImageTaskState.Generated, prompt: prompt)
  else:
    # Doesn't look like wombo has a way to tell that a task couldn't finish generating,
    # so we have to rely on AI Roguelite's own 20 second timeout here
    discard

proc addTask*(ctx: Context) {.async, gcsafe.} =
  let taskId = ctx.getPathParams("taskId", "")
  if taskId.len == 0 or not tasks.hasKey(taskId):
    resp jsonResponse(%*{"error": "taskId is required"})
    return
    
  let data = parseJson(ctx.request.body)["input_spec"]
  let prompt = data["prompt"].getStr()
  if cfg.batchSize > 1:
    tasks[taskId] = ImageTask(state: ImageTaskState.Pending, prompt: prompt)
    toStartGenerate.add(taskId)
  else:
    asyncCheck genImageWrapper(taskId, prompt)
  #echo "Accepted task parameters for generation: ", taskId, " prompt: ", prompt

proc newTask*(ctx: Context) {.async, gcsafe.} =
  let newId = uuid4()
  tasks[$newId] = ImageTask()
  resp jsonResponse(%*{"id": $newId})
  #echo "Generated new task: ", $newId
  return

proc checkTask*(ctx: Context) {.async, gcsafe.} =   
  let taskId = ctx.getPathParams("taskId", "")
  var task = tasks.getOrDefault(taskId, ImageTask())
  if task.state != ImageTaskState.Generated:
    # no images in list
    resp jsonResponse(%*{"photo_url_list": []})
    return
  else:
    #echo "Responding with generated image"
    resp jsonResponse(%*{"photo_url_list": [fmt"{myHost}/images/{taskId}/final.jpg"]})

proc serveImage(ctx: Context) {.async, gcsafe.} = 
  let taskId = ctx.getPathParams("taskId", "")
  let task = tasks.getOrDefault(taskId, ImageTask())
  if task.state != ImageTaskState.Generated:
    # Why is the client asking is for an unfinished image directly?
    resp "Not generated yet"
    return
  else:
    await ctx.respond(Http200, task.content, initResponseHeaders({"Content-Type": "image/png"}))
    # Delete the finished task since we no longer need it to not occupy memory
    tasks.del(taskId)

if cfg.backend == AutoWebUI and cfg.batchSize > 1:
  asyncCheck generateMultiple()

var app = newApp(newSettings(port = Port(cfg.port)))
app.addRoute("/api/tasks/", newTask, HttpPost)
app.addRoute("/api/tasks/{taskId}", checkTask, HttpGet)
app.addRoute("/api/tasks/{taskId}", addTask, HttpPut)
app.addRoute("/images/{taskId}/final.jpg", serveImage, HttpGet)
app.run()
