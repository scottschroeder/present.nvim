local parse = require("present")._parse_slides

local function split_lines(input)
  local lines = {}
  for line in input:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

local parse_buffer = function(input)
  return parse(split_lines(input))
end

describe("present.parse_slides", function()
  it("should parse an empty file", function()
    assert.are.same({ slides = {} }, parse_buffer(""))
  end)

  it("should parse a with just a title", function()
    assert.are.same({
      slides = {
        {
          title = "# MyTitle",
          body = {},
        }
      }
    }, parse_buffer("# MyTitle"))
  end)

  it("should parse a single slide", function()
    assert.are.same({
      slides = {
        {
          title = "# MyTitle",
          body = { "This is the body" },
        }
      }
    }, parse_buffer([[
# MyTitle

This is the body
]]))
  end)

  it("should parse a multiple slides", function()
    assert.are.same({
      slides = {
        {
          title = "# MyTitle",
          body = { "This is the body" },
        },
        {
          title = "# Second Slide",
          body = { "More text goes here", "And some more for good measure" },
        }
      }
    }, parse_buffer([[
# MyTitle

This is the body

# Second Slide

More text goes here
And some more for good measure
]]))
  end)
end)
