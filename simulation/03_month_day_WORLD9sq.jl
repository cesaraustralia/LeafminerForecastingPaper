using Plots
using Rasters
using CSV
using DelimitedFiles
using Dates
using TranscodingStreams
using CodecZlib

species_list = ["Liriomyza sativae","Liriomyza huidobrensis",
"Liriomyza trifolii", "Diglyphus isaea", "Hemiptarsenus varicornis"]
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))

function merge_raster(Ryy)
    Rdim= dims(Ryy[1])
    x_ = [Rdim[1][i] for i in 1:length(Rdim[1])]
    y_ = [Rdim[2][i] for i in 1:length(Rdim[2])]
    A = Array{Union{Missing, Float64}, 3}(undef,size(Ryy[1])[1],size(Ryy[1])[2],length(Ryy))
    for i in 1:length(Ryy)
        A[:,:,i] = Ryy[i]
    end
    R = Raster(A, (X(x_),Y(y_), Ti(1:length(Ryy))))
    return(R)
end

################# NBR DAY / MONTH / YEAR

## ORIGIN DATA
filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "binary")
path = searchdir(filepath, ".nc")
for i_sp in species_list
    path = searchdir(filepath, i_sp)
    for i_path in path
        R = Raster(joinpath(filepath, i_path))
        Rsum = sum(R, dims=3)
        GR_path = joinpath(filepath, "..","sumBinaryMonth", i_path)
        Rasters.write(GR_path, Rsum)
    end
end
## Merge raster
filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "sumBinaryMonth")
for i_sp in species_list
    i_path = searchdir(filepath, i_sp)
    Ryy = [Raster(joinpath(filepath, ii_path)) for ii_path in i_path]
    R = merge_raster(Ryy)
    GR_path = joinpath(filepath, "DDbyMM", "GR_positiveDDbyMM_$(i_sp).nc")
    Rasters.write(GR_path, R)
end


## RES 10, 5, 3
for res in [10,5,3]
    filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "binary")
    for i_sp in species_list
        path = searchdir(filepath, i_sp)
        for i_path in path
            R = Raster(joinpath(filepath, i_path))
            Rsum = sum(R, dims=3)
            GR_path = joinpath(filepath, "..","sumBinaryMonth", i_path)
            Rasters.write(GR_path, Rsum)
        end
    end
    filepath =  joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryMonth")
    for i_sp in species_list
        i_path = searchdir(filepath, i_sp)
        Ryy = [Raster(joinpath(filepath, ii_path)) for ii_path in i_path]
        R = merge_raster(Ryy)
        GR_path = joinpath(filepath, "DDbyMM", "GR_positiveDDbyMM_$(i_sp).nc")
        Rasters.write(GR_path, R)
    end
end

################# NBR DAY / YEAR
## RES 10, 5, 3
for res in [10,5,3]
    filepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res","sumBinaryMonth", "DDbyMM")
    savepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res","sumBinaryYear")
    for i_sp in species_list
        path = searchdir(filepath, i_sp)
        R = Raster(joinpath(filepath, path[1]))
        Rsum = sum(R, dims=3)
        GR_path = joinpath(savepath,"$(i_sp)_daily.nc")
        Rasters.write(GR_path, Rsum)
    end
end

## WORLD9sq
filepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "sumBinaryMonth", "DDbyMM")
savepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "sumBinaryYear")
for i_sp in species_list
    path = searchdir(filepath, i_sp)
    R = Raster(joinpath(filepath, path[1]))
    Rsum = sum(R, dims=3)
    GR_path = joinpath(savepath,"$(i_sp)_daily.nc")
    Rasters.write(GR_path, Rsum)
end

################# NBR MONTH / YEAR
## RES 10, 5, 3
for res in [10,5,3]
    filepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryMonth", "DDbyMM")
    savepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryYear")
    for i_sp in species_list
        path = searchdir(filepath, i_sp)
        R = Raster(joinpath(filepath, path[1]))
        Rbin = map(x -> x !== missing ? (x > 0 ? x*0+1 : x*0) : missing, R)
        Rsum = sum(Rbin, dims=3)
        GR_path = joinpath(savepath,"$(i_sp)_monthly.nc")
        Rasters.write(GR_path, Rsum)
    end
end

## WORLD9sq
filepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "sumBinaryMonth", "DDbyMM")
savepath = joinpath("D:", "SMAP","nsidc", "GROWTHRATE", "sumBinaryYear")
for i_sp in species_list
    path = searchdir(filepath, i_sp)
    R = Raster(joinpath(filepath, path[1]))
    Rbin = map(x -> x !== missing ? (x > 0 ? x*0+1 : x*0) : missing, R)
    Rsum = sum(Rbin, dims=3)
    GR_path = joinpath(savepath,"$(i_sp)_monthly.nc")
    Rasters.write(GR_path, Rsum)
end