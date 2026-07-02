# SPDX-License-Identifier: Apache-2.0 OR MIT
# Copyright (c) Status Research & Development GmbH

# Generic custom-task request: lets superset-linked modules (e.g. the RLN
# gifter protocol) run code on the libp2p worker thread with direct access to
# the LibP2P state (switch, rng). The task is a plain top-level {.nimcall.}
# proc that typically `asyncSpawn`s its own async work and owns any C callback
# it needs to invoke; `data` is an opaque shared-allocated pointer the task
# takes ownership of and must free once its async work completes.

import chronos
import ../../../types

type CustomTaskFn* = proc(
  libp2p: ptr LibP2P, data: pointer
) {.nimcall, gcsafe, raises: [].}

type CustomRequest* = object
  task: CustomTaskFn
  data: pointer

proc createShared*(T: type CustomRequest, task: CustomTaskFn, data: pointer): ptr type T =
  var ret = createShared(T)
  ret[].task = task
  ret[].data = data
  ret

proc destroyShared*(self: ptr CustomRequest) =
  deallocShared(self)

proc process*(
    self: ptr CustomRequest, libp2p: ptr LibP2P
) {.async: (raises: [CancelledError]).} =
  ## Runs the task synchronously on the worker thread. The task is expected to
  ## schedule its own async work (asyncSpawn) and invoke its own callback; this
  ## request carries no callback of its own.
  let task = self[].task
  let data = self[].data
  destroyShared(self)
  if not task.isNil():
    task(libp2p, data)
