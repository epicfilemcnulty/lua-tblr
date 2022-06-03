local term = require("plterm")

local _M = {}

_M.get_screen_dimensions = function()
	mode = term.savemode()
	term.setrawmode()
	l, c = term.getscrlc()
	term.restoremode(mode)
	return l, c
end

local add_to_row = function(self, row, tbl)
	if not self.rows[row] then
		self.rows[row] = {}
	end

	local x, y = 2, 2
	if row > 1 then
		for i = 1, row - 1 do
			local row_height = 0
			for _, t in ipairs(self.rows[i]) do
				local _, _, _, _, height = table.unpack(t.tbl:dimensions())
				if height > row_height then
					row_height = height
				end
			end
			y = y + row_height + self.y_margin
		end
	end

	if #self.rows[row] > 0 then
		for i, t in ipairs(self.rows[row]) do
			local _, _, _, width = table.unpack(t.tbl:dimensions())
			x = x + width + self.x_margin
		end
	end

	table.insert(self.rows[row], {
		x = x,
		y = y,
		tbl = tbl,
	})
	-- return the position of the inserted table
	return { row, #self.rows[row] }
end

local fits_in_row = function(self, row, tbl)
	local _, _, _, width = table.unpack(tbl:dimensions())
	if width > self.x then
		return false
	end
	if not self.rows[row] then
		return false
	end
	local occupied = 0
	for i, t in ipairs(self.rows[row]) do
		local _, _, _, width = table.unpack(t.tbl:dimensions())
		occupied = occupied + width + 1
	end
	return occupied + width <= self.x
end

local print_all = function(self)
	for _, r in ipairs(self.rows) do
		for _, t in ipairs(r) do
			t.tbl:print(t.x, t.y)
		end
	end
end

_M.create = function()
	local page = {
		x,
		y = _M.get_screen_dimensions(),
		x_margin = 2,
		y_margin = 0,
		rows = {},
		add_to_row = add_to_row,
		print_all = print_all,
		fits_in_row = fits_in_row,
		selected_tbl = { 0, 0 },
	}
	return page
end

return _M
