Gem::Specification.new do |s|
    s.name        = 'xjson'
    s.version     = '0.0.3'
    s.date        = '-<write Time.now.to_s.split[0]>-'
    s.summary     = "Xjson is extension to JSON format."
    s.description = "Xjson is extension to JSON format."
    s.authors     = ["Tero Isannainen"]
    s.email       = 'tero.isannainen@gmail.com'
    s.files       = ['README.rdoc', 'CHANGELOG.rdoc', 'LICENSE', 'lib/xjson.rb', ] + Dir.glob( "test/**/*" ) + Dir.glob( "doc/**/*" ) + Dir.glob( "markdown/*" )
    s.license     = 'Ruby'
    s.post_install_message = "Check README..."
    s.required_ruby_version = '>= 1.9.3'
    s.extra_rdoc_files = ['README.rdoc', 'CHANGELOG.rdoc']
end
