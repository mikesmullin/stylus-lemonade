var stylus = require('stylus')
    , fs = require('fs')
    , styl_input_filename = '../fixtures/private/stylesheets/application.styl'
    , css_output_filename = '../fixtures/public/stylesheets/application.css'
    , styl_input = fs.readFileSync(styl_input_filename).toString('utf-8');

stylus(styl_input)
  .set('filename', styl_input_filename)
  .plugin(__dirname + '/../../lib/stylus-lemonade', {
    image_path:  __dirname + '/../fixtures/private/images/',
    sprite_path: __dirname + '/../fixtures/public/images/',
    sprite_url:  '../images/'
  })
  .render(function(err, css_output) {
    if (err) throw err;
    fs.writeFileSync(css_output_filename, css_output);
    console.log('Wrote ' + css_output_filename + '.');
  });
