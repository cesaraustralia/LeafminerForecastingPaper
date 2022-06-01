using Plots
using Rasters
using CSV
using DelimitedFiles
using Dates
using TranscodingStreams
using CodecZlib
using DataFrames


species_list = ["Liriomyza sativae","Liriomyza huidobrensis",
"Liriomyza trifolii", "Diglyphus isaea", "Hemiptarsenus varicornis"]
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))

## RES 10, 5, 3
filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_3")
filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_5")
filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_10")
i_sp = species_list[1]
path = searchdir(filepath, i_sp)
i_path = path[1]
R = Raster(joinpath(filepath, i_path))
Rdim = dims(R)
lon_ = [Rdim[1][i] for i in 1:length(Rdim[1])]
lat_ = [Rdim[2][i] for i in 1:length(Rdim[2])]

extract_ = function(pt)
    lon_id = searchsortedlast(lon_, pt[1])
    lat_id = length(lat_) - searchsortedlast(reverse(lat_), pt[2])
    return (lon_[lon_id], lat_[lat_id])
end

extract_id = function(pt, i)
    lon_id = searchsortedlast(lon_, pt[1])
    lat_id = length(lat_) - searchsortedlast(reverse(lat_), pt[2])
    return R[lon_id, lat_id, i]
end


DT = Dict(
    :Lakeland =>  (lon=144.836652, lat=-15.835572),
    :Bundaberg => (lon=152.331365, lat=-24.951024),
    :Kununurra => (lon=128.713446, lat=-15.726019),
    :Werribee =>  (lon=144.65646, lat=-37.943556),
    :Mildura =>   (lon=142.198147, lat=-34.245636),
)
# transform crs = 4326 to "+proj=cea +lat_ts=30 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
DT = Dict(
    :Lakeland =>  (lon=13974750 , lat=-1995238),
    :Bundaberg => (lon=14697887 , lat=-3085878),
    :Kununurra => (lon=12419082 , lat=-1981775),
    :Werribee =>  (lon=13957364 , lat=-4502047),
    :Mildura =>   (lon=13720170 , lat=-4119137),
)

plot(R[Ti(1)])
scatter!(extract_(DT[:Lakeland]))
scatter!(extract_(DT[:Bundaberg]))
scatter!(extract_(DT[:Kununurra]))
scatter!(extract_(DT[:Werribee]))
scatter!(extract_(DT[:Mildura]))

dd = DateTime(2017,01,01):Day(1):DateTime(2017,12,31)

for i_sp in species_list
    println("$i_sp")
    Lakeland = []
    Bundaberg = []
    Kununurra = []
    Werribee = []
    Mildura = []
    path = searchdir(filepath, i_sp)
    for i_path in path
        println("$i_path")
        R = Raster(joinpath(filepath, i_path))
        Rdim = dims(R)
        lon_ = [Rdim[1][i] for i in 1:length(Rdim[1])]
        lat_ = [Rdim[2][i] for i in 1:length(Rdim[2])]
        append!(Lakeland, [extract_id(DT[:Lakeland], i) for i in 1:length(Rdim[3])])
        append!(Bundaberg, [extract_id(DT[:Bundaberg], i) for i in 1:length(Rdim[3])])
        append!(Kununurra, [extract_id(DT[:Kununurra], i) for i in 1:length(Rdim[3])])
        append!(Werribee, [extract_id(DT[:Werribee], i) for i in 1:length(Rdim[3])])
        append!(Mildura, [extract_id(DT[:Mildura], i) for i in 1:length(Rdim[3])])
    end
    df =  DataFrame(
        Lakeland = Lakeland,
        Bundaberg = Bundaberg,
        Kununurra = Kununurra,
        Werribee = Werribee, 
        Mildura = Mildura,
        Days = dd,
        DaysNum = 1:365,
        MonthName = monthname.(dd),
        MonthNum = month.(dd),
        Species = i_sp,
    )
    CSV.write(joinpath(filepath, "series_AUS", "GR_site_$i_sp.csv"), df ; missingstring = "NA")
end


############# 
############# Climate series ################
filepath =  joinpath("D:\\SMAP","nsidc")
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))

path_wlt = searchdir(filepath,"wilt.nc")
path_tmp = searchdir(filepath,"temp.nc")

R = Rasters.Raster(joinpath(filepath, path_wlt[1]))
Rdim = dims(R)
lon_ = [Rdim[1][i] for i in 1:length(Rdim[1])]
lat_ = [Rdim[2][i] for i in 1:length(Rdim[2])]


extract_R = function(R_, pt,m)
    lon_id = searchsortedlast(lon_, pt[1])
    lat_id = length(lat_) - searchsortedlast(reverse(lat_), pt[2])
    mat =  R_[lon_id-m:lon_id+m, lat_id-m:lat_id+m]
    return sum(mat) / length(mat)
end

df = DataFrame(City = [], tmp = Float64[], wlt = Float64[], Dates = DateTime[])
dd = DateTime(2017,01,01):Day(1):DateTime(2017,12,31)

for i in 1:length(path_wlt)
    R_wlt = Rasters.Raster(joinpath(filepath, path_wlt[i]))
    R_tmp = Rasters.Raster(joinpath(filepath, path_tmp[i]))
    push!(df, ["Lakeland", extract_R(R_tmp, DT[:Lakeland],1),   extract_R(R_wlt, DT[:Lakeland],1), dd[i]])
    push!(df, ["Bundaberg", extract_R(R_tmp, DT[:Bundaberg],1),   extract_R(R_wlt, DT[:Bundaberg],1),  dd[i]])
    push!(df, ["Kununurra", extract_R(R_tmp, DT[:Kununurra],1),   extract_R(R_wlt, DT[:Kununurra],1),  dd[i]])
    push!(df, ["Werribee", extract_R(R_tmp, DT[:Werribee],1),   extract_R(R_wlt, DT[:Werribee],1),  dd[i]])
    push!(df, ["Mildura", extract_R(R_tmp, DT[:Mildura],1),   extract_R(R_wlt, DT[:Mildura],1),  dd[i]])
end

df[!, :DaysNum] = dayofyear.(df[:Dates])
df[!, :MonthName] = monthname.(df[:Dates])
df[!, :MonthNum] = month.(df[:Dates])
df[!, :tmp_C] = df[:tmp] .- 273.15

CSV.write(joinpath(filepath, "series_AUS_CLIMATE.csv"), df ; missingstring = "NA")