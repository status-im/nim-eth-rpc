include ../ json_rpc / client

proc nextId*(self: RpcClient): int64 = self.nextId

proc rawCall*(self: RpcClient, name: string,
           msg: string): Future[Response] {.async.} =
  # For debug purposes only
  let id = $self.nextId
  self.nextId.inc

  var s = msg & "\r\n"
  let res = await self.transport.write(s)
  doAssert res == len(s)

  # completed by processMessage.
  var newFut = newFuture[Response]()
  # add to awaiting responses
  self.awaiting[id] = newFut

  result = await newFut
