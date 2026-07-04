# SPDX-License-Identifier: Apache-2.0 OR MIT
# Copyright (c) Status Research & Development GmbH

import std/tables
import chronos
import results
import pkg/libp2p
import pkg/libp2p/protocols/protocol
import pkg/libp2p/protocols/pubsub/gossipsub
import pkg/libp2p/protocols/kademlia
import pkg/libp2p_mix
import pkg/libp2p_mix/mix_node
import pkg/libp2p/protocols/connectivity/relay/client
import ffi_types

# TODO: remove and implement custom event callbacks if needed
# Example:
#   proc onSomeEvent(ctx: ptr LibP2PContext): Libp2pCallback =
#    return proc(msg: string) {.gcsafe.} =
#      callEventCallback(ctx, "onSomeEvent"):
#        $JsonMyEvent.new(msg)
type AppCallbacks* = ref object

type PubsubTopicPair* = tuple[topic: string, handler: PubsubTopicHandler]
type TopicHandlerEntry* = tuple[handler: TopicHandler, userData: pointer]

type LibP2P* = ref object
  switch*: Switch
  rng*: Rng
  gossipSub*: Opt[GossipSub]
  kad*: Opt[KadDHT]
  mix*: Opt[MixProtocol]
  mixNodeInfo*: Opt[MixNodeInfo]
  relayClient*: Opt[RelayClient]
  topicHandlers*: Table[PubsubTopicPair, TopicHandlerEntry]
  streams*: Table[ptr Libp2pStream, Stream]
  streamReleaseWaiters*: Table[ptr Libp2pStream, Future[void].Raising([CancelledError])]
  customProtocols*: Table[string, LPProtocol]
