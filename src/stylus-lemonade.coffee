###*
 * Lemonade: Automatically Generate CSS Sprites from Images with Stylus
 * a Node.js + Stylus implementation
 *
 * Copyright 2012 Smullin Design and other contributors
 * http://smullindesign.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###

gd = require 'node-gd'
async = require 'async'
fs = require 'fs'
#pathlib = require 'path'
#exec    = require('child_process').exec
instance = undefined

class Lemonade
  constructor: (@options) ->

  reset: ->
    @options ?= {}
    @options.image_path ?= './'
    @options.sprite_path ?= './'
    @options.sprite_url ?= './'
    @sprites = {}
    @series = []

  infect: (stylus_instance) ->
    # garbage collection
    @reset()

    ###*
 * sprite-map(sprite, options)
 * @param {String} sprite_filename
 *   name of sprite file to generate without .png extension
 *   default is 'sprite'
 * @param {String} options
 *   (optional) css-like key: value; string of options for sprite engine
 * @return {String}
    ###
    stylus_instance.define 'sprite-map', (sprite, options) ->
      sprite ?= { string: 'sprite' }
      options ?= { string: '' }
      "sprite:#{sprite.string};#{options.string}"

    ###*
 * sprite-url(map)
 * @param {String} map
 *   string returned by sprite-map()
 * @return {String}
 *   url to the sprite map's corresponding sprite file; for browsers
    ###
    stylus_instance.define 'sprite-url', (map) =>
      @_generate_placeholder 'URL', map.string

    ###*
 * sprite-position(map, png)
 * the only function that actually triggers sprite generation
 * @param {String} map
 *   string returned by sprite-map()
 * @param {String} png
 *   image filename without .png extension
 * @return {String}
 *   x, y coordinates of original image within compiled sprite
    ###
    stylus_instance.define 'sprite-position', (map, png) =>
      @_generate_placeholder 'POSITION', map.string, png.string

    ###*
 * sprite(map, png)
 * the only function that actually triggers sprite generation
 * @param {String} map
 *   string returned by sprite-map()
 * @param {String} png
 *   image filename without .png extension
 * @return {String}
 *   sprite image url() and x, y coordinates of original image
    ###
    stylus_instance.define 'sprite', (map, png) =>
      @_generate_placeholder 'URL_AND_IMAGE_POSITION', map.string, png.string

    ###*
 * sprite-width(map)
 * @param {String} map
 *   string returned by sprite-map()
 * @param {String} png
 *   image filename without .png extension
 * @return {Integer}
 *   width in pixels
    ###
    stylus_instance.define 'sprite-width', (map, png) =>
      @_generate_placeholder 'WIDTH', map.string, png.string

    ###*
 * sprite-height(map)
 * @param {String} map
 *   string returned by sprite-map()
 * @param {String} png
 *   image filename without .png extension
 * @return {Integer}
 *   height in pixels
    ###
    stylus_instance.define 'sprite-height', (map, png) =>
      @_generate_placeholder 'HEIGHT', map.string, png.string

    # event emitted by stylus.render()
    stylus_instance.on 'end', (css, callback) =>
      async.series @series, (err) =>
        return callback err, css if err

        # replace placeholders in css
        css = css.replace /["']SPRITE_(.+?)_PLACEHOLDER\((.+?), (.*?)\)["']/g, (match, key, sprite_key, png) =>
          sprite = @sprites[sprite_key]
          image = sprite.images[png]
          switch key
            when 'POSITION'
              return image.coords()
            when 'URL'
              return sprite.digest_url()
            when 'URL_AND_IMAGE_POSITION'
              return "url(#{sprite.digest_url()}) #{image.coords()}"
            when 'WIDTH'
              return image.px image.width
            when 'HEIGHT'
              return image.px image.height

        # save final sprites to disk
        series = []
        for own sprite_key, sprite of @sprites
          ((sprite) -> series.push (next) -> sprite.render next)(sprite)
        async.series series, (err) =>
          # complete stylus rendering
          callback null, css

          # notify done callback if one was provided
          @options.done() if typeof @options.done is 'function'

          return
        return
      return
    return

  _sprite_key_from_map: (map) ->
    if (matches = map.match(/sprite:(.+?);/)) isnt null then matches[1] else undefined

  _generate_placeholder: (key, map, png) ->
    sprite_key = @_sprite_key_from_map map
    sprite = @sprites[sprite_key] ?= new Sprite map
    if png?
      @series.push (callback) =>
        sprite.add png, callback
    "SPRITE_#{key}_PLACEHOLDER(#{sprite_key}, #{png ?= ''})"

  image_path: (png) ->
    @options.image_path + png + '.png'

  sprite_url: (png) ->
    @options.sprite_url + png + '.png'

  sprite_path: (png) ->
    @options.sprite_path + png + '.png'

  relative_path: (file) ->
    file.replace process.cwd() + '/', ''

class Sprite
  constructor: (map) ->
    @options =
      repeat: 'no-repeat'
    for token in map.split(';').slice(0, -1)
      token = token.split(':')
      @options[token[0].trim()] = token[1].trim().toLowerCase()
    @images = {}
    @x = 0
    @y = 0
    @width = 0
    @height = 0
    @png = undefined
    @_digest = undefined
    return

  digest: ->
    return @_digest if typeof @_digest isnt 'undefined'
    blob = ''
    blob += image.toString() + '|' for own key, image of @images
    @_digest = require('crypto').createHash('md5').update(blob).digest('hex').substr(-10)

  digest_file: ->
    undefined unless @digest()
    instance.sprite_path @options.sprite + '-' + @digest()

  digest_url: ->
    undefined unless @digest()
    instance.sprite_url @options.sprite + '-' + @digest()

  add: (file, callback) ->
    @_digest = undefined
    # if existing image within sprite
    unless typeof @images[file] is 'undefined'
      @images[file] # cached
      callback null
    else # new image not in sprite
      # calculate
      image = @images[file] = new Image file, @x, @y, (err) =>
        return callback err if err
        # TODO: allow repeat to dictate how cursor is incremented here; or do it all-at-once during render
        @width = Math.max @width, image.width
        @y = @height += image.height
        callback null
    return

  render: (callback) ->
    # save sprite image
    sprite = @

    # create new blank sprite canvas
    sprite.png = gd.createTrueColor sprite.width, sprite.height
    transparency = sprite.png.colorAllocateAlpha 0, 0, 0, 127
    sprite.png.fill 0, 0, transparency
    sprite.png.colorTransparent transparency
    sprite.png.alphaBlending 0
    sprite.png.saveAlpha 1

    # compile sprite in memory
    series = []
    for own key of sprite.images
      ((image) -> series.push (next) ->
        image.open ->
          #console.log "rendering #{image.file} over #{sprite.options.sprite} at #{image.coords()} with #{sprite.options.repeat}..."
          # TODO: support smart rendering for more compact image placement
          switch sprite.options.repeat
            when 'no-repeat'
              image.png.copy sprite.png, image.x, image.y, 0, 0, image.width, image.height
            when 'repeat-x'
              #TODO: account for spacing here
              for x in [0..sprite.width] by image.width
                image.png.copy sprite.png, x, image.y, 0, 0, image.width, image.height
            when 'repeat-y'
              #TODO: account for spacing here
              for y in [0..sprite.height] by image.height
                image.png.copy sprite.png, image.x, y, 0, 0, image.width, image.height
          next()
          return
        return)(sprite.images[key])
    async.series series, (err) ->
      callback err if err

      # delete old sprites off disk
      pattern = sprite.digest_file().replace /-[\w\d+]+\.png$/, '-*.png'
      files = require('glob').sync pattern
      for file in files
        fs.unlinkSync file

      # override sprite png on disk
      sprite.png.savePng sprite.digest_file(), 0, ->
        console.log "Wrote #{instance.relative_path sprite.digest_file()}."
        # TODO: add pngcrush here
        callback null, sprite.digest_file()
        return
      return
    return

class Image
  constructor: (@file, @x, @y, callback) ->
    @png = undefined
    @height = undefined
    @width = undefined
    @absfile = instance.image_path @file
    @open (err) =>
      return callback err if err
      @height = @png.height
      @width  = @png.width
      callback null
    return

  toString: ->
    "Image#file=#{@file},x=#{@x},y=#{@y},width=#{@width},height=#{@height}"

  open: (callback) ->
    gd.openPng @absfile, (err, png) =>
      return callback err if err
      @png = png
      callback null

  px: (i) ->
    if i is 0 then 0 else i + 'px'

  coords: ->
    @px(@x * -1) + ' ' + @px(@y * -1)

module.exports = (stylus_instance, options) ->
  instance = new Lemonade options
  instance.infect stylus_instance if stylus_instance?
  instance
