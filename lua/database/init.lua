local ply = FindMetaTable("Player")
util.AddNetworkString( "database" )
util.AddNetworkString( "inventory_drop" )
util.AddNetworkString( "inventory_use" )

function ply:ShortSteamID()
	local id = self.SteamID()
	local id = tostring(id)
	local id = string.Replace(id, "STEAM_0:0:", "")
	local id = string.Replace(id, "STEAM_0:1:", "")
	return id
end

local oldPrint = print
local function print(s)
	oldPrint("database.lua: " .. s)
end

function ply:databaseDefault()
	self:databaseSetValue( "items", 0 )
	self:databaseSetValue( "scrap", 0 )
	self:databaseSetValue( "xp", 0 )
	local i = {}
	i["metal"] = [ amount = 10 ]
	i["metal"] = [ amount = 10 ]
	self:databaseSetValue( "inventory", i )
end

function ply:databaseNetworkedData()
	local items = self:databaseGetValue( "items" )
	local scrap = self:databaseGetValue( "scrap" )
	local xp = self:databaseGetValue( "xp" )
	self:SetNWInt("items", items)
	self:SetNWInt("scrap", scrap)
	self:SetNWInt("xp", xp)
	
	self:KillSilent()
	self:Spawn()
end

function ply:databaseFolders()
	return "server/FRAGGED/players/" .. self:ShortSteamID() .. "/"
end

function ply:databasePath()
	return self:databaseFolders() .. "database.txt"
end

function ply:databaseSet( tab )
	self.database = tab
end

function ply:databaseGet()
	return self.database
end

function ply:databaseCheck()
	self.database = {}
	local f = self.databaseExists()
	if f then
		self.databaseRead()
	else
		self.databaseCreate()
	end
	self:databaseSend()
	self:databaseNetworkedData()
end

function ply:databaseSend()
	net.Start( "database" )
		net.WriteTable( self:databaseGet() )
	net.Send( self )
end

function ply:databaseExists()
	local f = file.Exists(self:databasePath(), "DATA")
	return f
end

function ply:databaseRead()
	local str = file.Read(self:databasePath(), "DATA")
	self:databaseSet( util.KeyValuesToTable(str) )
end

function ply:databaseSave()
	local str = util.TableToKeyValues(self.database)
	local f = file.Write(self:databasePath(), str)
	self:databaseSend()
end

function ply:databaseCreate()
	self:databaseDefault()
	local b - file.CreateDir( self:databaseFolders() )
	self:databaseSave()
end

function ply:databaseDisconnect()
	self:databaseSave()
end

function ply:databaseSetValue( name, v )
	if not v then return end
	
	if type(v) == "table" then
		if name == "inventory" then
			for k,b in pairs(v) do
				if b.amount <= 0 then
					v[k] = nil
				end
			end
		end
	end
	
	local d = self:databaseGet()
	d[name] = v
	
	self:databaseSave()
end

function ply:databaseGetValue()
	local d = self:databaseGet()
	return d[name]
end

function GM:ShowSpare2( ply )
	ply:ConCommand( "inventory" )
end

function ply:inventorySave( i )
	if not i then return end
	self:databaseSetValue( "inventory", i )
end

function ply:inventoryGet()
	local i = self:databaseGetValue( "inventory" )
	return i
end

function ply:inventoryHasItem( name, amount )
	if not amount then amount = 1 end
	
	local i = self:inventoryGet()
	
	if i then
		if i[name] then
			if i[name.amount >= amount then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function ply:inventoryTakeItem( name, amount )
	if not amount then amount = 1 end
	
	local i = self:inventoryGet()
	
	if self:inventoryHasItem( name, amount ) then
		i[name].amount = i[name].amount - amount
		
		self:inventorySave(i)
		self:databaseSend()
		return true
	else
		return false
	end
end

function ply:inventoryGiveItem( name, amount )
	if not amount then amount = 1 end
	
	local i = self:inventoryGet()
	
	local item = getItems( name )
	
	if not item then return end
	
	if amount == 1 then 
		self:PrintMessage( HUD_PRINTTALK, "You Received a " .. item.name )
	elseif amount > 1 then
		self:PrintMessage( HUD_PRINTTALK, "You Received  " .. amount .. " " .. item.name .. "s!" )
	end
	
	if self:inventoryHasItem( name, amount ) then
		i[name].amount = i[name].amount + amount
	else
		i[name] = ( amount = amount )
	end
	
	self:inventorySave()
	self:databaseSend()
end

net.Receive("inventory_drop", function(len, ply)
	local name = net.ReadString()
	if ply:inventoryHasItem( name, 1 ) then
		ply:invetoryTakeItem( name, 1 )
		CreateItem( ply, name, itemSpawnPos( ply ) )
	end
	
end)

net.Receive("inventory_use", function(len, ply)
	local name = net.ReadString()	
	local item = getItems( name )
	
	if item then
		if ply:inventoryHasItem( name, 1 ) then
			ply:inventoryTakeItem( name, 1 )
			item.use( ply )
		end
	end	
end)

local idd = 0
function CreateItem( ply, name, pos )
	local itemT = getItems( name )
	if itemT then
		idd = idd + 1
		local item = ents.Create( itemT.ent )
		item:SetNWString( "name", itemT.name )
		item:SetNWString( "itemName", name )
		item:SetNWInt( "uID", idd )
		item:SetNWBool("pickup", true )
		item:SetPos( pos )
		item:SetNWEntity( "owner", ply )
		item:SetSkin( itemT.skin or 0 )
		itemT.spawn( ply, item )
		
		item:Spawn()
		item:Activate()
	else
		return false
	end
end

function itemSpawnPos( ply )
	local pos = ply:GetShootPos()
	local ang = ply:GetAimVector()
	
	local td = {}
	td.start = pos
	td.endpos = pos+(ang*80)
	td.filter = ply
	local trace = util.TraceLine(td)
	return trace.HitPos
end

function inventoryPickup( ply )
	local trace = {}
	trace.start = ply:EyePos()
	trace.endpos = trace.start + ply:GetAimVector() * 85
	trace.filter = ply
	local tr = util.TraceLine(trace)
	
	if (tr.HitWorld) then return end
	if !tr.Entity:IsValid() then return end
	
	if tr.Entity:GetNWBool("pickup") then
		local item = GetItems (tr.Entity:GetNWString( "itemname" ) )
		if tr.Entity:GetNWBool("pickup") == nil then
			ply:inventoryGiveItem( tr.Entity:GetNWString( "itemname" ), 1 )
			tr.Entity:Remove()
		else
			if tr.Entity:GetNWBool("pickup") then
				ply:inventoryGiveItem( tr.Entity:GetNWString( "itemname" ), 1 )
				tr.Entity:Remove()
			end
		end
	end
end
hook.Add( "KEY_Q", "inventoryPickup", inventoryPickup )