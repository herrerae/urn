local bit32 = bit32
local U32 = 2 ^ 32

if not bit32 then
	bit32 = { }
	function bit32.arshift(x, disp)
		local result = bit32.rshift(x, disp)
		if disp >= 0 then
			if disp > 32 then
				disp = 32
			end
			if (x % U32) >= (2 ^ 31) then
				for i = 1, disp do
					result = result + (2 ^ (32 - i))
				end
			end
		end
		return result
	end
	function bit32.band(...)
		local args, result, newresult, abit, bbit, rbit = {...}, ...

		for i = 2, #args do
			newresult = 0
			for j = 0, 31 do
				abit = math.floor((result / (2 ^ j)) % 2)
				bbit = math.floor((args[i] / (2 ^ j)) % 2)
				if (abit == 1) and (bbit == 1) then
					rbit = 1
				else
					rbit = 0
				end
				newresult = newresult + (rbit * (2 ^ j))
			end
			result = newresult
		end

		return result % U32
	end
	function bit32.bnot(x)
		return U32 - (x % U32) - 1
	end
	function bit32.bor(...)
		local args, result, newresult, abit, bbit, rbit = {...}, ...

		for i = 2, #args do
			newresult = 0
			for j = 0, 31 do
				abit = math.floor((result / (2 ^ j)) % 2)
				bbit = math.floor((args[i] / (2 ^ j)) % 2)
				if (abit == 1) or (bbit == 1) then
					rbit = 1
				else
					rbit = 0
				end
				newresult = newresult + (rbit * (2 ^ j))
			end
			result = newresult
		end

		return result % U32
	end
	function bit32.btest(...)
		return bit32.band(...) ~= 0
	end
	function bit32.bxor(...)
		local args, result, newresult, abit, bbit, rbit = {...}, ...

		for i = 2, #args do
			newresult = 0
			for j = 0, 31 do
				abit = math.floor((result / (2 ^ j)) % 2)
				bbit = math.floor((args[i] / (2 ^ j)) % 2)
				if ((abit == 1) or (bbit == 1)) and (not ((abit == 1) and (bbit == 1))) then
					rbit = 1
				else
					rbit = 0
				end
				newresult = newresult + (rbit * (2 ^ j))
			end
			result = newresult
		end

		return result % U32
	end
	function bit32.lrotate(x, disp)
		disp = disp % 32
		return bit32.lshift(x, disp) + bit32.rshift(x, 32 - disp)
	end
	function bit32.lshift(x, disp)
		if disp >= 0 then
			return (x * (2 ^ disp)) % U32
		else
			return math.floor(x * (2 ^ disp)) % U32
		end
	end
	function bit32.rrotate(x, disp)
		return bit32.lrotate(x, 0 - disp)
	end
	function bit32.rshift(x, disp)
		return bit32.lshift(x, 0 - disp)
	end
end

if not bit32.extract or not bit32.replace then
	function bit32.extract(n, field, width)
		width = width or 1
		return math.floor((n / (2 ^ field)) % (2 ^ width))
	end
	function bit32.replace(n, v, field, width)
		width = width or 1
		local pre = bit32.rshift(bit32.lshift(n, 32 - field), 32 - field)
		local val = bit32.lshift(v % (2 ^ width), field)
		local post = bit32.lshift(bit32.rshift(n, field + width), field + width)
		return (pre + val + post) % U32
	end
end

return {
	["ashr"] = bit32.arshift,
	["bit-and"] = bit32.band,
	["bit-not"] = bit32.bnot,
	["bit-or"] = bit32.bor,
	["bit-test"] = bit32.btest,
	["bit-xor"] = bit32.bxor,
	["bit-extract"] = bit32.extract,
	["bit-replace"] = bit32.replace,
	["bit-rotl"] = bit32.lrotate,
	["shl"] = bit32.lshift,
	["bit-rotr"] = bit32.rrotate,
	["shr"] = bit32.rshift,
}
