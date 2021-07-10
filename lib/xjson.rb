require 'json'
# require 'byebug'

class Xjson

    class XjsonIncludeError < RuntimeError; end
    class XjsonReferenceError < RuntimeError; end

    VERSION = "0.0.2"
    def Xjson.version
        Xjson::VERSION
    end

    def Xjson.load( filename )
        Marshal.load( File.read( filename ) )
    end

    attr_reader :ext_data
    attr_reader :data
    attr_reader :dir

    def initialize( xjson_file )
        @cur_file = []
        @cur_data = []
        @ext_data = {}
        @ext_data = read_json_file( xjson_file )
        @data = expand( @ext_data )
    end

    # Read xjson file.
    def read_json_file( xjson_file )
        @cur_file.unshift xjson_file
        if xjson_file[0] != "<"
            JSON.parse( File.read( xjson_file ) )
        else
            JSON.parse( STDIN.read )
        end
    end

    # Write expanded json file.
    def write_json_file( json_file )
        File.write( json_file, JSON.pretty_generate( @data ) + "\n" )
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
            reference_handle( data, ":#{ref_desc}" )
        else
            # Relative reference from root.
            path = ref_desc.split( ":" )[1..-1]
            scope = data
            while path[0..-2].any?
                if path[0] == "*"
                    # Wildcard for array.
                    unless path[1] && path[2]
                        raise XjsonReferenceError,
                        "Invalid reference: \"#{ref_desc}\" in \"#{@cur_file[0]}\", missing match key and value ..."
                    end
                    index = find_in_array_of_hash( scope, path[1], path[2] )
                    unless index
                        raise XjsonReferenceError,
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
                    raise XjsonReferenceError,
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
        scope
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

        when Array;
            ret = []
            @cur_data.unshift ret
            data.each do |v|
                value = expand( v )
                ret.push( value ) if value
            end
            @cur_data.shift
            ret

        when Hash

            if data.size == 1

                # Most possible extension.

                k, v = data.first

                case k

                when "@eval"
                    %x"#{expand(v)}".split("\n")

                when "@env"
                    ENV[expand(v)]

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
                        if @cur_data[0].class == expdata.class
                            expdata.each do |ke,ve|
                                @cur_data[0][ ke ] = ve
                            end
                        else
                            raise XjsonIncludeError,
                            "Included file (\"#{jsonfile}\") must contain a hash as top level"
                        end
                    elsif expdata.class == Array
                        expdata.each do |ve|
                            @cur_data[0].push ve
                        end
                    else
                        raise XjsonIncludeError,
                        "Included file (\"#{jsonfile}\") must contain a hash or a an array as top level"
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

    # Return JSON data as string.
    def to_s
        JSON.pretty_generate( @data )
    end

    # Dump JSON data as marshal.
    def dump( filename )
        File.write( filename, Marshal.dump( @data ) )
    end

end
