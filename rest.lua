-- json package from http://json.luaforge.net/
-- socket package http://www.tecgraf.puc-rio.br/~diego/professional/luasocket/
-- date package http://luaforge.net/projects/date/
-- 
-- Inspiration come from http://www.digitalhobbit.com/2008/05/25/rails-21-and-incoming-json-requests/
--   curl -H "Content-Type:application/json" -H "Accept:application/json" -d "{\"passcode\":{\"pin\":\"0001\"}}"  http://localhost:3000/passcodes

local debug=true

require 'json'
require 'date'
local http = require("socket.http")

-- 'class' Database
Database = {
	host = "http://localhost:3001"
}

function Database:get(resource,id)
	local chunks = {}
	url = Database.host.."/"..resource..'/'..id..'.json'
	ret, code, head = http.request(
		{ ['url'] = url,
			method = 'GET',
			sink = ltn12.sink.table(chunks)
		}
	)
	if 200==code then
		local data = json.decode(chunks[1]) -- fix
		return data, code
	else
		return nil, code
	end
end

-- Put into the resource, this object and returns the created object, with appropriate Ids.
-- If some field is missing, then database will use the defaults.
-- Returns: newly object, return code, 
function Database:create(resource, object)
	local url = Database.host.."/"..resource
	local body = json.encode(object)
	if debug then print("DEBUG: Database:create(): body="..body) end
	local chunks = {}
	local ret, code, head = http.request(
		{ ['url'] = url,
			method = 'POST',
			headers = {  
				['Content-Type'] = 'application/json', 
				['Accept'] = 'application/json', 
				['content-length'] = body:len() 
			}, 
			source = ltn12.source.string(body), -- ltn12.source.table(chunks)
			sink = ltn12.sink.table(chunks)
		}
	)
	if debug then 
		if chunks and chunks[1] then
			print('DEBUG: Database:create(): chunks[1]='..chunks[1])
		end
		if ret then print('ret='..ret) end
		print('DEBUG: Database:create(): code='..code)
		print('DEBUG: Database:create(): head='..json.encode(head))
	end
	return chunks[1], code, head -- ret is always 1
end

-- Updates this collection
function Database:put(resource, object)
	local url = Database.host.."/"..resource
	local body = json.encode(object)
	local chunks = {}
	local ret, code, head = http.request(
		{ ['url'] = url,
			method = 'PUT',
			headers = {  
				['Content-Type'] = 'application/json', 
				['Accept'] = 'application/json', 
				['content-length'] = resource:len() 
			}, 
			source = ltn12.source.string(body), -- ltn12.source.table(chunks)
			sink = ltn12.sink.table(chunks)
		}
	)
	if debug then 
		if chunks and chunks[1] then
			print('chunks[1]='..chunks[1])
		end
		if ret then print('ret='..ret) end
		print('code='..code)
		print('head='..json.encode(head))
	end
	return chunks[1], code, head -- ret is always 1?
end
	

function tabledump(t,indent)
	local indent = indent or 0
	for k,v in pairs(t) do
		if type(v)=="table" then
			print(string.rep(" ",indent)..k.."=>")
			tabledump(v, indent+4)
		else
			print(string.rep(" ",indent) .. k  .. "=>" .. v)
		end
	end
end

local pass, code = Database:get('passcodes',1)
print('Database:get(passcodes,1):')
tabledump(pass)

local m, code = Database:create( 'passcodes', pass )
if nil == m then
	print("Failed! Code="..code)
	return
end

print(m)

