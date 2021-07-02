require 'json'

require 'byebug'

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
#     "opts": [ { "@eval": "/projects/ejson/sbin/list_opts" },
#                   { "@join": [ " ",
#                               "-conf_file",
#                               { "@join": [ "/",
#                                           { "@self": "workdir" },
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
    class EjsonReferenceError < RuntimeError; end

    VERSION = "0.0.1"
    def Ejson.version
        Ejson::VERSION
    end

    def Ejson.load( filename )
        Marshal.load( File.read( filename ) )
    end

    attr_reader :ext_data
    attr_reader :data
    attr_reader :dir

    def initialize( ejson_file )
        @cur_file = []
        @cur_data = []
        @ext_data = {}
        @ext_data = read_json_file( ejson_file )
        @data = expand( @ext_data )
    end

    def read_json_file( ejson_file )
        @cur_file.unshift ejson_file
        if ejson_file[0] != "<"
            JSON.parse( File.read( ejson_file ) )
        else
            JSON.parse( STDIN.read )
        end
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

    def find_in_array_of_hash( scope, key, value )
        index = 0
        while index < scope.length
            if Regexp.new( value).match( scope[ index ][ key ] )
                return index
            end
            index += 1
        end
        nil
    end

    def reference_handle( data, ref_desc )
        if ref_desc[0] != ":"
            # [ data, ref_desc ]
            reference_handle( data, ":#{ref_desc}" )
        else
            # Relative reference from root.
            path = ref_desc.split( ":" )[1..-1]
            scope = data
            while path[0..-2].any?
                if path[0] == "*"
                    # Wildcard for array.
                    unless path[1] && path[2]
                        raise EjsonReferenceError,
                        "Invalid reference: \"#{ref_desc}\" in \"#{@cur_file[0]}\", missing match key and value ..."
                    end
                    index = find_in_array_of_hash( scope, path[1], path[2] )
                    unless index
                        raise EjsonReferenceError,
                        "Invalid reference: \"#{ref_desc}\" in \"#{@cur_file[0]}\", key and value not matched ..."
                    end
                    scope = scope[ index ]
                    path.shift( 2 )
                else
                    begin
                        index = Integer( path[0] )
                        scope = scope[ index ]
                    rescue
                        scope = scope[ path[0] ]
                    end
                end
                path.shift
                unless scope
                    raise EjsonReferenceError,
                    "Invalid reference: \"#{ref_desc}\" in \"#{@cur_file[0]}\"..."
                end
            end
            [ scope, path[-1] ]
        end
    end

    def reference( data, ref_desc )
        path, label = reference_handle( data, ref_desc )
        begin
            index = Integer( label )
            scope = path[ index ]
        rescue
            # scope = scope[ path[0] ]
            scope = path[ label ]
        end
        # scope = path[ label ]
#        if scope.class == String
            scope
#        else
#            scope.to_s
#        end
    end

    def override_desc( data, exp )
        path, label = reference_handle( data, exp[0] )
        { path: path, label: label, value: exp[1] }
    end


    def override_apply( desc, overwrite = false )
        if desc[:label] == "*"
            desc[:path].each do |place|
                if not( place[ desc[:value][0] ] ) || overwrite
                    place[ desc[:value][0] ] = desc[:value][1]
                end
            end
        else
            if not( desc[:path][desc[:label]] ) || overwrite
                desc[:path][desc[:label]] = desc[:value]
            end
        end
    end


    def override( data, exp, overwrite = false )
        desc = override_desc( data, exp )
        override_apply( desc, overwrite )
    end


    # Expand json recursively.
    def expand( data )

        case data

        when TrueClass; data

        when FalseClass; data

        when Float; data

        when Integer; data

        when String; data

        when Array; data.map{|i| expand( i )}.compact

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
                    reference( @ext_data, expand(v) )

                when "@over";
                    override( @cur_data[0], expand(v), true )
                    nil

                when "@base";
                    override( @cur_data[0], expand(v), false )
                    nil

                when "@null"
                    nil

                when "@include";
                    jsonfile = expand(v)
                    subdata = read_json_file( jsonfile )
                    expdata = expand( subdata )
                    if expdata.class == Hash
                        expdata.each do |ke,ve|
                            @cur_data[0][ ke ] = ve
                        end
                    else
                        raise EjsonIncludeError,
                        "Included file (\"#{jsonfile}\") must contain a hash as top level"
                    end
                    @cur_file.shift
                    nil

                else
                    # Non-extension.
                    { k => expand( v ) }

                end

            else
                ret = {}
                @cur_data.unshift ret
                data.each do |k,v|
                    case k
                    when "@null"; nil
                    else
                        value = expand( v )
                        ret[ k ] = value if value
                    end
                end
                @cur_data.shift
                ret
            end
        end
    end

    def to_s
        JSON.pretty_generate( @data )
    end

    def dump( filename )
        File.write( filename, Marshal.dump( @data ) )
    end

end
