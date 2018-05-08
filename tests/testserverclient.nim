import ../ rpcclient, ../ rpcserver, 
  asyncdispatch, json, unittest, tables

# TODO: dummy implementations of RPC calls handled in async fashion.
var srv = sharedRpcServer()
srv.address = "localhost"
srv.port = Port(8545)

srv.on("myProc") do(input: string, data: array[0..3, int]):
  result = %("Hello " & input & " data: " & $data)

asyncCheck srv.serve

suite "RPC":
  proc main {.async.} =
    var client = newRpcClient()
    await client.connect("localhost", Port(8545))
    var response: Response

    test "Version":
      response = waitFor client.web3_clientVersion(newJNull())
      check response.result == %"Nimbus-RPC-Test"
    test "SHA3":
      response = waitFor client.web3_sha3(%["abc"])
      check response.result.getStr == "3A985DA74FE225B2045C172D6BD390BD855F086E3E9D525B46BFE24511431532"
    test "Custom RPC":
      # Custom async RPC call
      response = waitFor client.call("myProc", %[%"abc", %[1, 2, 3, 4]])
      check response.result.getStr == "Hello abc data: [1, 2, 3, 4]"

  

  waitFor main()
  