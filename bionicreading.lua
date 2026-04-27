local M = {}

local glyph_id = node.id("glyph")
local math_id = node.id("math")
local disc_id = node.id("disc")
local glue_id = node.id("glue")
local kern_id = node.id("kern")
local penalty_id = node.id("penalty")

local boundaries = {
  { 0, 4, 12, 17, 24, 29, 35, 42, 48 },
  { 1, 2, 7, 10, 13, 14, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49 },
  { 1, 2, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 43, 45, 47, 49 },
  { 0, 2, 4, 5, 6, 8, 9, 11, 14, 15, 17, 18, 20, 0, 21, 23, 24, 26, 27, 29, 30, 32, 33, 35, 36, 38, 39, 41, 42, 44, 45, 47, 48 },
  { 0, 2, 3, 5, 6, 7, 8, 10, 11, 12, 14, 15, 17, 19, 20, 21, 23, 24, 25, 26, 28, 29, 30, 32, 33, 34, 35, 37, 38, 39, 41, 42, 43, 44, 46, 47, 48 },
}

M.enabled = false
M.fixation_point = 1
M.font_map = {}
M.state_stack = {}
M.callbacks_registered = false

local function is_ascii_letter(char)
  return (char >= 65 and char <= 90) or (char >= 97 and char <= 122)
end

local function is_ascii_digit(char)
  return char >= 48 and char <= 57
end

local function is_ascii_alnum(char)
  return is_ascii_letter(char) or is_ascii_digit(char)
end

local function fixation_length(word_length, fixation_point)
  local list = boundaries[fixation_point] or boundaries[1]
  for index, boundary in ipairs(list) do
    if word_length <= boundary then
      local length = word_length - (index - 1)
      if length < 0 then
        return 0
      end
      return length
    end
  end
  local length = word_length - #list
  if length < 0 then
    return 0
  end
  return length
end

local function bold_word(word, has_letter)
  if not has_letter or #word == 0 then
    return
  end
  local bold_count = fixation_length(#word, M.fixation_point)
  for i = 1, bold_count do
    local glyph = word[i]
    local bold_font = M.font_map[glyph.font]
    if bold_font then
      glyph.font = bold_font
    end
  end
end

function M.process_list(head)
  if not M.enabled then
    return head
  end

  local word = {}
  local has_letter = false

  local function flush()
    bold_word(word, has_letter)
    word = {}
    has_letter = false
  end

  for n in node.traverse(head) do
    if n.id == glyph_id and is_ascii_alnum(n.char) then
      word[#word + 1] = n
      if is_ascii_letter(n.char) then
        has_letter = true
      end
    elseif n.id == kern_id or n.id == disc_id then
      -- Font kerning and discretionary hyphenation can occur inside a word.
      -- They must not restart fixation calculation for the following glyphs.
    else
      flush()
    end
  end

  flush()
  return head
end

function M.set_fixation_point(value)
  value = tonumber(value) or 1
  if value < 1 then
    value = 1
  elseif value > 5 then
    value = 5
  end
  M.fixation_point = value
end

function M.register_font_pair(normal_id, bold_id)
  normal_id = tonumber(normal_id)
  bold_id = tonumber(bold_id)
  if normal_id and bold_id then
    M.font_map[normal_id] = bold_id
  end
end

function M.start(fixation_point, active)
  table.insert(M.state_stack, {
    enabled = M.enabled,
    fixation_point = M.fixation_point,
  })
  M.set_fixation_point(fixation_point)
  M.enabled = active ~= false
end

function M.stop()
  local previous = table.remove(M.state_stack)
  if previous then
    M.enabled = previous.enabled
    M.fixation_point = previous.fixation_point
  else
    M.enabled = false
  end
end

M.enable = function(fixation_point)
  M.start(fixation_point, true)
end

M.disable = M.stop

function M.register_callbacks()
  if M.callbacks_registered then
    return
  end
  if luatexbase and luatexbase.add_to_callback then
    luatexbase.add_to_callback("pre_linebreak_filter", M.process_list, "bionicreading")
  else
    callback.register("pre_linebreak_filter", M.process_list)
  end
  M.callbacks_registered = true
end

return M
