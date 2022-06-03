local term = require("plterm")

--[[ Although plterm provides its own color function,
     I'd some glitches with it, so we are going to use
     this one instead. 
]]

local color = function(colors)
	local fg, bg, bold = table.unpack(colors)
	if fg then
		if fg == 0 then
			term.out("\027[39m")
		else
			term.out("\027[", fg, "m")
		end
	end
	if bg then
		if bg == 0 then
			term.out("\027[49m")
		else
			term.out("\027[", bg, "m")
		end
	end
	if bold then
		term.out("\027[", bold, "m")
	end
end

local _M = {}

_M.color = color
_M.create = function(headers, style, title)
	local tbl = {
		t = {},
		h = headers or {},
		title = title,
		style = style or function(col, val)
			return nil
		end,
		sort_column = 0,
		add_row = function(self, row)
			table.insert(self.t, row)
		end,
	}

	tbl.sort_by_column = function(self, c)
		local c = c or self.sort_column + 1
		if c > #self.h then
			c = 1
		end
		self.sort_column = c
		self.cmp_func = function(a, b)
			local x = tonumber(a[c])
			local y = tonumber(b[c])
			if x and y then
				return x < y
			else
				return a[c] < b[c]
			end
		end
		table.sort(self.t, self.cmp_func)
	end

	tbl.dimensions = function(self, margin)
		local margin = margin or 2
		local rows = #self.t
		local columns = #self.h
		if columns == 0 then
			columns = #self.t[1]
		end
		local col_widths = {}
		for i, c in ipairs(self.h) do
			table.insert(col_widths, #c)
		end
		for i, r in ipairs(self.t) do
			for p, c in ipairs(r) do
				if not col_widths[p] then
					col_widths[p] = 0
				end
				if #c > col_widths[p] then
					col_widths[p] = #c
				end
			end
		end
		local width = 1
		for _, w in ipairs(col_widths) do
			width = width + w + margin + 2
		end
		local height = rows + 1 -- lower border
		if #self.h > 0 then
			height = height + 3
		elseif self.title then
			height = height + 1
		end
		return { rows, columns, col_widths, width, height, margin }
	end

	tbl.print_borders = function(self, x, y, c)
		local c = c or { nil, nil, 2 }
		local _, _, col_widths, width, height, margin = table.unpack(self:dimensions())
		term.golc(y, x)
		color(c)
		if self.title then
			local space = width - #self.title
			local offset = math.ceil(space / 2)
			local suffix = width - (offset + #self.title)
			term.outf("." .. string.rep("~", offset - 2))
			term.right(#self.title + 2)
			term.outf(string.rep("~", suffix - 2) .. ".")
		else
			term.outf("." .. string.rep("—", width - 2) .. ".")
		end

		for i = y + 1, y + height - 2 do
			term.golc(i, x)
			term.outf("|")
			term.golc(i, x + width - 1)
			term.outf("|")
		end
		term.golc(y + height - 1, x)
		term.outf("*" .. string.rep("—", width - 2) .. "*")
		color({ 0, 0, 0 })
	end

	tbl.print = function(self, x, y)
		local _, _, col_widths, width, _, margin = table.unpack(self:dimensions())

		term.golc(y, x)
		local l = 0
		if self.title then
			local space = width - #self.title
			local offset = math.ceil(space / 2)
			term.golc(y, x + offset - 1)
			color({ nil, nil, 1 })
			term.outf(" " .. self.title .. " ")
			color({ nil, nil, 0 })
		end
		l = l + 1
		if #self.h > 0 then
			term.golc(y + l, x + 1)
			for p, c in ipairs(self.h) do
				color({ nil, nil, 3 })
				local suffix = col_widths[p] - #c + margin
				if p == self.sort_column then
					color({ nil, 44 })
				end
				term.outf(" " .. c .. string.rep(" ", suffix))
				color({ 0, 0, 0 })
				term.outf("|")
			end
			l = l + 1
			term.golc(y + l, x)
			term.outf("." .. string.rep("…", width - 2) .. ".")
			l = l + 1
		end
		for i, r in ipairs(self.t) do
			term.golc(y + l, x + 1)
			for c, v in ipairs(r) do
				local suffix = col_widths[c] - #v + margin
				local decor = self.style(c, v)
				if decor then
					color(decor)
				end
				term.outf(" " .. v .. string.rep(" ", suffix))
				if decor then
					color({ 0, 0, 0 })
				end
				term.outf("|")
			end
			l = l + 1
		end
		self:print_borders(x, y)
	end
	return tbl
end

return _M
