--[[
Highlight.lua - Simplified management of the highlights list for weechat
  Version 0.1

Prerequisites
  The Lua plugin for weechat must be installed and enabled

Installation:
  Copy the highlight.lua file into your ~/.weechat/lua/autoload folder
	Reload the lua plugin by typing '/lua reload'

Usage:
	/highlight [list]
	  Prints the current highlight list to the core buffer

	/highlight add <phrase>
	  Adds the <phrase> to the highlights list. Note that weechat is not
		case sensitive in its highlight matching, so the phrase will be converted
		to lower case when added to the list.

	/highlight del <phrase>
	  Removes the <phrase> from the highlights list. See the add command
		for details around case sensitivity.

Issues:
	Please report issues using the issue tracker on my weechat-scripts
	github repository:

	http://github.com/PProvost/weechat-scripts/issues

License:
	Copyright 2010 Peter Provost (irc:PProvost@freenode)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
]]

--
-- Helper functions for dealing with lists of strings
--
local function strsplit(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

local function strjoin(delimiter, list)
	local len = #list
	if len == 0 then 
		return "" 
	end
	local string = list[1]
	for i = 2, len do 
		string = string .. delimiter .. list[i] 
	end
	return string
end

-- 
-- Helper functions for managing the config option set
--
local function GetHighlightTable()
	local opt = weechat.config_get("weechat.look.highlight")
	local val = weechat.config_string(opt)
	return strsplit(val, ",")
end

local function SaveHighlights(highlightsTable)
	local opt = weechat.config_get("weechat.look.highlight")
	local highlightsString = strjoin(",", highlightsTable)
	weechat.config_option_set(opt, highlightsString, 0)	
end

local function IsAlreadySet(phrase)
	local highlights = GetHighlightTable()
	for i,v in ipairs(highlights) do
		if string.lower(v) == string.lower(phrase) then
			return true
		end
	end
	return nil
end

--
-- Command handlers
--
local function PrintList()
	local highlights = GetHighlightTable()
	if #highlights == 0 then
		weechat.print("", "Highlights list is empty.")
	else
		weechat.print("", "Current highlights:")
		for i,v in ipairs(highlights) do
			weechat.print("", "  "..v)
		end
	end
end

local function PrintUsage()
	weechat.print("Highlight usage:")
	weechat.print(" /highlight [list][add <phrase>][del <phrase>]")
	weechat.print(" where <phrase> is the case-insensitive phrase you want to add to the highlight list.")
end

local function AddPhrase(phrase)
	if not phrase or phrase == "" then
		weechat.print("ERROR - you must provide a phrase to be added.")
	end

	local phrase = string.lower(phrase)
	if IsAlreadySet(phrase) then
		weechat.print("Phrase " .. phrase .. " is already in the highlight list.")
	else
		local highlights = GetHighlightTable()
		table.insert(highlights, phrase)
		SaveHighlights(highlights)
		weechat.print("", "'"..phrase.."' added to highlights list")
	end
end

local function DelPhrase(phrase)
	if not phrase or phrase == "" then
		weechat.print("ERROR - you must provide a phrase to be added.")
	end

	local phrase = string.lower(phrase)
	if not IsAlreadySet(phrase) then
		weechat.print("Phrase '" .. phrase .."' is not in the highlights list.")
	else
		local highlights = GetHighlightTable()
		for i,v in ipairs(highlights) do
			if string.lower(v) == phrase then
				table.remove(highlights, i)
				SaveHighlights(highlights)
				weechat.print("", "Phrase '"..phrase.."' removed from the highlights list.")
				return
			end
		end
	end
end

--
-- Main entry point
--
function highlight_init(data, buffer, args)
	local cmd, params = string.match(args, "(%a+) (.*)")
	if not cmd or cmd == "" or cmd == "list" then
		PrintList()
		return
	end

	cmd = string.lower(cmd)
	if cmd == "add" then
		AddPhrase(params)
	elseif cmd == "del" then
		DelPhrase(params)
	else
		PrintUsage()
	end
	return weechat.WEECHAT_RC_OK
end

--
-- Register with weechat
--
weechat.register("Highlight", "PProvost", "0.1", "Apache-2.0", "A set of useful highlight management slash commands", "", "")
weechat.hook_command("highlight", 
	"Access the weechat hightlist list",  -- description
	"[list | add <phrase> | del <phrase>]", -- args
	"  list: lists highlight phrases\n"..
	"  add: adds a new phrase\n"..
	"  del: removes a phrase\n\n"..
	"If no command is given, all phrases are listed.",
	"add || del || list", -- completion
	"highlight_init", 
	"")

