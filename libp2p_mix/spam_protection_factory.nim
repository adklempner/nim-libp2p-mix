# SPDX-License-Identifier: Apache-2.0 OR MIT
# Copyright (c) Status Research & Development GmbH

## Generic, RLN-agnostic spam-protection injection hook for the mix protocol.
##
## A plugin (e.g. mix-rln-spam-protection-plugin) registers a factory BEFORE
## `libp2p_new` is called; the factory runs on the libp2p thread at mix mount
## time (MIX_SET_NODE_INFO). Injection is mount-time-only by design: spam
## protection changes the wire packet size (maxWireSize = PacketSize +
## proofSize), so flipping it on a live protocol would corrupt in-flight
## packets. There is intentionally NO post-construction setter.
##
## The factory type is `nimcall` (no closures): it is registered on the host
## thread but invoked on the libp2p thread, and closure environments must not
## cross threads (GC-unsafe). Implementations keep their config in their own
## thread-safe storage.

import results
import ./spam_protection

type MixSpamProtectionFactory* = proc(): Opt[SpamProtection] {.
  gcsafe, nimcall, raises: []
.}

var factory: MixSpamProtectionFactory = nil

proc registerSpamProtectionFactory*(f: MixSpamProtectionFactory) =
  ## Must be called before `libp2p_new`; the registration is read once at
  ## mix mount time. Thread-safety relies on the libp2p thread being created
  ## after registration (happens-before via thread start).
  {.cast(gcsafe).}:
    factory = f

proc makeSpamProtection*(): Opt[SpamProtection] {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    if factory.isNil:
      Opt.none(SpamProtection)
    else:
      factory()
