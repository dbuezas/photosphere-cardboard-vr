gulp = require 'gulp'
serve = require 'gulp-serve'
manifest = require 'gulp-manifest'

gulp.task 'serve', serve(
  hostname: '0.0.0.0'
  root: [
    'serve'
  ]
  port: 8000
)
gulp.task "manifest", ->
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
  )).pipe gulp.dest("serve")

gulp.task 'default', [
  'serve'
]
