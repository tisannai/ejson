require 'test/unit'
require_relative '../lib/xjson.rb'
require 'fileutils'

class XjsonTest < Test::Unit::TestCase

    def test_basic

        FileUtils.mkdir_p( "test/result" )

        ENV['XJSON_FOOBAR'] = "FOOBAR"

        ifile = 'test/input/test.ext.json'

        # Open file.
        json = Xjson.new( ifile )
        ofile = "test/result/test.json"
        json.write_json_file( ofile )

        golden_data = File.read( "test/golden/test.json" )
        design_data = File.read( ofile )

        assert_equal( golden_data, design_data )

        FileUtils.rm_f ofile
        FileUtils.rm_f "test/result"

    end

end
