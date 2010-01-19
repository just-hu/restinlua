-- json package from http://json.luaforge.net/
-- socket package http://www.tecgraf.puc-rio.br/~diego/professional/luasocket/
-- date package http://luaforge.net/projects/date/
-- 
-- Inspiration come from http://www.digitalhobbit.com/2008/05/25/rails-21-and-incoming-json-requests/
--   curl -H "Content-Type:application/json" -H "Accept:application/json" -d "{\"passcode\":{\"pin\":\"0001\"}}"  http://localhost:3000/passcodes

local debug=false

require 'json'
require 'date'
local http = require("socket.http")

-- 'class' Database
Database = {
	-- host = "http://localhost:3001"
	host = "http://192.168.0.40"
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
	if debug then 
		if chunks and chunks[1] then
			print('DEBUG: Database:get(): chunks[1]='..chunks[1])
		end
		if ret then print('DEBUG: Database:create():  ret='..ret) end
		print('DEBUG: Database:get(): code='..code)
		print('DEBUG: Database:get(): head='..json.encode(head))
	end

	if nil~=chunks then
		return json.decode(chunks[1]), code, head
	else
		return nil, code, head
	end

end

-- Put into the resource, this object and returns the created object, with appropriate Ids.
-- If some field is missing, then database will use the defaults.
-- Returns: newly object, return code, 
-- SUccess: code=201
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
	-- show some debug info
	if debug then 
		if chunks and chunks[1] then
			print('DEBUG: Database:create(): chunks[1]='..chunks[1])
		end
		if ret then print('DEBUG: Database:create():  ret='..ret) end
		print('DEBUG: Database:create(): code='..code)
		print('DEBUG: Database:create(): head='..json.encode(head))
	end
	
	if nil==chunks then
		return nil, code, head
	else
		return json.decode(chunks[1]), code, head -- ret is always 1
	end
end

-- Updates this collection
function Database:put(resource, object)
	local url = Database.host.."/"..resource.."/"..object.id
	local body = json.encode(object)
	if debug then print("DEBUG: Database:put(): body="..body) end
	local chunks = {}
	local ret, code, head = http.request(
		{ ['url'] = url,
			method = 'PUT',
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
			print('DEBUG: Database:put(): chunks[1]='..chunks[1])
		end
		print('DEBUG: Database:put(): code='..code)
		print('DEBUG: Database:put(): head='..json.encode(head))
		print('DEBUG: Database:put():  ret='..ret)
	end
	if nil==chunks then 
		return nil, code, head
	else
		return object, code, head -- ret is always 1?
	end
end

-- Deletes a resource. 
-- On success, 200 is returned
function Database:delete(resource, id)
		local chunks = {}
		url = Database.host.."/"..resource..'/'..id..'.json'
		ret, code, head = http.request(
			{ ['url'] = url,
				method = 'DELETE',
				sink = ltn12.sink.table(chunks)
			}
		)
		if debug then 
			print('DEBUG: Database:delete(): code='..code)
			print('DEBUG: Database:delete(): head='..json.encode(head))
			print('DEBUG: Database:delete():  ret='..json.encode(ret))
		end
		return {}, code, head
	end

function tabledump(t,indent)
	-- if nil==t then return end
	assert(type(t)=='table', "Wrong input type. Expected table, got "..type(t))
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

-- Creates a new passcode 
print('=============== CREATE ================== ')
local r, code = Database:create('passcodes', { passcode = { pin = '1234' } })
print('  code='..code)
tabledump(r)
local id=r.passcode.id

print('=============== GET ================== ')
r, code = Database:get('passcodes', id)
print('  code='..code)
tabledump(r)

print('=============== PUT =================== ')
r.passcode.pin = '666'
r, code = Database:put( 'passcodes', r.passcode )
print("  code="..code)
-- tabledump(r)

print('=============== DELETE =================== ')
r, code = Database:delete('passcodes', id)
print('  code='..code)
tabledump(r)
