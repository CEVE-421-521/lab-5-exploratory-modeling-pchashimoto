using DataFrames
using Unitful

"""A struct to hold the depth-damage data"""
struct DepthDamageData

    # define the fields of the data structure
    depths::Vector{<:Unitful.Quantity{<:AbstractFloat,Unitful.𝐋}}
    damages::Vector{<:AbstractFloat}
    occupancy::AbstractString
    dmg_fn_id::AbstractString
    source::AbstractString
    description::AbstractString
    comment::AbstractString

    # we use an "inner constructor" to check that the lengths of the vectors are the same
    function DepthDamageData(depths, damages, args...; kwargs...)
        return if length(depths) == length(damages)
            new(depths, damages, args...; kwargs...)
        else
            error("depths and damages must be the same length")
        end
    end
end

"""Parse a row from a DataFrame, eg from `haz_fl_dept.csv`"""
function DepthDamageData(row::DataFrames.DataFrameRow)

    # get metadata fields
    occupancy = string(row.Occupancy)
    dmg_fn_id = string(row.DmgFnId)
    source = string(row.Source)
    description = string(row.Description)
    comment = string(row.Comment)

    # now get the depths and damages
    depths = Float64[]
    damages = Float64[]

    # Iterate over each column in the row
    for (col_name, value) in pairs(row)
        # Check if the column name starts with 'ft'
        if startswith(string(col_name), "ft")
            if value != "NA"
                # Convert column name to depth
                depth_str = string(col_name)[3:end] # Extract the part after 'ft'
                is_negative = endswith(depth_str, "m")
                depth_str = is_negative ? replace(depth_str, "m" => "") : depth_str
                depth_str = replace(depth_str, "_" => ".") # Replace underscore with decimal
                depth_val = parse(Float64, depth_str)
                depth_val = is_negative ? -depth_val : depth_val
                push!(depths, depth_val)

                # Add value to damages
                push!(damages, parse(Float64, string(value)))
            end
        end
    end

    # add appropriate units to them
    depths = depths .* 1.0u"ft"

    return DepthDamageData(
        depths, damages, occupancy, dmg_fn_id, source, description, comment
    )
end
