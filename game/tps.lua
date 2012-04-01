local t = {}

local s_loaded_textures = {}

-- Load a texture at most once.
-- Mostly for internal use.
--
-- Pass:
--   filename	A texture to load
--
function t.get_texture(png)
	local tex = s_loaded_textures[png]
	if tex then return tex end
	tex = MOAITexture.new()
	tex:load(png)
	s_loaded_textures[png] = tex
	return tex
end

-- Create a sprite from png.
--
-- Pass:
--   png        Filename
--   scale      optional scale; if not passed, size == texel size
--
-- Returns a Deck
--
function t.load_single(png, scale)
	if not scale then scale = 1 end
    local deck = MOAIGfxQuad2D.new()
	local tex = t.get_texture(png)
    deck:setTexture(tex)
    local w,h = tex:getSize()
    deck:setRect(0,0,w*scale,h*scale)

    return deck
end

-- Load a sprite sheet
-- It's assumed that there is some sort of custom logic in here
-- that sets the geometry scale appropriately
--
-- Pass:
--   lua        .lua output from texturepacker
--   scale      scale to bake into all sprites created from sheet
--   xsize      If passed, scale down so all sprites have this x size
--
-- Returns an object with a :make(sprite_name [,scale)] method
-- make() returns a MOAIProp2D.
--
function t.load_sheet(lua, sheet_scale, xsize, xoff)
    if not sheet_scale then
        sheet_scale = 1
    end
    if not xoff then xoff = 0 end

    local sheet = dofile ( lua )
    local frames = sheet.frames

    local tex = t.get_texture( 'art/' .. sheet.texture )
    local xtex, ytex = tex:getSize ()

    -- Annotate the frame array with uv quads and geometry rects
    for i, frame in ipairs ( frames ) do
        -- convert frame.uvRect to frame.uvQuad to handle rotation
        local uv = frame.uvRect
        local q = {}
        if not frame.textureRotated then
            -- From Moai docs: "Vertex order is clockwise from upper left (xMin, yMax)"
            q.x0, q.y0 = uv.u0, uv.v0
            q.x1, q.y1 = uv.u1, uv.v0
            q.x2, q.y2 = uv.u1, uv.v1
            q.x3, q.y3 = uv.u0, uv.v1
        else
            -- Sprite data is rotated 90 degrees CW on the texture
            -- u0v0 is still the upper-left
            q.x3, q.y3 = uv.u0, uv.v0
            q.x0, q.y0 = uv.u1, uv.v0
            q.x1, q.y1 = uv.u1, uv.v1
            q.x2, q.y2 = uv.u0, uv.v1
        end
        frame.uvQuad = q

        -- convert frame.spriteColorRect and frame.spriteSourceSize
        -- to frame.geomRect.  Origin is at x0,y0 of original sprite
        local cr = frame.spriteColorRect
        local r = {}
        if xsize ~= nil then
            if frame.spriteSourceSize.width then
                sheet_scale = xsize / frame.spriteSourceSize.width
            else
                sheet_scale = 1
            end
        end

        r.x0 = sheet_scale * ( cr.x             ) + xoff
        r.y0 = sheet_scale * ( cr.y             )
        r.x1 = sheet_scale * ( cr.x + cr.width  ) + xoff
        r.y1 = sheet_scale * ( cr.y + cr.height )
        frame.geomRect = r
    end

    -- Construct the deck
    local deck = MOAIGfxQuadDeck2D.new ()
    deck:setTexture ( tex )
    deck:reserve ( #frames )
    local names = {}
    for i, frame in ipairs ( frames ) do
        local q = frame.uvQuad
        local r = frame.geomRect
        names[frame.name] = i
        deck:setUVQuad ( i, q.x0,q.y0, q.x1,q.y1, q.x2,q.y2, q.x3,q.y3 )
        deck:setRect ( i, r.x0,r.y0, r.x1,r.y1 )
    end

    deck.names = names

    function deck:setup(prop, sprite)
        prop:setDeck(self)
        local idx = self.names[sprite]
        if not idx then
            print("WARN: missing sprite "..sprite)
        else
            prop:setIndex(idx)
        end
    end
    
    function deck:make(sprite, scale)
        local prop = MOAIProp2D.new()
        if scale then prop:setScl(scale,scale) end
        self:setup(prop, sprite)
        return prop
    end

    return deck
end

-- Return
--   deck
--   array<layer>
function t.load_tilesheet(luafile, pngfile)
    local sheet = dofile ( luafile )
    local deck = MOAITileDeck2D.new ()

    deck:setTexture( t.get_texture( pngfile ) )
    deck:setRect(0,0,1.03,1.03)
    deck:setSize(10, 10)
    return deck, sheet.layers
end

return t