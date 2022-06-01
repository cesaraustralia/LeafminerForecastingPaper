using Rasters
using Statistics
using Rasters: Center 

filepath =  joinpath("D:","SMAP","nsidc", "GROWTHRATE")
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filepath_nc = searchdir(filepath, ".nc")

# Original data set

for i_file in filepath_nc
    R = Raster(joinpath(filepath, i_file))
    Rbin = map(x -> x !== missing ? (x > 0 ? x*0+1 : x*0) : missing, R)
    GRbin_path = joinpath(filepath, "binary", i_file)
    Rasters.write(GRbin_path, Rasters.Raster(Rbin))
end

for i_file in filepath_nc
    R = Raster(joinpath(filepath, i_file))
    Rpos = map(x -> x !== missing ? (x > 0 ? x : x*0) : missing, R)
    GRpos_path = joinpath(filepath, "positive", i_file)
    Rasters.write(GRpos_path, Rasters.Raster(Rpos))
end

# aggregated data

for res in [3,5,10]
    for i_file in filepath_nc
        R = Raster(joinpath(filepath, i_file))
        Rlow = Rasters.aggregate(Center(), R, (Y(res), X(res)); skipmissingval=true, progress=false)
        GRlow_path = joinpath(filepath, "lower_res_$res", i_file)
        Rasters.write(GRlow_path, Rasters.Raster(Rlow))
        Rbin = map(x -> x !== missing ? (x > 0 ? x*0+1 : x*0) : missing, Rlow)
        GRbin_path = joinpath(filepath, "lower_res_$res", "binary", i_file)
        Rasters.write(GRbin_path, Rasters.Raster(Rbin))
        Rpos = map(x -> x !== missing ? (x > 0 ? x : x*0) : missing, Rlow)
        GRpos_path = joinpath(filepath, "lower_res_$res", "positive", i_file)
        Rasters.write(GRpos_path, Rasters.Raster(Rpos))
    end
end

