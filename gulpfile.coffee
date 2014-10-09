gulp = require 'gulp'
serve = require 'gulp-serve'

gulp.task 'serve', serve(
  hostname: '0.0.0.0'
  root: [
    'serve'
  ]
  port: 8000
)

gulp.task 'default', [
  'serve'
]
