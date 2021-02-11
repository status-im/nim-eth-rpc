#[
  This module uses debug versions of the rpc components that
  allow unchecked and unformatted calls.
]#

import unittest, debugclient, ../json_rpc/rpcserver
import strformat, chronicles

var server = newRpcSocketServer("localhost", Port(8545))
var client = newRpcSocketClient()

server.start()
waitFor client.connect("localhost", Port(8545))

server.rpc("rpc") do(a: int, b: int):
  result = %(&"a: {a}, b: {b}")

server.rpc("makeError"):
  if true:
    raise newException(ValueError, "Test")

proc testMissingRpc: Future[Response] {.async.} =
  var fut = client.call("phantomRpc", %[])
  result = await fut

proc testInvalidJsonVer: Future[Response] {.async.} =
  let json =
    $ %{"jsonrpc": %"3.99", "method": %"rpc", "params": %[],
      "id": % $client.nextId} & "\r\n"
  var fut = client.rawCall("rpc", json)
  result = await fut

proc testMalformed: Future[Response] {.async.} =
  let malformedJson = "{field: 2, \"field: 3}"
  var fut = client.rawCall("rpc", malformedJson)
  await fut or sleepAsync(1000)
  if fut.finished: result = fut.read()
  else: result = (true, %"Timeout")

proc testRaise: Future[Response] {.async.} =
  var fut = client.call("makeError", %[])
  result = await fut

suite "RPC Errors":
  # Note: We don't expect a exceptions for most of the tests,
  # because the server should respond with the error in json
  test "Missing RPC":
    #expect ValueError:
    try:
      let res = waitFor testMissingRpc()
      check res.error == true and
        res.result["message"] == %"Method not found" and
        res.result["data"] == %"phantomRpc is not a registered method."
    except CatchableError as exc:
      echo "Error ", exc.msg

  #[test "Incorrect json version":
    #expect ValueError:
    try:
      let res = waitFor testInvalidJsonVer()
      check res.error == true and res.result["message"] == %"JSON 2.0 required"
    except CatchableError as exc:
      echo "Error ", exc.msg
  ]#
  test "Raising exceptions":
    #expect ValueError:
    try:
      let res = waitFor testRaise()
    except CatchableError as exc:
      echo "Error ", exc.msg

  test "Malformed json":
    # TODO: We time out here because the server won't be able to
    # find an id to return to us, so we cannot complete the future.
    try:
      let res = waitFor testMalformed()
      check res.error == true and res.result == %"Timeout"
    except CatchableError as exc:
      echo "Error ", exc.msg

