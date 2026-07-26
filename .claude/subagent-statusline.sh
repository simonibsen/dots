#!/usr/bin/env bash
# Claude Code subagentStatusLine — renders one row per running subagent in the
# agent panel below the prompt, showing the resolved model each one runs on:
#
#   <name> · <Model> · <tokens>
#
# Receives {tasks:[...]} on stdin (base hook fields + columns + tasks array).
# Each task has: id, name, type, status, description, label, startTime,
# model, effort, contextWindowSize, tokenCount, tokenSamples, cwd.
# `model` is the resolved model ID (Claude Code >= 2.1.205); omitted until
# the task's model resolves. We emit one {"id","content"} JSON line per row.

input=$(cat)

echo "$input" | jq -c '
  .tasks[]?
  | (.name // .label // .type // "agent") as $name
  # Shorten the resolved model to its family name. `.model` is documented as a
  # resolved model-ID string; tolerate an object form ({display_name|id}) too.
  | ((if (.model | type) == "object" then (.model.display_name // .model.id // "")
      else (.model // "") end) | tostring) as $modelid
  | (if $modelid != "" then
        ($modelid | ascii_downcase) as $m
        # Substring match, so it is order-independent: both "claude-sonnet-5"
        # and the older "claude-3-5-sonnet-20241022" map to "Sonnet", and a new
        # *version* of a known family auto-shortens. A new family *name* falls
        # through to the raw model ID (readable, just not shortened).
        # NEW FAMILY? Add its line here, e.g.:
        #    elif ($m | test("titan"))  then "Titan"
        | (if   ($m | test("opus"))   then "Opus"
           elif ($m | test("sonnet")) then "Sonnet"
           elif ($m | test("haiku"))  then "Haiku"
           elif ($m | test("fable"))  then "Fable"
           else $modelid end)
     else "" end) as $model
  # Humanize the running token count (>=1000 -> Nk).
  | (if (.tokenCount // 0) > 0 then
        (.tokenCount | if . >= 1000 then ((. / 1000) | floor | tostring) + "k"
                       else tostring end)
     else "" end) as $tok
  | { id: .id,
      content: ([$name, $model, $tok] | map(select(. != "")) | join(" · ")) }
'
