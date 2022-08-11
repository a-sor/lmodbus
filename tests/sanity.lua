--[[
  A simple sanity test with some already known ModBus transactions.
]]

local sprintf = string.format

local function str_to_hex(str)
  local ret = ''
  local sep = ''

  for i = 1, #str do
    ret = ret .. sprintf('%s%02X', sep, str:byte(i))
    sep = ' '
  end

  return ret
end

  local mb = require('lmodbus')

  local transactions = {
      -- https://www.fernhillsoftware.com/help/drivers/modbus/modbus-protocol.html
    {
      type = 'RTU', func = 'READ_COILS', server_addr = 2,
      start_addr = 32, bit_count = 12,
      expected_req = "\x02\x01\x00\x20\x00\x0C\x3D\xF6",

      resp = "\x02\x01\x02\x80\x02\x1D\xFD",
      expected_bits = { 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, },
    },
    {
      type = 'RTU', func = 'READ_HOLDING_REGISTERS', server_addr = 1,
      start_addr = 600, word_count = 2,
      expected_req = "\x01\x03\x02\x58\x00\x02\x44\x60",

      resp = "\x01\x03\x04\x03\xE8\x13\x88\x77\x15",
      expected_words = {1000, 5000},
    },
    {
      type = 'TCP', func = 'READ_HOLDING_REGISTERS', server_addr = 1,
      start_addr = 600, word_count = 2,
      expected_req = "\x00\x00\x00\x00\x00\x06\x01\x03\x02\x58\x00\x02",

      resp = "\x00\x0F\x00\x00\x00\x07\x01\x03\x04\x03\xE8\x13\x88",
      expected_words = {1000, 5000},
    },
    {
      type = 'RTU', func = 'READ_INPUT_REGISTERS', server_addr = 1,
      start_addr = 200, word_count = 2,
      expected_req = "\x01\x04\x00\xC8\x00\x02\xF0\x35",

      resp = "\x01\x04\x04\x27\x10\xC3\x50\xA0\x39",
      expected_words = {10000, 50000},
    },
    {
      type = 'TCP', func = 'READ_INPUT_REGISTERS', server_addr = 1,
      start_addr = 200, word_count = 2,
      expected_req = "\x00\x00\x00\x00\x00\x06\x01\x04\x00\xC8\x00\x02",

      resp = "\x00\x14\x00\x00\x00\x07\x01\x04\x04\x27\x10\xC3\x50",
      expected_words = {10000, 50000},
    },
    {
      type = 'RTU', func = 'WRITE_MULTIPLE_REGISTERS', server_addr = 0x1C,
      start_addr = 0x64, words = { 0x03E8, 0x07D8 },
      expected_req = "\x1C\x10\x00\x64\x00\x02\x04\x03\xE8\x07\xD8\x19\x02",

      resp = "\x1C\x10\x00\x64\x00\x02\x03\x9A",
    },
    {
      type = 'TCP', func = 'WRITE_MULTIPLE_REGISTERS', server_addr = 0x1C,
      start_addr = 0x64, words = { 0x03E8, 0x07D8 },
      expected_req = "\x00\x00\x00\x00\x00\x0B\x1C\x10\x00\x64\x00\x02\x04\x03\xE8\x07\xD8",

      resp = "\x00\x23\x00\x00\x00\x06\x1C\x10\x00\x64\x00\x02",
    },
      -- https://www.modbustools.com/modbus.html
    {
      type = 'RTU', func = 'READ_COILS', server_addr = 4,
      start_addr = 10, bit_count = 13,
      expected_req = "\x04\x01\x00\x0A\x00\x0D\xDD\x98",

      resp = "\x04\x01\x02\x0A\x11\xB3\x50",
      expected_bits = {0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, },
    },
    {
      type = 'RTU', func = 'READ_HOLDING_REGISTERS', server_addr = 1,
      start_addr = 0, word_count = 2,
      expected_req = "\x01\x03\x00\x00\x00\x02\xC4\x0B",

      resp = "\x01\x03\x04\x00\x06\x00\x05\xDA\x31",
      expected_words = {6, 5},
    },
    {
      type = 'RTU', func = 'READ_INPUT_REGISTERS', server_addr = 1,
      start_addr = 0, word_count = 2,
      expected_req = "\x01\x04\x00\x00\x00\x02\x71\xCB",

      resp = "\x01\x04\x04\x00\x06\x00\x05\xDB\x86",
      expected_words = {6, 5},
    },
      -- https://ctlsys.com/support/modbus_message_examples/
    {
      type = 'RTU', func = 'READ_HOLDING_REGISTERS', server_addr = 1,
      start_addr = 1200, word_count = 21,
      expected_req = "\x01\x03\x04\xB0\x00\x15\x84\xD2",

      resp = "\x01\x03\x2A\x01\x40\x00\x00\x01\x40\x00\x00\x01\x40\x00\x00\x01"..
        "\x40\x00\x00\x07\x17\x02\x65\x02\x3E\x02\x73\x04\x9F\x04\xBC\x04"..
        "\x6D\x04\xB3\x08\x01\x07\xEF\x07\xE7\x08\x2C\x02\x58\xC3\xFC",
      expected_words = { 0x0140, 0x0000, 0x0140, 0x0000, 0x0140, 0x0000,
        0x0140, 0x0000, 0x0717, 0x0265, 0x023E, 0x0273, 0x049F, 0x04BC, 0x046D,
        0x04B3, 0x0801, 0x07EF, 0x07E7, 0x082C, 0x0258},
    },
      -- https://ipc2u.com/articles/knowledge-base/modbus-rtu-made-simple-with-detailed-descriptions-and-examples/
    {
      type = 'RTU', func = 'READ_COILS', server_addr = 17,
      start_addr = 19, bit_count = 37,
      expected_req = "\x11\x01\x00\x13\x00\x25\x0E\x84",

      resp = "\x11\x01\x05\xCD\x6B\xB2\x0E\x1B\x45\xE6",
      expected_bits = {1, 0, 1, 1, 0, 0, 1, 1,
                       1, 1, 0, 1, 0, 1, 1, 0,
                       0, 1, 0, 0, 1, 1, 0, 1,
                       0, 1, 1, 1, 0, 0, 0, 0,
                       1, 1, 0, 1, 1, },
    },
    {
      type = 'RTU', func = 'READ_HOLDING_REGISTERS', server_addr = 17,
      start_addr = 0x6B, word_count = 3,
      expected_req = "\x11\x03\x00\x6B\x00\x03\x76\x87",

      resp = "\x11\x03\x06\xAE\x41\x56\x52\x43\x40\x49\xAD",
      expected_words = {0xAE41, 0x5652, 0x4340},
    },
    {
      type = 'RTU', func = 'READ_INPUT_REGISTERS', server_addr = 17,
      start_addr = 8, word_count = 1,
      expected_req = "\x11\x04\x00\x08\x00\x01\xB2\x98",

      resp = "\x11\x04\x02\x00\x0A\xF8\xF4",
      expected_words = {0x000A},
    },
    {
      type = 'RTU', func = 'WRITE_MULTIPLE_REGISTERS', server_addr = 17,
      start_addr = 0x0001, words = {0x000A, 0x0102},
      expected_req = "\x11\x10\x00\x01\x00\x02\x04\x00\x0A\x01\x02\xC6\xF0",

      resp = "\x11\x10\x00\x01\x00\x02\x12\x98",
    },
      -- https://unserver.xyz/modbus-guide/
    {
      type = 'RTU', func = 'READ_COILS', server_addr = 1,
      start_addr = 10, bit_count = 2,
      expected_req = "\x01\x01\x00\x0A\x00\x02\x9D\xC9",

      resp = "\x01\x01\x01\x03\x11\x89",
      expected_bits = {1, 1, },
    },
    {
      type = 'RTU', func = 'READ_HOLDING_REGISTERS', server_addr = 1,
      start_addr = 2, word_count = 1,
      expected_req = "\x01\x03\x00\x02\x00\x01\x25\xca",

      resp = "\x01\x03\x02\x07\xFF\xFA\x34",
      expected_words = {0x07FF},
    },
    {
      type = 'RTU', func = 'READ_INPUT_REGISTERS', server_addr = 1,
      start_addr = 0, word_count = 1,
      expected_req = "\x01\x04\x00\x00\x00\x01\x31\xca",

      resp = "\x01\x04\x02\x03\xFF\xF9\x80",
      expected_words = {0x03FF},
    },
      -- https://www.generationrobots.com/media/roboteq/modbus-manual.pdf
    {
      type = 'RTU', func = 'READ_INPUT_REGISTERS', server_addr = 1,
      start_addr = 0x20C1, word_count = 2,
      expected_req = "\x01\x04\x20\xC1\x00\x02\x2B\xF7",

      resp = "\x01\x04\x04\x00\x00\x12\x34\xF6\xF3",
      expected_words = {0x0000, 0x1234},
    },
    {
      type = 'RTU', func = 'WRITE_MULTIPLE_REGISTERS', server_addr = 1,
      start_addr = 0x00A1, words = {0x0000, 0x1234},
      expected_req = "\x01\x10\x00\xA1\x00\x02\x04\x00\x00\x12\x34\x35\x6C",

      resp = "\x01\x10\x00\xA1\x00\x02\x10\x2A",
    },
    {
      type = 'TCP', func = 'READ_INPUT_REGISTERS', server_addr = 1, transact_id = 3,
      start_addr = 0x20C1, word_count = 2,
      expected_req = "\x00\x03\x00\x00\x00\x06\x01\x04\x20\xC1\x00\x02",

      resp = "\x00\x03\x00\x00\x00\x07\x01\x04\x04\x00\x00\x12\x34",
      expected_words = {0, 0x1234},
    },
  }

  for _, x in ipairs(transactions) do
    print(x.func)
    local req = mb.build_request(x)
    if req ~= x.expected_req then
      error('Result mismatch:\n'..
      '  Expected: ' .. str_to_hex(x.expected_req) .. '\n' ..
      '  Got:      ' .. str_to_hex(req)
      )
    end
    if x.resp then
      local ok, err = mb.parse_response(x, x.resp)
      if not ok then
        error(err)
      end
      if x.expected_words then
        if #x.expected_words ~= #x.words then
          error('Words count mismatch')
        end
        for i = 1, #x.words do
          if x.words[i] ~= x.expected_words[i] then
            error('Words mismatch:\n' ..
              sprintf('  expected_words[%d] = %d\n', i, x.expected_words[i]) ..
              sprintf('           words[%d] = %d\n', i, x.words[i])
            )
          end
        end
      elseif x.expected_bits then
        if #x.expected_bits ~= #x.bits then
          error('Bits count mismatch')
        end
        for i = 1, #x.bits do
          if x.bits[i] ~= x.expected_bits[i] then
            error('Bits mismatch:\n' ..
              sprintf('  expected_bits[%d] = %d\n', i, x.expected_bits[i]) ..
              sprintf('           bits[%d] = %d\n', i, x.bits[i])
            )
          end
        end
      else
        print('  No response words expected.')
      end
      print('  OK')
    else
      print('  Response not checked.')
    end
  end
