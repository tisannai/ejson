require 'json'
# require 'byebug'

#
# Extended JSON, EJSON
#
# JSON contains literal entries. EJSON extends the liternal entries to
# dynamic which are evaluated.
#
# Dynamic entries are captured in Hash data and they are indentified
# with specific keys: eval, self, join, conc.
#
# The Extension Keys (EK) are reserved words in JSON, since they are
# only intended for extension (expansion).
#
# Example:
#
#   {
#     "opts": [ { "eval": "/projects/ejson/sbin/list_opts" },
#                   { "join": [ " ",
#                               "-conf_file",
#                               { "join": [ "/",
#                                           { "self": "workdir" },
#                                           "unit/data.txt" ] }
#                             ]
#                   }
#                 ],
#
# "opts" is a literal JSON entry, since it doesn't match an EK. "eval"
# is an EK, and the related value is used as shell command.
#
# "join" is also an EK, which takes a list (array) of entries to join
# as one string. However, the result might contain arrays, which are
# first flattened.
#


class Ejson

    class EjsonIncludeError < RuntimeError; end

    VERSION = "0.0.1"
    def Ejson.version
        Ejson::VERSION
    end

    attr_reader :ext_data
    attr_reader :data
    attr_reader :dir

    def initialize( ejson_file )
        @ext_data = read_json_file( ejson_file )
        @data = expand( @ext_data )
    end

    def read_json_file( ejson_file )
        JSON.parse( File.read( ejson_file ) )
    end

    # Flatten by one level within array.
    def flatten( data )
        case data
        when Array;
            res = []
            data.each do |i|
                if i.class == Array
                    res += i
                else
                    res.push i
                end
            end
            res
        else
            data
        end
    end


    # Expand json recursively.
    def expand( data )

        case data

        when TrueClass; data

        when FalseClass; data

        when Float; data

        when Integer; data

        when String; data

        when Array; data.map{|i| expand( i )}

        when Hash

            if data.size == 1

                # Most possible extension.

                k, v = data.first

                case k

                when "@eval"
                    %x"#{expand(v)}".split("\n")

                when "@join"
                    flatten( v[1..-1].map{|i| expand( i )} ).join( v[0] )

                when "@flat"
                    flatten( v[1..-1].map{|i| expand( i )} )

                when "@self"
                    @ext_data[ expand(v) ]

                else
                    # Non-extension.
                    { k => expand( v ) }

                end

            else
                ret = {}
                data.each do |k,v|
                    if k == "@include"
                        jsonfile = expand(v)
                        subdata = read_json_file( jsonfile )
                        expdata = expand( subdata )
                        if expdata.class == Hash
                            expdata.each do |ke,ve|
                                ret[ ke ] = ve
                            end
                        else
                            raise EjsonIncludeError,
                            "Included file (\"#{jsonfile}\") must contain a hash as top level"
                        end
                    else
                        ret[ k ] = expand( v )
                    end
                end
                ret
            end
        end
    end

    def to_s
        JSON.pretty_generate( @data )
    end

end
