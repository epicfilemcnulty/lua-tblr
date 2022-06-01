local term = require("plterm")

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
_M.create = function(headers, style)
	local tbl = {
		t = {},
		h = headers,
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

	tbl.print = function(self, x, y)
		local rows = #self.t
		local columns = #self.h
		local col_widths = {}
		local margin = 2
		for i, c in ipairs(self.h) do
			table.insert(col_widths, #c)
		end
		for i, r in ipairs(self.t) do
			for p, c in ipairs(r) do
				if #c > col_widths[p] then
					col_widths[p] = #c
				end
			end
		end

		local width = 1
		for _, w in ipairs(col_widths) do
			width = width + w + margin + 2
		end

		term.golc(y, x)
		color({ nil, nil, 1 })
		term.outf("." .. string.rep("—", width - 2) .. ".")
		term.golc(y + 1, x)
		term.outf("|")
		for p, c in ipairs(self.h) do
			local suffix = col_widths[p] - #c + margin
			if p == self.sort_column then
				color({ nil, 44 })
			end
			term.outf(" " .. c .. string.rep(" ", suffix))
			color({ nil, 0 })
			term.outf("|")
		end
		term.golc(y + 2, x)
		term.outf("." .. string.rep("…", width - 2) .. ".")
		color({ 0, 0, 0 })

		for i, r in ipairs(self.t) do
			term.golc(y + 2 + i, x)
			term.outf("|")
			for p, c in ipairs(r) do
				local suffix = col_widths[p] - #c + margin
				local decor = self.style(p, c)
				if decor then
					color(decor)
				end
				term.outf(" " .. c .. string.rep(" ", suffix))
				if decor then
					color({ 0, 0, 0 })
				end
				term.outf("|")
			end
		end
		term.golc(y + 3 + #self.t, x)
		color({ nil, nil, 1 })
		term.outf("*" .. string.rep("—", width - 2) .. "*")
		color({ 0, 0, 0 })
	end
	return tbl
end

return _M
