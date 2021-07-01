require 'test/unit'
require_relative '../lib/ejson.rb'
require 'fileutils'

class EjsonTest < Test::Unit::TestCase

    def test_basic

        FileUtils.mkdir_p( "test/result" )

        ifile = 'test/input/test.ext.json'

        # Open file.
        json = Ejson.new( ifile )
        ofile = "test/result/test.json"
        File.write( ofile, JSON.pretty_generate( json.data ) )

        golden_data = File.read( "test/golden/test.json" )
        design_data = File.read( ofile )

        assert_equal( golden_data, design_data )

        FileUtils.rm_f ofile
        FileUtils.rm_f "test/result"

    end

end

#require_relative '../lib/ejson.rb'
#require 'fileutils'
#FileUtils.mkdir_p( "test/result" )
#
#ifile = 'test/input/test.ext.json'
#
## Open file.
#json = Ejson.new( ifile )
#ofile = "test/result/test.json"
#File.write( ofile, JSON.pretty_generate( json.data ) )
#
#golden_data = File.read( "test/golden/test.json" )
#design_data = File.read( ofile )
