Stylus-Lemonade
===============

**Stylus-Lemonade** is a plugin for Node.js [Stylus](https://github.com/LearnBoost/stylus)
which allows you to use functions like `sprite-position()`, `sprite-height()`, `image-width()`, `sprite-map()`, etc.
within your `*.styl` markup to automatically fetch images and generate css sprites at render time.

If you come from the Ruby on Rails community, you will immediately recognize conventions from Spriting
with [Compass](http://compass-style.org/help/tutorials/spriting/)/SASS, originally [Lemonade](http://www.hagenburger.net/BLOG/Lemonade-CSS-Sprites-for-Sass-Compass.html).

WARNING:
--------
Until my [pull request #923](https://github.com/LearnBoost/stylus/pull/923) is accepted, you'll have to [npm link](https://npmjs.org/doc/link.html) my fork of [Stylus](https://github.com/mikesmullin/stylus/commit/b672aa987e5cccd4b344095f2f4e1ef133158146).

DEPRECATED:
-----------
Decided rather than waiting I would just do it a better way. Now focusing my energy on [CoffeeSprites](https://github.com/mikesmullin/coffee-sprites). 
Will still keep stylus-lemonade around for posterity, but probably no new features.

Install
-------

```bash
sudo apt-get install libgd2-xpm-dev # on ubuntu; a libgd dependency
npm install stylus-lemonade
```

Use in Javascript
-----------------

For the very latest and most comprehensive example, see [test/integration/server.js](https://github.com/mikesmullin/stylus-lemonade/blob/master/test/integration/server.js#L9).

```javascript
var stylus = require('stylus');
stylus(markup_input)
  .use(require('stylus-lemonade')())
  .render(function(err, css_output){
    console.log(css_output);
  });
```

Use in Stylus
-------------

For the very latest and most comprehensive examples, see [test/fixtures/private/stylesheets/application.styl](https://github.com/mikesmullin/stylus-lemonade/blob/master/test/fixtures/private/stylesheets/application.styl#L16).

```sass
$animated_flame = sprite-map('flame')
#flame
  background: url(sprite-url($animated_flame)) no-repeat
  height: sprite-height($animated_flame, 'flame_a_0001')
  width: sprite-width($animated_flame, 'flame_a_0001')
.flame-frame-1
  background-position: sprite-position($animated_flame, 'flame_a_0001') !important
.flame-frame-2
  background-position: sprite-position($animated_flame, 'flame_a_0002') !important
.flame-frame-3
  background-position: sprite-position($animated_flame, 'flame_a_0003') !important
.flame-frame-4
  background-position: sprite-position($animated_flame, 'flame_a_0004') !important
.flame-frame-5
  background-position: sprite-position($animated_flame, 'flame_a_0005') !important
.flame-frame-6
  background-position: sprite-position($animated_flame, 'flame_a_0006') !important
```

Will output CSS like this:

```css
#flame {
  background: url(../images/flame-4e9c94d3fa.png) no-repeat;
  height: 512px;
  width: 512px;
}
.flame-frame-1 {
  background-position: 0 0 !important;
}
.flame-frame-2 {
  background-position: 0 -512px !important;
}
.flame-frame-3 {
  background-position: 0 -1024px !important;
}
.flame-frame-4 {
  background-position: 0 -1536px !important;
}
.flame-frame-5 {
  background-position: 0 -2048px !important;
}
.flame-frame-6 {
  background-position: 0 -2560px !important;
}
```

And the image will turn out like this:

 * [test/fixtures/public/images/flame-4e9c94d3fa.png](https://github.com/mikesmullin/stylus-lemonade/blob/master/test/fixtures/public/images/flame-4e9c94d3fa.png)

Test
----

```bash
npm test # build coffee, run mocha unit test, run chrome browser integration test
```

To do
-----
 * add validation to ensure no stylus defined function can be called with invalid input to avoid cryptic lockups
 * could probably simplify by calculating x, y, width, height using gd directly and once during render() rather than as-we-go
 * find a way to provide image-width and image-height mixins that can accept public paths and evaluate private paths according to single lemonade config
