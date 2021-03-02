import
  unittest, json, chronicles,
  ../json_rpc/[rpcclient, rpcserver]

var srv = newRpcSocketServer(["localhost:8545"])
var client = newRpcSocketClient()

# Create RPC on server
srv.rpc("myProc") do(input: string, data: array[0..3, int]):
  return %("Hello " & input & " data: " & $data)

srv.rpc("myError") do(input: string, data: array[0..3, int]):
  raise (ref ValueError)(msg: "someMessage")

srv.rpc("myUint64") do(data: uint64) -> uint64:
  return data - 1

srv.start()
waitFor client.connect("localhost", Port(8545))

suite "Server/Client RPC":
  test "Successful RPC call":
    let r = waitFor client.call("myProc", %[%"abc", %[1, 2, 3, 4]])
    check r.getStr == "Hello abc data: [1, 2, 3, 4]"

  test "Missing params":
    expect(CatchableError):
      discard waitFor client.call("myProc", %[%"abc"])

  test "Error RPC call":
    expect(CatchableError): # The error type wont be translated
      discard waitFor client.call("myError", %[%"abc", %[1, 2, 3, 4]])

  test "uint64 roundtrip":
    let r = waitFor client.call("myUint64", %[uint64.high()])
    check r.getStr == $(uint64.high() - 1)

srv.stop()
waitFor srv.closeWait()
