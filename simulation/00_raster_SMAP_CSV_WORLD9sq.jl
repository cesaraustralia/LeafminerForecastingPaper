using Rasters
using Plots
using CSV
using DelimitedFiles
using Dates
using TranscodingStreams
using CodecZlib


filepath =  joinpath("D:\\SMAP","nsidc")

# 1. retrieve all files of surface moisture and temperature
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))
filepath_wlt = searchdir(filepath,"wilting.csv.gz")
filepath_tmp = searchdir(filepath,"temp.csv.gz")

function extract_date(path)
    yyyy = parse(Int64, path[16:19])
    mm =  parse(Int64, path[20:21])
    dd =  parse(Int64, path[22:23])
    hh =  parse(Int64, path[25:26])
    return DateTime(yyyy,mm,dd,hh)
end

dates_wlt = [extract_date(i_path) for  i_path in filepath_wlt]
dates_tmp = [extract_date(i_path) for  i_path in filepath_tmp]
#check same dates
dates_wlt == dates_tmp

lat = readdlm(joinpath(filepath, "lat.csv"))
lon = readdlm(joinpath(filepath, "lon.csv"))

function get_stack(path)
    r = open(GzipDecompressorStream, joinpath(filepath, path), "r") do stream
        readdlm(stream, ';', Float64)
    end
    println(path)
    R = Raster(r', (X(lon[1:3856]), Y(lat[1:1624])) ; missingval = -9999.0)
    return R
end

mmdd = monthday.(dates_wlt)
mmdd_uniq = unique(mmdd)

for s in mmdd_uniq
# for s in reverse(mmdd_uniq)
    filename_R_wlt = string("SMAP_L4_SM_gph_2017$(string(s[1],pad=2))$(string(s[2],pad=2))_wilt.nc")
    filename_R_tmp = string("SMAP_L4_SM_gph_2017$(string(s[1],pad=2))$(string(s[2],pad=2))_temp.nc") 
    filepath_R_wlt = joinpath(filepath, filename_R_wlt)
    filepath_R_tmp = joinpath(filepath, filename_R_tmp)
    select = [s == i_mmdd for i_mmdd ∈ mmdd]
    if !(filename_R_wlt ∈ readdir(filepath))
        stack_wlt = [get_stack(i_path) for  i_path in filepath_wlt[select]]
        R_wlt = sum(stack_wlt) ./ size(stack_wlt)[1]
        Rasters.write(filepath_R_wlt, R_wlt)
    end
    if !(filename_R_tmp ∈ readdir(filepath))
        stack_tmp = [get_stack(i_path) for  i_path in filepath_tmp[select]]
        R_tmp = sum(stack_tmp) ./ size(stack_tmp)[1]
        Rasters.write(filepath_R_tmp, R_tmp)
    end   
end

# stack_daily_wilt = [get_stack(i_path) for  i_path in filepath_wlt]
# sizeof(stack_daily_wilt)
# stack_daily_temp = [get_stack(i_path) for  i_path in filepath_tmp]