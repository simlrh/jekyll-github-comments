Gem::Specification.new do |spec|
  spec.name        = 'jekyll-github-comments'
  spec.version     = '1.0.1'
  spec.date        = '2016-11-23'
  spec.summary     = "Jekyll Github Comments"
  spec.description = "A Jekyll plugin to provide static site comments via Github pull requests."
  spec.authors     = ["Steve Le Roy Harris"]
  spec.email       = 'steve@nourish.je'
  spec.files       = ["lib/jekyll-github-comments.rb"]
  spec.homepage    =
    'http://rubygems.org/gems/jekyll-github-comments'
  spec.license       = 'MIT'
  spec.add_runtime_dependency "jekyll", ">= 3.0"
  spec.add_runtime_dependency "liquid", "~> 3.0"
end
