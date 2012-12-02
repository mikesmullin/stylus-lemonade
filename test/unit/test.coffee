assert = require 'assert'

describe 'Lemonade', ->
  lemonade = undefined

  setup = (done) ->
    fs = require('fs')
    styl_input_filename = __dirname + '/../fixtures/private/stylesheets/application.styl'
    css_output_filename = __dirname + '/../fixtures/public/stylesheets/application.css'
    styl_input = fs.readFileSync(styl_input_filename).toString('utf-8')

    stylus = require 'stylus'
    lemonade = require __dirname + '/../../lib/stylus-lemonade'

    stylus_instance = stylus(styl_input).set('filename', styl_input_filename)
    lemonade = lemonade(null, {
      image_path:  __dirname + '/../fixtures/private/images/',
      sprite_path: __dirname + '/../fixtures/public/images/',
      sprite_url:  '../images/'
      debug: true
      done: done
    })
    lemonade.infect stylus_instance
    stylus_instance.render (err, css_output) ->

  beforeEach setup

  it 'exists', ->
    assert lemonade

  describe 'Sprite', ->
    it 'exists', ->
      assert lemonade.sprites

    it 'has unique digest per sprite', ->
      digests = {}
      all_unique = true
      for own sprite_key, sprite of lemonade.sprites
        key = sprite.digest()
        if digests[key]?
          all_unique = false
        else
          digests[key] = true
      assert all_unique

    it 'deletes old sprites on render', ->
      # create fake old sprite image
      fs = require 'fs'
      fake_file = lemonade.sprite_path 'icons-xxxxxxxxxx'
      fs.writeFileSync fake_file, '' # touch
      # verify fake old sprite image created successfully
      assert fs.existsSync fake_file
      setup -> # re-render
        # verify fake old sprite image was deleted
        assert not fs.existsSync fake_file

  describe 'Image', ->
    it 'exists', ->
      assert lemonade.sprites.icons.images
