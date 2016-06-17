--
-- Cybermon configuration file, used to tailor the behaviour of cybermon.
--
-- This configuration file stores events in ElasticSearch.  The event
-- functions are all empty stubs.  Maybe a good starting point for building
-- your own config from scratch.
--

-- This file is a module, so you need to create a table, which will be
-- returned to the calling environment.  It doesn't matter what you call it.
local observer = {}

-- Other modules------------------------------------------------------------

local mime = require("mime")
local jsenc = require("json.encode")
local http = require("util.http")
local jsenc = require("json.encode")

-- Gaffer config -----------------------------------------------------------

-- Gaffer REST interface URL 
gaffer_base = "http://localhost:8080/example-rest/v1"

-- GeoIP -------------------------------------------------------------------

-- Open geoip module if it exists.
local geoip
status, rtn, geoip = pcall(function() return require("geoip.country") end)
if status then
  geoip = rtn
end 

-- Open geoip database if it exists.
local geodb
if geoip then
  geodb = geoip.open()
  print("Using GeoIP: " .. tostring(geodb))
end

-- Common data type URI ----------------------------------------------------

local cybtype = "http://cyberprobe.sf.net/type/"
local cybprop = "http://cyberprobe.sf.net/prop/"
local cybobj = "http://cyberprobe.sf.net/obj/"

local rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
local rdfs = "http://www.w3.org/2000/01/rdf-schema#"

-- Misc functions ----------------------------------------------------------

-- Base64 encoding
local b64 = function(x)
  local a, b = mime.b64(x)
  if (a == nil) then
    return ""
  end
  return a
end

-- Gaffer support ----------------------------------------------------------

-- This uses the Gaffer schema used at:
--    https://github.com/cybermaggedon/gaffer-tools.
-- However, rather than using the Redland API, comms are direct to the Gaffer
-- REST API.

-- Add edge to observation.
-- s=source e=edge d=destination tp=type (@n or @r).
local add_edge_basic = function(edges, s, e, d, tp)

  if not edges["elements"] then
    edges["elements"] = {}
  end

  local elt = {}
  elt["directed"] = true
  elt["class"] = "gaffer.data.element.Edge"
  elt["group"] = "BasicEdge"
  elt["source"] = s
  elt["destination"] = d
  elt["properties"] = {}
  elt["properties"]["name"] = {}
  elt["properties"]["name"]["gaffer.function.simple.types.FreqMap"] = {}
  elt["properties"]["name"]["gaffer.function.simple.types.FreqMap"][tp] = 1
  elt["properties"]["name"]["gaffer.function.simple.types.FreqMap"][e] = 1

  edges["elements"][#edges["elements"] + 1] = elt

end

-- Add an edge, with object type of URI.
-- s=subject, p=predicate, o=object
local add_edge_u = function(edges, s, p, o)
  add_edge_basic(edges, "n:u:" .. s, "r:u:" .. p, "n:u:" .. o, "@r")
  add_edge_basic(edges, "n:u:" .. s, "n:u:" .. o, "r:u:" .. p, "@n")
end

-- Add an edge, with object type of string.
-- s=subject, p=predicate, o=object
local add_edge_s = function(edges, s, p, o)
  add_edge_basic(edges, "n:u:" .. s, "r:u:" .. p, "n:s:" .. o, "@r")
  add_edge_basic(edges, "n:u:" .. s, "n:s:" .. o, "r:u:" .. p, "@n")
end

-- Add an edge, with object type of integer.
-- s=subject, p=predicate, o=object
local add_edge_i = function(edges, s, p, o)
  add_edge_basic(edges, "n:u:" .. s, "r:u:" .. p, "n:i:" .. math.floor(o), "@r")
  add_edge_basic(edges, "n:u:" .. s, "n:i:" .. math.floor(o), "r:u:" .. p, "@n")
end

-- Add an edge, with object type of xsd:dateTime.
-- s=subject, p=predicate, o=object
local add_edge_dt = function(edges, s, p, o)
  add_edge_basic(edges, "n:u:" .. s, "r:u:" .. p, "n:d:" .. o, "@r")
  add_edge_basic(edges, "n:u:" .. s, "n:d:" .. o, "r:u:" .. p, "@n")
end

-- Submit a set of edges to the Gaffer REST API.
local submit_edges = function(edges)
  local c = http.http_req(gaffer_base .. "/graph/doOperation/add/elements",
  	                  "PUT", jsenc.encode(edges),
			  "application/json")
  print(c)
end

local init = function()

  edges = {}

  add_edge_u(edges, cybtype .. "observation", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "observation", rdfs .. "label",
             "Observation")

  add_edge_u(edges, cybtype .. "liid", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "liid", rdfs .. "label",
             "LIID")

  add_edge_u(edges, cybprop .. "method", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "method", rdfs .. "label",
             "Method")

  add_edge_u(edges, cybprop .. "action", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "action", rdfs .. "label",
             "Action")

  add_edge_u(edges, cybprop .. "code", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "code", rdfs .. "label",
             "Response code")

  add_edge_u(edges, cybprop .. "status", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "status", rdfs .. "label",
             "Response status")

  add_edge_u(edges, cybprop .. "url", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "url", rdfs .. "label",
             "URL")

  add_edge_u(edges, cybprop .. "time", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybprop .. "time", rdfs .. "label",
             "Time of observation")

  -- Geo
  add_edge_u(edges, cybtype .. "country", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "country", rdfs .. "label",
             "Country of origin")

  -- Protocol context
  add_edge_u(edges, cybtype .. "context", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "context", rdfs .. "label",
             "Protocol context")

  -- For DNS
  
  add_edge_u(edges, cybprop .. "dns_type", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "dns_type", rdfs .. "label",
             "DNS type")

  add_edge_u(edges, cybprop .. "query", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "query", rdfs .. "label",
             "DNS query")

  add_edge_u(edges, cybprop .. "answer_name", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "answer_name", rdfs .. "label",
             "Answer (name)")

  add_edge_u(edges, cybprop .. "answer_address", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "answer_address", rdfs .. "label",
             "Answer (address)")

  -- Addresses

  add_edge_u(edges, cybprop .. "source", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "source", rdfs .. "label",
             "Source address")

  add_edge_u(edges, cybprop .. "dest", rdf .. "type",
             rdfs .. "Property")
  add_edge_s(edges, cybprop .. "dest", rdfs .. "label",
             "Destination address")

  add_edge_u(edges, cybtype .. "ipv4", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "ipv4", rdfs .. "label",
             "IPv4 address")

  add_edge_u(edges, cybtype .. "tcp", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "tcp", rdfs .. "label",
             "TCP port")

  add_edge_u(edges, cybtype .. "udp", rdf .. "type",
             rdfs .. "Resource")
  add_edge_s(edges, cybtype .. "udp", rdfs .. "label",
             "UDP port")

  submit_edges(edges)

end

local next_id = 0

local get_next_id = function()
  local id = next_id
  next_id = next_id + 1
  return id
end

-- Gets the stack of addresses on the src/dest side of a context.
local function get_stack(context, addrs, is_src)

  local par = context:get_parent()

  if par then
    get_stack(par, addrs, is_src)
  end

  local cls, addr
  if is_src then
    cls, addr = context:get_src_addr()
  else
    cls, addr = context:get_dest_addr()
  end

  -- FIXME: This is all very IPv4-centric.
  if cls == "ipv4" then
    local p = {}
    p["id"] = cybobj .. "ipv4/" .. addr
    p["type"] = cybtype .. "ipv4"
    p["description"] = addr
    p["ipv4"] = addr

    if geodb then
      lookup = geodb:query_by_addr(addr)
      if lookup and lookup.code and not(lookup.code == "--") then
        p["geo"] = lookup.code
      end
    end

    table.insert(addrs, p)
  end

  if cls == "tcp" then
    local p = {}

    local ipv4 = "unknown"
    for i, v in ipairs(addrs) do
      if v.ipv4 then ipv4 = v.ipv4 end
    end

    p["id"] = cybobj .. "tcp/" .. ipv4 .. ":" .. addr
    p["type"] = cybtype .. "tcp"
    p["description"] = ipv4 .. ":" .. addr
    p["context"] = cybobj .. "ipv4/" .. ipv4
    table.insert(addrs, p)

  end

  if cls == "udp" then
    local p = {}

    local ipv4 = "unknown"
    for i, v in ipairs(addrs) do
      if v.ipv4 then ipv4 = v.ipv4 end
    end

    p["id"] = cybobj .. "udp/" .. ipv4 .. ":" .. addr
    p["type"] = cybtype .. "udp"
    p["description"] = ipv4 .. ":" .. addr
    p["context"] = cybobj .. "ipv4/" .. ipv4
    table.insert(addrs, p)

  end

  return addrs
end

-- Initialise a basic observation
local create_basic = function(edges, context, action)

  local id = get_next_id()
  local uri = cybobj .. "obs/" .. id
  add_edge_u(edges, uri, rdf .. "type", cybtype .. "observation")

  local liid = cybobj .. "liid/" .. context:get_liid()
  add_edge_u(edges, uri, cybprop .. "liid", liid)
  add_edge_u(edges, liid, rdf .. "type", cybtype .. "liid")
  add_edge_s(edges, liid, rdfs .. "label", "LIID " .. context:get_liid())

  add_edge_s(edges, uri, cybprop .. "action", action)

  addrs = {}
  get_stack(context, addrs, true)
  for key, value in pairs(addrs) do
    add_edge_u(edges, value.id, rdf .. "type", value.type)
    add_edge_s(edges, value.id, rdfs .. "label", value.description)
    if value.geo then
      add_edge_s(edges, value.id, cybprop .. "geo", value.geo)
    end
    if value.context then
      add_edge_u(edges, value.id, cybprop .. "context", value.context)
    end
    add_edge_u(edges, uri, cybprop .. "source", value.id)
  end

  addrs = {}
  get_stack(context, addrs, false)
  for key, value in pairs(addrs) do
    add_edge_u(edges, value.id, rdf .. "type", value.type)
    add_edge_s(edges, value.id, rdfs .. "label", value.description)
    if value.geo then
      add_edge_s(edges, value.id, cybprop .. "geo", value.geo)
    end
    if value.context then
      add_edge_u(edges, value.id, cybprop .. "context", value.context)
    end
    add_edge_u(edges, uri, cybprop .. "dest", value.id)
  end
  
  local tm = context:get_event_time()
  local tmstr = os.date("!%Y%m%dT%H%M%S", math.floor(tm))
  local millis = 1000 * (tm - math.floor(tm))

  tmstr = tmstr .. "." .. string.format("%03dZ", math.floor(millis))

  add_edge_dt(edges, uri, cybprop .. "time", tmstr)

  return uri

end

-- This function is called when a trigger events starts collection of an
-- attacker. liid=the trigger ID, addr=trigger address
observer.trigger_up = function(liid, addr)
end

-- This function is called when an attacker goes off the air
observer.trigger_down = function(liid)
end

-- This function is called when a stream-orientated connection is made
-- (e.g. TCP)
observer.connection_up = function(context)
end

-- This function is called when a stream-orientated connection is closed
observer.connection_down = function(context)
end

-- This function is called when a datagram is observed, but the protocol
-- is not recognised.
observer.unrecognised_datagram = function(context, data)
  local edges = {}
  local id = create_basic(edges, context, "unrecognised_datagram")
  add_edge_s(edges, id, cybprop .. "data", b64(data))
  add_edge_s(edges, id, rdfs .. "label", "unrecognised datagram")
  submit_edges(edges)
end

-- This function is called when stream data  is observed, but the protocol
-- is not recognised.
observer.unrecognised_stream = function(context, data)
  local edges = {}
  local id = create_basic(edges, context, "unrecognised_stream")
  add_edge_s(edges, id, cybprop .. "data", b64(data))
  add_edge_s(edges, id, rdfs .. "label", "unrecognised stream")
  submit_edges(edges)
end

-- This function is called when an ICMP message is observed.
observer.icmp = function(context, data)
  local edges = {}
  local id = create_basic(edges, context, "icmp")
  add_edge_s(edges, id, cybprop .. "data", b64(data))
  add_edge_s(edges, id, rdfs .. "label", "ICMP")
  submit_edges(edges)
end

-- This function is called when an HTTP request is observed.
observer.http_request = function(context, method, url, header, body)
  local edges = {}
  local id = create_basic(edges, context, "http_request")
  add_edge_s(edges, id, cybprop .. "method", method)
  add_edge_u(edges, id, cybprop .. "url", url)
  for key, value in pairs(header) do
    add_edge_s(edges, id, cybprop .. "header:" .. key, value)
  end
  if (body and not body == "") then
    add_edge_s(edges, id, cybprop .. "body", b64(body))
  end
  add_edge_s(edges, id, rdfs .. "label", "HTTP " .. method .. " " .. url)
  submit_edges(edges)
end

-- This function is called when an HTTP response is observed.
observer.http_response = function(context, code, status, header, url, body)
  local edges = {}
  local id = create_basic(edges, context, "http_response")
  add_edge_s(edges, id, cybprop .. "code", code)
  add_edge_s(edges, id, cybprop .. "status", status)
  add_edge_u(edges, id, cybprop .. "url", url)
  for key, value in pairs(header) do
    add_edge_s(edges, id, cybprop .. "header:" .. key, value)
  end
  body = b64(body)
  if (body) then
    add_edge_s(edges, id, cybprop .. "body", body)
  end
  -- If there's an image payload, use the payload as the thumbnail
  if header["Content-Type"] then
    if string.sub(header["Content-Type"], 1, 6) == "image/" then
      add_edge_u(edges, id, "http://dbpedia.org/ontology/thumbnail",
                 "data:" .. header["Content-Type"] .. ";base64," .. body)
    end
  end
  add_edge_s(edges, id, rdfs .. "label",
             "HTTP " .. code .. " " .. status .. " " .. url)
  submit_edges(edges)
end


-- This function is called when a DNS message is observed.
observer.dns_message = function(context, header, queries, answers, auth, add)
  local edges = {}
  local id = create_basic(edges, context, "dns_message")

  local label = ""
  
  if header.qr == 0 then
    add_edge_s(edges, id, cybprop .. "dns_type", "DNS query")
    label = "query"
  else
    add_edge_s(edges, id, cybprop .. "dns_type", "DNS answer")
    label = "answer"
  end

  for key, value in pairs(queries) do
    add_edge_s(edges, id, cybprop .. "query", value.name)
    label = label .. " " .. value.name
  end

  for key, value in pairs(answers) do
    add_edge_s(edges, id, cybprop .. "answer_name", value.name)
    if value.rdaddress then
       add_edge_s(edges, id, cybprop .. "answer_address",
                  value.rdaddress)
    end
    if value.rdname then
       add_edge_s(edges, id, cybprop .. "answer_name",
                            value.rdname)
    end
  end
  submit_edges(edges)
end


-- This function is called when an FTP command is observed.
observer.ftp_command = function(context, command)
  local edges = {}
  local id = create_basic(edges, context, "ftp_command")
  add_edge_s(edges, id, cybprop .. "command", command)
  add_edge_s(edges, id, rdfs .. "label", "FTP " .. command)
  submit_edges(edges)
end

-- This function is called when an FTP response is observed.
observer.ftp_response = function(context, status, text)
  local edges = {}
  local id = create_basic(edges, context, "ftp_response")
  add_edge_s(edges, id, cybprop .. "status", status)
  add_edge_s(edges, id, cybprop .. "text", text)
  add_edge_s(edges, id, rdfs .. "label", "FTP " .. status)
  submit_edges(edges)
end

-- Initialise
init()

-- Return the table
return observer
