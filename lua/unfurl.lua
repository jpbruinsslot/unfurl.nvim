local curl = require("plenary.curl")

local unfurl = {}
local last_url = nil

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

unfurl.youtube_timestamp = function()
	-- Check if a URL has been previously entered
	local url
	if last_url then
		-- Ask if the user wants to use the cached URL or enter a new one
		local use_cached = vim.fn.input("Use the last URL (" .. last_url .. ")? (y/n): ")
		if use_cached:lower() == "y" then
			url = last_url
		else
			url = vim.fn.input("Enter YouTube URL: ")
		end
	else
		url = vim.fn.input("Enter YouTube URL: ")
	end

	-- Validate and cache the URL
	local video_id = extract_video_id(url)
	if not video_id then
		print("Invalid YouTube URL")
		return
	end
	last_url = url -- Cache the valid URL

	-- Get timestamp input
	local timestamp = vim.fn.input("Enter timestamp (e.g. 2:34:30): ")
	local hours, minutes, seconds = 0, 0, 0

	-- Determine the format of the timestamp
	if timestamp:match("%d+:%d+:%d+") then
		hours, minutes, seconds = timestamp:match("(%d+):(%d+):(%d+)")
	elseif timestamp:match("%d+:%d+") then
		minutes, seconds = timestamp:match("(%d+):(%d+)")
	else
		print("Invalid timestamp")
		return
	end

	-- Construct the full URL with the timestamp
	local full_url = string.format("https://youtu.be/watch?v=%s&t=%dh%dm%ds", video_id, hours, minutes, seconds)

	-- Pad hours, minutes, and seconds with 0 if necessary
	hours = string.format("%02d", hours)
	minutes = string.format("%02d", minutes)
	seconds = string.format("%02d", seconds)

	-- Generate the markdown URL
	local markdown_url
	if tonumber(hours) > 0 then
		markdown_url = string.format("[%s:%s:%s](%s)", hours, minutes, seconds, full_url)
	else
		markdown_url = string.format("[%s:%s](%s)", minutes, seconds, full_url)
	end

	-- Insert the markdown URL
	vim.api.nvim_put({ markdown_url }, "l", true, true)
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

	vim.keymap.set("n", "<leader>ts", function()
		unfurl.youtube_timestamp()
	end, { noremap = true, silent = true })

	vim.keymap.set("n", "<leader>url", function()
		unfurl.webpage_url()
	end, { noremap = true, silent = true })
end

return unfurl
