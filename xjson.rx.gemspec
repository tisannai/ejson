Gem::Specification.new do |s|
    s.name        = 'ejson'
    s.version     = '0.1'
    s.date        = '-<write Time.now.to_s.split[0]>-'
    s.summary     = "Ejson is extension to JSON format."
    s.description = "Ejson is extension to JSON format."
    s.authors     = ["Tero Isannainen"]
    s.email       = 'tero.isannainen@gmail.com'
    s.files       = ['README.rdoc', 'CHANGELOG.rdoc', 'LICENSE', 'lib/ejson.rb', ] + Dir.glob( "test/**/*" ) + Dir.glob( "doc/**/*" )
    s.license     = 'Ruby'
    s.post_install_message = "Check README..."
    s.required_ruby_version = '>= 1.9.3'
    s.extra_rdoc_files = ['README.rdoc', 'CHANGELOG.rdoc']
end
