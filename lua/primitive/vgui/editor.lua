

----------------------------------------------------------------
local color_frame_1 = Color(75, 75, 75)
local color_label_disabled = Color(115, 115, 115)
local color_column_disabled = Color(240, 240, 240)
local color_strikethrough = Color(0, 0, 0)

local function PaintRow(self, w, h)
	if not IsValid(self.Inner) then return end

	local Skin = self:GetSkin()
	local editing = self.Inner:IsEditing()
	local disabled = not self.Inner:IsEnabled() or not self:IsEnabled()

	if disabled then
		surface.SetDrawColor(color_column_disabled)
		surface.DrawRect(w*0.45, 0, w, h)
		surface.DrawRect(0, 0, w*0.45, h)
		surface.SetDrawColor(color_strikethrough)
		surface.DrawLine(0, h*0.5, w, h*0.5)
	elseif editing then
		surface.SetDrawColor(Skin.Colours.Properties.Column_Selected)
		surface.DrawRect(0, 0, w*0.45, h)
	end

	surface.SetDrawColor(Skin.Colours.Properties.Border)
	surface.DrawRect(w - 1, 0, 1, h)
	surface.DrawRect(w*0.45, 0, 1, h)
	surface.DrawRect(0, h - 1, w, 1)

	if disabled then
		self.Label:SetTextColor(color_label_disabled)
	elseif editing then
		self.Label:SetTextColor(Skin.Colours.Properties.Label_Selected)
	else
		self.Label:SetTextColor(Skin.Colours.Properties.Label_Normal)
	end
end


----------------------------------------------------------------
local PANEL = {}

function PANEL:Init()
	self.PropertySheet = self:Add("DProperties")
	self.PropertySheet:Dock(FILL)

	self.PropertySheet.SetEntity = function(pnl, entity)
		if pnl.m_Entity == entity then
			return
		end
		pnl.m_Entity = entity
		pnl:RebuildControls()
	end

	self.PropertySheet.EntityLost = function(pnl)
		pnl:Clear()
		pnl:OnEntityLost()
	end

	self.PropertySheet.OnEntityLost = function(pnl)
		self:Remove()
	end

	self.PropertySheet.RebuildControls = function(pnl)
		pnl:Clear()

		if not IsValid(pnl.m_Entity) then return end
		if not isfunction(pnl.m_Entity.GetEditingData) then return end

		local editor = pnl.m_Entity:GetEditingData()

		local i = 1000
		for name, edit in pairs(editor) do
			if edit.order == nil then edit.order = i end
			i = i + 1
		end

		for name, edit in SortedPairsByMemberValue(editor, "order") do
			pnl:EditVariable(name, edit)
		end
	end

	self.PropertySheet.EditVariable = function(pnl, varname, editdata)
		if not istable(editdata) then return end
		if not isstring(editdata.type) then return end

		local row = pnl:CreateRow(editdata.category or "#entedit.general", editdata.title or varname)

		row:Setup(editdata.type, editdata)
		row.Paint = PaintRow

		row.DataUpdate = function(_)
			if not IsValid(pnl.m_Entity) then pnl:EntityLost() return end
			row:SetValue(pnl.m_Entity:GetNetworkKeyValue(varname))
			if editdata.enabled ~= nil and editdata.enabled ~= row:IsEnabled() then row:SetEnabled(editdata.enabled) end
		end

		row.DataChanged = function(_, val)
			if not IsValid(pnl.m_Entity) then pnl:EntityLost() return end
			pnl.m_Entity:EditValue(varname, tostring(val))
		end
	end

	self.btnMinim:Remove()
	self.btnMaxim:Remove()
	self.btnClose:SetText("r")
	self.btnClose:SetFont("Marlett")
	self.btnClose.Paint = function(pnl, w, h)
		derma.SkinHook("Paint", "Button", pnl, w, h)
	end
end


----------------------------------------------------------------
function PANEL:SetEntity(ent)
	self:SetTitle(tostring(ent))
	self.PropertySheet:SetEntity(ent)
end


----------------------------------------------------------------
function PANEL:PerformLayout()
	local titlePush = 0
	if IsValid(self.imgIcon) then
		self.imgIcon:SetPos(5, 5)
		self.imgIcon:SetSize(16, 16)
		titlePush = 16
	end

	local w, h = self:GetSize()

	self.btnClose:SetPos(w - 49, 3)
	self.btnClose:SetSize(45, 22)

	self.lblTitle:SetPos(6 + titlePush, 3)
	self.lblTitle:SetSize(w - 25 - titlePush, 22)
end


----------------------------------------------------------------
function PANEL:Paint(w, h)
	surface.SetDrawColor(color_frame_1)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0)
	surface.DrawOutlinedRect(0, 0, w, h)
end


----------------------------------------------------------------
vgui.Register("primitive_editor", PANEL, "DFrame")