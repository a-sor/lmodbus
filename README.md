# lmodbus
This is an implementatin of the [ModBus](https://en.wikipedia.org/wiki/Modbus) protocol for [Lua](https://en.wikipedia.org/wiki/Lua_(programming_language)). I wrote it when I needed it for a particular task and I am putting it out in the hope that it might be useful to someone else.

Of course, there are other — and more extensive — Lua implementations of the ModBus protocol on the Web. I created mine because I couldn't find one that would simultaneously:
- have both server and client capabilities;
- be "channel agnostic", that is, allow me to work with the data, but wouldn't drag around with it its own implementation of the COM port.

**Important: `lmodbus` uses native bitwise operators `&`, `|`, etc. that were introduced only in Lua 5.3. This means that you can't use `lmodbus` with Lua versions prior to 5.3, sorry :( Portability was not so much of a concern for my task as was the speed of development/program execution.**

**However, you can still port `lmodbus` yourself by rewriting the functions `band()`, `bor()`, etc. It may not be so difficult as it seems. You should include some [implementation of bitwise operators](http://lua-users.org/wiki/BitwiseOperators) and replace the operators `&`, `|`, etc. with matching function calls.**

# Usage example

Below are basic examples of a ModBus client and a server. For more details, please read the source code and the testing program. I hope I will get around to writing proper documentation some time in the future :)

## Client example

```lua
  local mb = require('lmodbus')

  --[[
    When you send a request, you must first define a transaction
    in the following manner:
  ]]
  local xact = {
    -- ModBus protocol type, currently only 'RTU' and 'TCP' are supported.
    type = 'RTU',
    -- ModBus function, see source code for more values.
    func = 'READ_HOLDING_REGISTERS',
    -- Server address, optional. If not defined, 1 is assumed.
    server_addr = 1,
    -- The starting address of the registers or whatever entities
    -- that are (will be) supported.
    start_addr = 600,
    -- Quantity of registers being queried. (For 1-bit access functions,
    -- such as Read Coils, bit_count is used.)
    word_count = 2,
  }

  -- req is a string containing the binary data of the request
  local req = mb.build_request(xact)

  -- send the request, e.g.
  -- send(req)

  -- get the response, e.g.
  -- resp = receive() -- resp must be a string

  local ok, err = mb.parse_response(xact, resp)

  if not ok then
    error(err)
  end

  for i = 1, #xact.words do
    -- Note that for 1-bit access functions, such as Read Coils,
    -- xact.bits is used.
    print('regs[%d] = %d\n', xact.start_addr + i - 1, xact.words[i])
  end
```

## Server example

```lua
  local mb = require('lmodbus')

  --[[
    Again, we must define a transaction first. The transaction object will
    contain the request data after the request is parsed.
  ]]
  local xact = {
    -- The parser must know the ModBus protocol type.
    type = 'RTU',
    words = {}
    -- more fields, e.g. server_addr, word_count, etc. will be created
    -- during the parse
  }
  local req = ''

  while true do
    -- get the next chunk of the request, e.g.
    --local data = receive()

    -- we assume we may not receive a whole request at a time
    req = req .. data

    local ok, n = mb.parse_request(xact, req)

    if ok then
      -- discard the parsed request
      req = req:sub(n + 1, -1)

      print('func: ', mb.func_str(xact.func))
      print('start_addr: ', xact.start_addr)
      print('word_count: ', xact.word_count)

      for i = 1, xact.word_count do
        -- fill the response registers with data, e.g.
        --xact.words[i] = regs[i - 1]
      end

      -- send the response
      local ok, resp = mb.build_response(xact)

      -- ...

    elseif n == mb.STAT_NOT_COMPLETED then
      -- do nothing. We haven't received a complete request yet,
      -- so we just go for the next chunk of data
    else
      -- error handling
      -- ...
    end
  end
```
