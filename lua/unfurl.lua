local curl = require("plenary.curl")

local unfurl = {}

local function extract_video_id(url)
	return url:match("v=([^&]+)") or url:match("youtu%.be/([^?]+)") or url:match("youtube%.com/embed/([^?]+)")
end

-- Extracts the domain from a URL
local function parse_domain(url)
	local domain = url:gsub("^https?://", ""):match("([^/]+)")
	if domain:find("^www%.") then
		domain = domain:gsub("^www%.", "")
	end
	return domain
end

local function fetch_html_title(url)
	local response = curl.get(url)
	if response.status == 200 then
		local title = response.body:match("<title>(.-)</title>")
		if title then
			return title
		end
	end
	return nil
end

local function unescape_html_entities(text)
	local html_entities = {
		["&amp;"] = "&",
		["&lt;"] = "<",
		["&gt;"] = ">",
		["&quot;"] = '"',
		["&apos;"] = "'",
		["&#39;"] = "'",
		["&nbsp;"] = " ",
	}

	for entity, char in pairs(html_entities) do
		text = text:gsub(entity, char)
	end

	return text
end

unfurl.youtube_url = function()
	local url = vim.fn.input("Enter YouTube URL: ")
	local video_id = extract_video_id(url)
	if not video_id then
		print("Invalid YouTube URL")
		return
	end

	local full_url = "https://www.youtube.com/watch?v=" .. video_id
	local title = fetch_html_title(full_url)
	if not title then
		print("Failed to fetch video title")
		return
	end

	-- Remove " - YouTube" from the end of the title
	title = title:gsub("%s+%- YouTube$", "")

	title = unescape_html_entities(title)

	local markdown_url = string.format("[%s](%s)", title, full_url)
	vim.api.nvim_put({ markdown_url }, "l", true, true)
end

unfurl.webpage_url = function()
	local url = vim.fn.input("Enter URL: ")
	local title = fetch_html_title(url)
	if not title then
		print("Failed to fetch webpage title")
		return
	end

	title = unescape_html_entities(title)

	local domain = parse_domain(url)

	local markdown_url = string.format("[%s - %s](%s)", domain, title, url)
	vim.api.nvim_put({ markdown_url }, "l", true, true)
end

function unfurl.setup(opts)
	opts = opts or {}

	vim.keymap.set("n", "<leader>yt", function()
		unfurl.youtube_url()
	end, { noremap = true, silent = true })

	vim.keymap.set("n", "<leader>url", function()
		unfurl.webpage_url()
	end, { noremap = true, silent = true })
end

return unfurl
