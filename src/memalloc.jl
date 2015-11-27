## Analyzing memory allocation

immutable MallocInfo
    bytes::Int
    filename::UTF8String
    linenumber::Int
end

sortbybytes(a::MallocInfo, b::MallocInfo) = a.bytes < b.bytes

"""
    analyze_malloc_files(files) -> Vector{MallocInfo}

Iterates through the given list of filenames and return a `Vector` of
`MallocInfo`s with allocation information.
"""
function analyze_malloc_files(files)
    bc = MallocInfo[]
    for filename in files
        open(filename) do file
            for (i,ln) in enumerate(eachline(file))
                tln = strip(ln)
                if !isempty(tln) && isdigit(tln[1])
                    s = split(tln)
                    b = parseint(s[1])
                    push!(bc, MallocInfo(b, filename, i))
                end
            end
        end
    end
    sort(bc, lt=sortbybytes)
end
ismemfile(file::AbstractString) = endswith(file, "jl.mem")
function find_malloc_files(dirs)
    files = ByteString[]
    for dir in dirs
        filelist = readdir(dir)
        for file in filelist
            file = joinpath(dir, file)
            if isdir(file)
                append!(files, find_malloc_files(file))
            elseif ismemfile(file)
                push!(files, file)
            end
        end
    end
    files
end
find_malloc_files(file::ByteString) = find_malloc_files([file])

analyze_malloc(dirs) = analyze_malloc_files(find_malloc_files(dirs))
analyze_malloc(dir::ByteString) = analyze_malloc([dir])

isfuncexpr(ex::Expr) =
    ex.head == :function || (ex.head == :(=) && typeof(ex.args[1]) == Expr && ex.args[1].head == :call)
isfuncexpr(arg) = false

"""
        clean_folder_malloc(folder::AbstractString)

    Cleans up all the `.mem` files in the given directory and subdirectories.
    Unlike `process_folder` this does not include a default value
    for the root folder, requiring the calling code to be more explicit about
    which files will be deleted.
    """
    function clean_folder_malloc(folder::AbstractString)
        files = find_malloc_files(folder)
        for fullfile in files
            println("Removing $fullfile")
            rm(fullfile)
        end
        nothing
    end

# # Support Unix command line usage like `julia Coverage.jl $(find ~/.julia/v0.3 -name "*.jl.mem")`
# if !isinteractive()
#     bc = analyze_malloc_files(ARGS)
#     println(bc)
# end
