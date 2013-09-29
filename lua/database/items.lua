local items = {}

function getItems( name )
	if items[name] then
		return items[name]
	end
	return false
end

items["scrap1"] = 	{
					name = "Old Scrap",
					desc = "Some old scrap, not worth much",
					ent = "item_basic",
					price = {
						buy = 3,
						sell = 1,
					},
					model = "models/props_junk/PopCan01a.mdl",
					use = (function(ply, ent)
						if ply:IsValid() then
							ply:SetHealth( ply:Health() + 2 )
							if ent then
								ent:Remove()
							end
						end
					end),
					spawn = (function(ply, ent)
						ent:SetItemName( "Scrap" )
					end),
					skin = 0,
					buttonDist = 32,
					}

items["scrap2"] = 	{
					name = "Good Scrap",
					desc = "Better quality and worth a bit more!",
					ent = "item_basic",
					price = {
						buy = 15,
						sell = 10,
					},
					model = "models/props_junk/PopCan01a.mdl",
					use = (function(ply, ent)
						if ply:IsValid() then
							ply:SetHealth( ply:Health() + 2 )
							if ent then
								ent:Remove()
							end
						end
					end),
					spawn = (function(ply, ent)
						ent:SetItemName( "Scrap" )
					end),
					skin = 1,
					buttonDist = 32,
					}
					
items["scrap3"] = 	{
					name = "Fine Scrap",
					desc = "Better quality scrap, worth much more!",
					ent = "item_basic",
					price = {
						buy = 50,
						sell = 35,
					},
					model = "models/props_junk/PopCan01a.mdl",
					use = (function(ply, ent)
						if ply:IsValid() then
							ply:SetHealth( ply:Health() + 2 )
							if ent then
								ent:Remove()
							end
						end
					end),
					spawn = (function(ply, ent)
						ent:SetItemName( "Scrap" )
					end),
					skin = 2,
					buttonDist = 32,
					}