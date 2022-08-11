
  -- supported ModBus transaction types
  local types = {
    RTU = 1,
    TCP = 2,
  }

  -- supported ModBus functions
  local funcs = {
    READ_COILS =                    0x01,
    -- READ_DISCRETE_INPUTS =          0x02,
    READ_HOLDING_REGISTERS =        0x03,
    READ_INPUT_REGISTERS =          0x04,
    -- WRITE_SINGLE_COIL =             0x05,
    -- WRITE_SINGLE_REGISTER =         0x06,
    -- READ_EXCEPTION_STATUS =         0x07,
    -- DIAGNOSTICS =                   0x08,
    -- GET_COMM_EVENT_COUNTER =        0x0B,
    -- GET_COMM_EVENT_LOG =            0x0C,
    -- WRITE_MULTIPLE_COILS =          0x0F,
    WRITE_MULTIPLE_REGISTERS =      0x10,
    REPORT_SLAVE_ID =               0x11,
    -- READ_FILE_RECORD =              0x14,
    -- WRITE_FILE_RECORD =             0x15,
    MASK_WRITE_REGISTER =           0x16,
    -- READ_WRITE_MULTIPLE_REGISTERS = 0x17,
    -- READ_FIFO_QUEUE =               0x18,
    -- READ_DEVICE_ID =                0x2B,
  }

  local errors = {
    [0x00] = "NO ERROR",
    [0x01] = "ILLEGAL FUNCTION",
    [0x02] = "ILLEGAL DATA ADDRESS",
    [0x03] = "ILLEGAL DATA VALUE",
    [0x04] = "SLAVE DEVICE FAILURE",
    [0x05] = "ACKNOWLEDGE",
    [0x06] = "SLAVE DEVICE BUSY",
    [0x08] = "MEMORY PARITY ERROR",
    [0x0A] = "GATEWAY PATH UNAVAILABLE",
    [0x0B] = "GATEWAY TARGET DEVICE FAILED TO RESPOND",
  }

  local stat = {
    COMPLETED =          'Completed',
    NOT_COMPLETED =      'Not completed',
    INVALID_PARAM =      'Invalid parameter',
    CRC_ERROR =          'CRC error',
    OVERFLOW =           'Overflow',
    FUNC_NOT_SUPPORTED = 'Function not supported',
    INVALID_REQUEST =    'Invalid request',
    INVALID_RESPONSE =   'Invalid response',
  }

-------------------------------------------------------------------------------
--- Utilities
-------------------------------------------------------------------------------

  local sprintf = string.format

local function errorf(...)
  error(sprintf(...))
end

-------------------------------------------------------------------------------

local function band(x, y)
  return x & y
end

-------------------------------------------------------------------------------

local function bor(x, y)
  return x | y
end

-------------------------------------------------------------------------------

local function bxor(x, y)
  return x ~ y
end

-------------------------------------------------------------------------------

local function blshift(x, n)
  return x << n
end

-------------------------------------------------------------------------------

local function brshift(x, n)
  return x >> n
end

-------------------------------------------------------------------------------

local function in_range(val, min, max)
  return type(val) == 'number' and val >= min and val <= max
end

-------------------------------------------------------------------------------

local function byte_at(str, ofs)
  return str:byte(ofs + 1) -- ofs is zero-based
end

-------------------------------------------------------------------------------

local function word_at(str, ofs)

  ofs = ofs + 1 -- ofs is zero-based

  return blshift(str:byte(ofs), 8) + str:byte(ofs + 1)
end

-------------------------------------------------------------------------------

local function word_at_le(str, ofs)
  -- little-endian

  ofs = ofs + 1 -- ofs is zero-based

  return blshift(str:byte(ofs + 1), 8) + str:byte(ofs)
end

-------------------------------------------------------------------------------

local function mk_word(val)
  return string.char(band(brshift(val, 8), 0xFF), band(val, 0xFF))
end

-------------------------------------------------------------------------------

local function mk_word_le(val)
  return string.char(band(val, 0xFF), band(brshift(val, 8), 0xFF))
end

-------------------------------------------------------------------------------

  local crc16_tab = {
    0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
    0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
    0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
    0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
    0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
    0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
    0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
    0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
    0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
    0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
    0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
    0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
    0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
    0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
    0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
    0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
    0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
    0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
    0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
    0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
    0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
    0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
    0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
    0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
    0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
    0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
    0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
    0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
    0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
    0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
    0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
    0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040,
  }

-------------------------------------------------------------------------------

local function calc_crc16(str, size)
  local crc = 0xFFFF

  if not size then
    size = #str
  end

  for i = 1, size do
    local b = str:byte(i)
    crc = bxor(brshift(crc, 8),  crc16_tab[band(bxor(crc, b), 0xFF) + 1])
  end

  return crc
end

-------------------------------------------------------------------------------

local function check_crc16(str)
  local ofs = #str - 2
  return calc_crc16(str, ofs) == word_at_le(str, ofs)
end

-------------------------------------------------------------------------------

local function is_rtu(xact)
  return xact.type == types.RTU or xact.type == 'RTU'
end

-------------------------------------------------------------------------------

local function is_tcp(xact)
  return xact.type == types.TCP or xact.type == 'TCP'
end

-------------------------------------------------------------------------------

  local adu_header_size_tab = {
    RTU = 1, [types.RTU] = 1,
    TCP = 7, [types.TCP] = 7,
  }


local function adu_header_size(xact)
  return adu_header_size_tab[xact.type]
end

  local func_ofs = adu_header_size

-------------------------------------------------------------------------------

  local crc_size_tab = {
    RTU = 2, [types.RTU] = 2,
    TCP = 0, [types.TCP] = 0,
  }

local function crc_size(xact)
  return crc_size_tab[xact.type]
end

-------------------------------------------------------------------------------

local function adu_extra_size(xact)
  return adu_header_size(xact) + crc_size(xact)
end

-------------------------------------------------------------------------------

local function min_request_size(xact)
  -- Function code + application data header size
  return 1 + adu_header_size(xact)
end

-------------------------------------------------------------------------------

local function min_response_size(xact)
  -- Function code + Exception code + application data header size
  return 1 + 1 + adu_header_size(xact)
end

-------------------------------------------------------------------------------

local function request_item_count(xact, req)
  -- Quantity of Inputs/Outputs
  return word_at(req, adu_header_size(xact) + 3)
end

  local response_item_count = request_item_count

-------------------------------------------------------------------------------

local function response_byte_count(xact, resp)
  return byte_at(resp, adu_header_size(xact) + 1)
end

-------------------------------------------------------------------------------

local function fix_mbap_length(str)
-- Set the length value in the MBAP header.
-- XXX Assume type == 'TCP'
  return str:sub(1, 4) .. mk_word(#str - 6) .. str:sub(7, -1)
end

-------------------------------------------------------------------------------

local function get_mbap_length(str)
-- Get the length value from the MBAP header.
-- XXX Assume type == 'TCP'

  return word_at(str, 4)
end

-------------------------------------------------------------------------------

local function new_adu(xact)

  if is_rtu(xact) then
    -- TODO check range
    return string.char(xact.server_addr)
  elseif is_tcp(xact) then
    return
      -- MBAP header
      mk_word(xact.transact_id) ..
      string.char(
      -- 0 = MODBUS protocol
      0, 0,
      -- XXX Length. This value must be subsequently fixed by the call to
      -- fix_mbap_length after we know the data size.
      0, 0,
      -- TODO check range
      xact.server_addr
    )
  end

  -- can't happen?
  return ''
end

-------------------------------------------------------------------------------

local function calc_byte_count(bit_count)
  local byte_count, frac = math.modf(bit_count / 8)

  if frac ~= 0.0 then
    byte_count = byte_count + 1
  end

  return byte_count
end

-------------------------------------------------------------------------------
-- READ COILS
-------------------------------------------------------------------------------

local function build_request_read_coils(xact)

  if not in_range(xact.bit_count, 1, 2000) then
    errorf("'bit_count' value (%s) is not properly assigned or out of range 1..2000",
      tostring(xact.word_count))
  end

  local req = new_adu(xact) ..
    string.char(funcs.READ_COILS) ..
    mk_word(xact.start_addr) ..
    mk_word(xact.bit_count)

  if is_rtu(xact) then
    req = req .. mk_word_le(calc_crc16(req))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(req)
  end

  return req
end

-------------------------------------------------------------------------------

local function parse_request_read_coils(xact, req)

  local req_size = adu_extra_size(xact) + 5

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  xact.start_addr = word_at(req, adu_header_size(xact) + 1)
  xact.bit_count = word_at(req, adu_header_size(xact) + 3)

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_read_coils(xact)

  -- TODO check request, e.g. coil count

  local byte_count = calc_byte_count(#xact.bits)

  local resp = new_adu(xact) ..
    string.char(funcs.READ_COILS) ..
    string.char(byte_count)

  local byte = 0
  for i = 0, xact.bit_count - 1 do
    if xact.bits[i + 1] == 1 then
      byte = bor(byte, blshift(1, i % 8))
    end
    if (i ~= 0 and i % 8 == 0) or (i == xact.bit_count - 1) then
      resp = resp .. byte
      byte = 0
    end
  end

  if is_rtu(xact) then
    resp = resp .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    resp = fix_mbap_length(resp)
  end

  return true, resp
end

-------------------------------------------------------------------------------

local function parse_response_read_coils(xact, resp)

  local resp_lead_size = adu_header_size(xact) + 2

  if #resp < resp_lead_size then
    return false, stat.NOT_COMPLETED
  end

  local bc = response_byte_count(xact, resp)
  local resp_size = resp_lead_size + bc + crc_size(xact)

  if #resp < resp_size then
    -- didn't get the whole response
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  if is_tcp(xact) and get_mbap_length(resp) ~= bc + 3 then
    return false, stat.INVALID_RESPONSE
  end

  if calc_byte_count(xact.bit_count) ~= bc then
    -- the response data size does not match the request coil count
    return false, stat.INVALID_RESPONSE
  end

  xact.bits = {}

  local byte = 0
  for i = 0, xact.bit_count - 1 do
    if i % 8 == 0 then
      byte = byte_at(resp, resp_lead_size + math.floor(i / 8))
    end
    xact.bits[i + 1] = band(byte, blshift(1, i % 8)) ~= 0 and 1 or 0
  end

  return true, resp_size
end

-------------------------------------------------------------------------------
-- READ HOLDING REGISTERS
-------------------------------------------------------------------------------

local function build_request_read_holding_registers(xact)

  if not in_range(xact.word_count, 1, 125) then
    errorf("'word_count' value (%s) is not properly assigned or out of range 1..125",
      tostring(xact.word_count))
  end

  local req = new_adu(xact) ..
    string.char(funcs.READ_HOLDING_REGISTERS) ..
    mk_word(xact.start_addr) ..
    string.char(0, xact.word_count)

  if is_rtu(xact) then
    req = req .. mk_word_le(calc_crc16(req))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(req)
  end

  return req
end

-------------------------------------------------------------------------------

local function parse_request_read_holding_registers(xact, req)
  local req_size = adu_extra_size(xact) + 5

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  xact.start_addr = word_at(req, adu_header_size(xact) + 1)
  xact.word_count = word_at(req, adu_header_size(xact) + 3)

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_read_holding_registers(xact)

  -- TODO check request, e.g. register count

  local resp = new_adu(xact) ..
    string.char(funcs.READ_HOLDING_REGISTERS) ..
    string.char(#xact.words * 2)

  for i = 1, #xact.words do
    resp = resp .. mk_word(xact.words[i])
  end

  if is_rtu(xact) then
    resp = resp .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    resp = fix_mbap_length(resp)
  end

  return true, resp
end

-------------------------------------------------------------------------------

local function parse_response_read_holding_registers(xact, resp)
  local resp_lead_size = adu_header_size(xact) + 2

  if #resp < resp_lead_size then
    return false, stat.NOT_COMPLETED
  end

  local bc = response_byte_count(xact, resp)
  local resp_size = resp_lead_size + bc + crc_size(xact)

  if #resp < resp_size then
    -- didn't get the whole response
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  if is_tcp(xact) and get_mbap_length(resp) ~= bc + 3 then
    return false, stat.INVALID_RESPONSE
  end

  if xact.word_count * 2 ~= bc then
    -- the response data size does not match the request register count
    return false, stat.INVALID_RESPONSE
  end

  xact.words = {}
  for i = 1, xact.word_count do
    xact.words[i] = word_at(resp, resp_lead_size + (i - 1) * 2)
  end

  return true, resp_size
end

-------------------------------------------------------------------------------
-- READ INPUT REGISTERS
-------------------------------------------------------------------------------

local function build_request_read_input_registers(xact)

  if not in_range(xact.word_count, 1, 125) then
    errorf("'word_count' value (%s) is not properly assigned or out of range 1..125",
      tostring(xact.word_count))
  end

  local req = new_adu(xact) ..
    string.char(funcs.READ_INPUT_REGISTERS) ..
    mk_word(xact.start_addr) ..
    string.char(0, xact.word_count)

    if is_rtu(xact) then
      req = req .. mk_word_le(calc_crc16(req))
    end

    if is_tcp(xact) then
      req = fix_mbap_length(req)
    end

    return req
end

-------------------------------------------------------------------------------

local function parse_request_read_input_registers(xact, req)
  local req_size = adu_extra_size(xact) + 5

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  xact.start_addr = word_at(req, adu_header_size(xact) + 1)
  xact.word_count = word_at(req, adu_header_size(xact) + 3)

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_read_input_registers(xact)

  -- TODO check request, e.g. register count

  local req = new_adu(xact) ..
    string.char(funcs.READ_INPUT_REGISTERS) ..
    string.char(#xact.words * 2)

  for i = 1, #xact.words do
    resp = resp .. mk_word(xact.words[i])
  end

  if is_rtu(xact) then
    resp = req .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(resp)
  end

  return true, resp
end

-------------------------------------------------------------------------------

local function parse_response_read_input_registers(xact, resp)
  local resp_lead_size = adu_header_size(xact) + 2;

  if #resp < resp_lead_size then
    return false, stat.NOT_COMPLETED
  end

  local bc = response_byte_count(xact, resp)
  local resp_size = bc + resp_lead_size + crc_size(xact)

  if #resp < resp_size then
    -- didn't get the whole response
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  if is_tcp(xact) and get_mbap_length(resp) ~= bc + 3 then
    return false, stat.INVALID_RESPONSE
  end

  if xact.word_count * 2 ~= bc then
    -- the response data size does not match the request register count
    return false, stat.INVALID_RESPONSE
  end

  xact.words = {}
  for i = 1, xact.word_count do
    xact.words[i] = word_at(resp, resp_lead_size + (i - 1) * 2)
  end

  return true, resp_size
end

-------------------------------------------------------------------------------
-- WRITE MULTIPLE REGISTERS
-------------------------------------------------------------------------------

local function build_request_write_multiple_registers(xact)

  if not xact.words or not in_range(#xact.words, 1, 123) then
    error("'words' value is not properly assigned or out of range 1..125")
  end

  local req = new_adu(xact)..
    string.char(funcs.WRITE_MULTIPLE_REGISTERS) ..
    mk_word(xact.start_addr) ..
    mk_word(#xact.words) ..
    string.char(#xact.words * 2)

  for i = 1, #xact.words do
    req = req .. mk_word(xact.words[i])
  end

  if is_rtu(xact) then
    req = req .. mk_word_le(calc_crc16(req))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(req)
  end

  return req
end

-------------------------------------------------------------------------------

local function parse_request_write_multiple_registers(xact, req)
  local req_lead_size = adu_header_size(xact) + 6

  if #req < req_lead_size then
    return false, stat.NOT_COMPLETED
  end

  local word_count = request_item_count(xact, req)

  local bc = byte_at(req, adu_header_size(xact) + 5)

  if word_count * 2 ~= bc then
    return false, stat.INVALID_REQUEST
  end

  local req_size = req_lead_size + bc + crc_size(xact)

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  xact.start_addr = word_at(req, adu_header_size(xact) + 1)

  local word_count = word_at(req, adu_header_size(xact) + 3)

  xact.words = {}

  for i = 1, word_count do
    xact.words[i] = word_at(req, 6 + (i - 1) * 2)
  end

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_write_multiple_registers(xact)

  -- TODO check request, e.g. register count

  local resp = new_adu(xact)..
    string.char(funcs.WRITE_MULTIPLE_REGISTERS) ..
    mk_word(xact.start_addr) ..
    mk_word(#xact.words)

  if is_rtu(xact) then
    resp = resp .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    resp = fix_mbap_length(resp)
  end

  return true, resp
end

-------------------------------------------------------------------------------

local function parse_response_write_multiple_registers(xact, resp)
  local resp_size = 5 + adu_extra_size(xact)

  if #resp < resp_size then
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  if is_tcp(xact) and get_mbap_length(resp) ~= 6 then
    return false, stat.INVALID_RESPONSE
  end

  if xact.start_addr ~= word_at(resp, adu_header_size(xact) + 1) or
     #xact.words ~= word_at(resp, adu_header_size(xact) + 3) then
    return false, stat.INVALID_RESPONSE;
  end

  return true, resp_size
end

-------------------------------------------------------------------------------
-- REPORT SLAVE ID
-------------------------------------------------------------------------------

local function build_request_report_slave_id(xact)

  local req = new_adu(xact).. string.char(funcs.REPORT_SLAVE_ID)

  if is_rtu(xact) then
    req = req .. mk_word_le(calc_crc16(req))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(req)
  end

  return req
end

-------------------------------------------------------------------------------

local function parse_request_report_slave_id(xact, req)
  local req_size = adu_extra_size(xact) + 1

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_report_slave_id(xact)

  local resp = new_adu(xact)..
    string.char(funcs.REPORT_SLAVE_ID) ..
    string.char(#xact.slave_id) ..
    xact.slave_id

  if is_rtu(xact) then
    resp = resp .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    resp = fix_mbap_length(resp)
  end

  return true, resp
end

-------------------------------------------------------------------------------

local function parse_response_report_slave_id(xact, resp)
  local resp_lead_size = adu_header_size(xact) + 2;

  if #resp < resp_lead_size then
    return false, stat.NOT_COMPLETED
  end

  local resp_size = response_byte_count(resp) + resp_lead_size + crc_size(xact)

  if #resp < resp_size then
      -- didn't get the whole response
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  xact.slave_id = resp:sub(resp_lead_size, -1 - crc_size(xact))

  return true, resp_size
end

-------------------------------------------------------------------------------
-- MASK WRITE REGISTER
-------------------------------------------------------------------------------

local function build_request_mask_write_register(xact)

  local req = new_adu(xact)..
    string.char(funcs.MASK_WRITE_REGISTER) ..
    mk_word(xact.start_addr) ..
    mk_word(xact.and_mask) ..
    mk_word(xact.or_mask)

  if is_rtu(xact) then
    req = req .. mk_word_le(calc_crc16(req))
  end

  if is_tcp(xact) then
    req = fix_mbap_length(req)
  end

  return req
end

-------------------------------------------------------------------------------

local function parse_request_mask_write_register(xact, req)
  local req_start = adu_header_size(xact)
  local req_size = req_start + 7 + crc_size(xact)

  if #req < req_size then
    return false, stat.NOT_COMPLETED
  end

  -- TODO check crc

  xact.start_addr = word_at(req, req_start + 1)
  xact.and_mask = word_at(req, req_start + 3)
  xact.or_mask = word_at(req, req_start + 5)

  return true, req_size
end

-------------------------------------------------------------------------------

local function build_response_mask_write_register(xact)

  local resp = new_adu(xact)..
    string.char(funcs.MASK_WRITE_REGISTER) ..
    mk_word(xact.start_addr) ..
    mk_word(xact.and_mask) ..
    mk_word(xact.or_mask)

  if is_rtu(xact) then
    resp = resp .. mk_word_le(calc_crc16(resp))
  end

  if is_tcp(xact) then
    resp = fix_mbap_length(resp)
  end

  return resp
end

-------------------------------------------------------------------------------

local function parse_response_mask_write_register(xact, resp)
  local resp_start = adu_header_size(xact)
  local resp_size = resp_start + 7 + crc_size(xact)

  if #resp < resp_size then
    return false, stat.NOT_COMPLETED
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  if xact.start_addr ~= word_at(resp, resp_start + 1) or
     xact.and_mask ~= word_at(resp, resp_start + 3) or
     xact.or_mask ~= word_at(resp, resp_start + 5) then
    return false, stat.INVALID_RESPONSE
  end

  return true, resp_size
end

-------------------------------------------------------------------------------

local function parse_response_exception(xact, resp)
  local resp_size = 2 + adu_extra_size(xact)

  if #resp < resp_size then
    return false, stat.NOT_COMPLETED
  end

  if is_tcp(xact) and get_mbap_length(resp) ~= 6 then
    return false, stat.INVALID_RESPONSE
  end

  if is_rtu(xact) and not check_crc16(resp) then
    return false, stat.CRC_ERROR
  end

  xact.error = byte_at(resp, adu_header_size(xact) + 1)

  return true, resp_size
end

-------------------------------------------------------------------------------

local function get_local_var(name)
  local i = 1

  while true do
    local n, v = debug.getlocal(2, i)
    if n == name then
      return v
    elseif not n then
      break
    end
    i = i + 1
  end

  errorf("'%s' is not defined", name)
end

-------------------------------------------------------------------------------

  local func_info = {}

  for k, v in pairs(funcs) do
    func_info[v] = {
      name = k,
      build_request = get_local_var('build_request_' .. k:lower()),
      parse_request = get_local_var('parse_request_' .. k:lower()),
      build_response = get_local_var('build_response_' .. k:lower()),
      parse_response = get_local_var('parse_response_' .. k:lower()),
    }
  end

-------------------------------------------------------------------------------

local function get_func(src)
  local func

  if type(src) == 'table' then
    -- src is a transaction
    func = src.func
  else
    func = src
  end

  if type(func) == 'string' then
    func = funcs[func]
  end

  -- check if supported
  if type(func) == 'number' and func_info[func] then
    return func
  end

  return nil
end

-------------------------------------------------------------------------------

local function build_request(xact)

  local func = get_func(xact)

  if func then

    func = func_info[func]

    -- TODO check_set_defaults
    if not xact.type then
      xact.type = 'RTU'
    end

    if is_rtu(xact) and not xact.server_addr then
      xact.server_addr = 1
    end

    if is_tcp(xact) then
      if not xact.server_addr then
        xact.server_addr = 1
      end
      if not xact.transact_id then
        xact.transact_id = 0
      end
    end

    return func.build_request(xact)
  end

  errorf("'func' value (%s) is not properly assigned or is not supported",
    tostring(xact.func))

end

-------------------------------------------------------------------------------

local function parse_request(xact, req)

  if not xact.type or not adu_header_size(xact) then
    -- check type validity
    errorf("'type' value (%s) is not properly assigned or is not supported",
      tostring(xact.type))
  end

  if #req < min_request_size(xact) then
    return false, stat.NOT_COMPLETED
  end

  local fn = byte_at(req, func_ofs(xact))
  local func = func_info[fn]

  -- TODO if it's is a TCP request, we already know its size at this point
  -- and can wait until the whole request arrives

  if func then
    xact.func = fn

    if is_rtu(xact) then
      xact.server_addr = byte_at(req, 0)
    elseif is_tcp(xact) then
      xact.transact_id = word_at(req, 0)
      xact.server_addr = byte_at(req, 6)
    end

    return func.parse_request(xact, req)
  end

  return false, stat.FUNC_NOT_SUPPORTED
end

-------------------------------------------------------------------------------

local function build_response(xact)
  local func = get_func(xact)

  if func then

    func = func_info[func]

    -- TODO check_set_defaults
    if not xact.type then
      xact.type = 'RTU'
    end

    if is_rtu(xact) and not xact.server_addr then
      xact.server_addr = 1
    end

    if is_tcp(xact) then
      if not xact.server_addr then
        xact.server_addr = 1
      end
      if not xact.transact_id then
        xact.transact_id = 0
      end
    end

    return func.build_response(xact)
  end

  errorf("'func' value (%s) is not properly assigned or is not supported",
    tostring(xact.func))
end

-------------------------------------------------------------------------------

local function parse_response(xact, resp)

  if not xact.type or not adu_header_size(xact) then
    -- check type validity
    errorf("'type' value (%s) is not properly assigned or is not supported",
      tostring(xact.type))
  end

  if #resp < min_response_size(xact) then
    return false, stat.NOT_COMPLETED
  end

  local fn = byte_at(resp, func_ofs(xact))

  local err

  if band(fn, 0x80) ~= 0 then
    err = true
    fn = band(fn, 0x7F)
  else
    err = false
  end

  if get_func(fn) then
    if fn == get_func(xact) then
      if err then
        return parse_response_exception(xact, resp)
      else
        xact.error = nil
        return func_info[fn].parse_response(xact, resp)
      end
    else
      return false, stat.INVALID_RESPONSE
    end
  end

  return false, stat.FUNC_NOT_SUPPORTED
end

-------------------------------------------------------------------------------

local function func_str(func)
  return func_info[func] and func_info[func].name or 'Unsupported function '
    .. tostring(func)
end

-------------------------------------------------------------------------------

  local ret = {
    build_request = build_request,
    parse_request = parse_request,
    build_response = build_response,
    parse_response = parse_response,
    func_str = func_str,
  }

  for k, v in pairs(types) do
    ret['TYPE_' .. k] = v
  end

  for k, v in pairs(funcs) do
    ret['FUNC_' .. k] = v
  end

  for k, v in pairs(stat) do
    ret['STAT_' .. k] = v
  end

  return ret
