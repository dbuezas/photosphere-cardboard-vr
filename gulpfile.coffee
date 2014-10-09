gulp = require 'gulp'
serve = require 'gulp-serve'
manifest = require 'gulp-manifest'
watch = require('gulp-watch');

gulp.task 'serve', serve(
  hostname: '0.0.0.0'
  root: [
    'serve'
  ]
  port: 8000
)
rebuildManifest = ->
  console.log( 'rebuilding manifest')
  gulp.src(["serve/**"]).pipe(manifest(
    hash: true
    preferOnline: true
    network: [
      "http://*"
      "https://*"
      "*"
    ]
    filename: "cache.manifest"
    exclude: "cache.manifest"
    timestamp: true
  )).pipe gulp.dest("serve")

gulp.task 'default', [
  'serve'
  'watch'
]

gulp.task 'watch', ->
  	gulp.src('serve/**')
  		.pipe(watch('serve/**', =>
  			rebuildManifest();
  		))