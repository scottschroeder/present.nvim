local M = {}


local state = {
  parsed = {},
  title = "",
  curent_slide = 1,
  floats = {
    background = nil,
    header = nil,
    body = nil,
    footer = nil,
  }
}

M.setup = function(opts)
  opts = opts or {}
end

local create_floating_window = function(config, enter)
  if enter == nil then
    enter = false
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, enter or false, config)

  vim.api.nvim_set_option_value("number", false, { win = win })

  return { buf = buf, win = win }
end

---@class present.Slides
---@fields slides present.Slide[]: The slides of the file

---@class present.Slide
---@field title string: Title
---@field body string[]: Body

---@param lines string[]: The lines in the buffer
---@return present.Slides
M._parse_slides = function(lines)
  local slides = { slides = {} }

  local current_slide = {}
  local separator = "^#"

  local append_slide = function()
    if current_slide.title == nil then
      return
    end
    if current_slide.body == nil then
      current_slide.body = {}
    end
    table.insert(slides.slides, current_slide)
    current_slide = {}
  end

  for _, line in ipairs(lines) do
    -- print(line, "find:", line:find(separator), "|")
    if line:find(separator) then
      append_slide()
      current_slide["title"] = line
    else
      local body = current_slide["body"] or {}
      table.insert(body, line)
      current_slide["body"] = body
    end
    -- table.insert(current_slide, line)
  end
  append_slide()

  return slides
end

local create_window_configurations = function()
  local width = vim.o.columns
  local height = vim.o.lines
  local header_size = 1 + 2 -- single line + 2x border
  local footer_size = 1     -- single line
  local body_height = height - header_size - footer_size - 2 - 1

  local windows = {
    background = {
      relative = 'editor',
      row = 0,
      col = 0,
      width = width,
      height = height,
      style = "minimal",
      zindex = 1,
    },
    header = {
      relative = 'editor',
      row = 0,
      col = 1,
      width = width,
      height = 1,
      style = "minimal",
      border = "rounded",
      zindex = 2,
    },
    body = {
      relative = 'editor',
      row = header_size + 1,
      col = 10,
      width = width - 10,
      height = body_height,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      zindex = 2,
    },
    footer = {
      relative = 'editor',
      row = height - 1,
      col = 1,
      width = width,
      height = 1,
      style = "minimal",
      -- border = "rounded",
      zindex = 2,
    },
  }
  return windows
end

local present_keymap = function(mode, key, callback)
  vim.keymap.set(mode, key, callback, {
    buffer = state.floats.body.buf
  })
end

local foreach_float = function(cb)
  for kind, float in pairs(state.floats) do
    cb(kind, float)
  end
end

local set_slide_content = function(slide_idx)
  if slide_idx > 0 then
    state.current_slide = slide_idx
  end
  local slide = state.parsed.slides[state.current_slide]

  local padding = string.rep(" ", (vim.o.columns - #slide.title) / 2)
  local centered_title = padding .. slide.title

  local footer = string.format("  [Slide %d/%d] [Title: %s]", state.current_slide, #state.parsed.slides, state.title)

  vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { centered_title })
  vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)
  vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
end


M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")
  state.parsed = M._parse_slides(lines)

  local windows = create_window_configurations()

  state.floats.background = create_floating_window(windows.background, false)
  state.floats.header = create_floating_window(windows.header, false)
  state.floats.footer = create_floating_window(windows.footer, false)
  state.floats.body = create_floating_window(windows.body, true)

  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  present_keymap("n", "n", function()
    local new_slide = math.min(state.current_slide + 1, #state.parsed.slides)
    set_slide_content(new_slide)
  end)

  present_keymap("n", "p", function()
    local new_slide = math.max(state.current_slide - 1, 1)
    set_slide_content(new_slide)
  end)

  present_keymap("n", "q", function()
    vim.api.nvim_win_close(state.floats.body.win, true)
  end)

  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      present = 0,
    },
    -- number = {
    --   original = vim.o.number,
    --   present = false,
    -- }
  }

  for option, config in pairs(restore) do
    vim.opt[option] = config.present
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.floats.body.buf,
    callback = function()
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end

      foreach_float(function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
        return
      end

      local windows_updated = create_window_configurations()
      foreach_float(function(name, float)
        vim.api.nvim_win_set_config(float.win, windows_updated[name])
      end)
      set_slide_content(0)
    end,

  })

  set_slide_content(1)
end

-- M.start_presentation({ bufnr = 437 })

return M
