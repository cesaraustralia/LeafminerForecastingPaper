using Plots
using Rasters
using ColorSchemes

searchdir(path,key) = filter(x->occursin(key,x), readdir(path))

species_list = ["Liriomyza sativae","Liriomyza huidobrensis",
"Liriomyza trifolii", "Diglyphus isaea", "Hemiptarsenus varicornis"]

################# NBR DAY / MONTH / YEAR
## RES 10, 5, 3
for res in [10, 5, 3]
    filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryMonth", "DDbyMM")
    img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "img")
    for i_sp in species_list
        i_path = searchdir(filepath, i_sp)
        R = Raster(joinpath(filepath, i_path[1]))
        animRp = @animate for i in 1:size(R)[3]
            plot(R[Ti(i)], xlabel = "", ylabel = "",
                title = "Nbr days GR>0 $(i_sp) 2017 month$(i)", c=:matter, clim = (0,31))
        end
        gif(animRp, joinpath(img_pth, "GRsup0_Daily_$(i_sp).gif"), fps = 3)

        animRp = @animate for i in 1:size(R)[3]
            plot(R[X(310:360), Y(95:140),Ti(i)], xlabel = "", ylabel = "",
                title = "Nbr days GR>0 $(i_sp) 2017 month$(i)", c=:matter, clim = (0,31))
        end
        gif(animRp, joinpath(img_pth, "GRsup0_Daily_$(i_sp)_AUS.gif"), fps = 3)
    end
end

## WORLD9sq
filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "sumBinaryMonth", "DDbyMM")
img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "img")
basedir = @__DIR__
filepath = joinpath(basedir,"data_raw","WORLD9sq","sumBinaryMonth","DDbyMM")
img_pth = joinpath(basedir,"img","WORLD9sq")
i_sp = species_list[1]
i_path = searchdir(filepath, i_sp)
R = Raster(joinpath(filepath, i_path[1]))

MONTH = monthname.(1:12)
animRp = @animate for i in 1:size(R)[3]
    plot(R[X(3100:3600), Y(950:1400),Ti(i)], xlabel = "", ylabel = "",
    title = "$(MONTH[i])", c=:matter, clim = (0,31))
end
gif(animRp, joinpath(img_pth, "GRsup0_Daily_$(i_sp)_AUS.gif"), fps = 2)


for i_sp in species_list
    i_path = searchdir(filepath, i_sp)
    R = Raster(joinpath(filepath, i_path[1]))
    animRp = @animate for i in 1:size(R)[3]
        plot(R[Ti(i)], xlabel = "", ylabel = "",
            title = "Nbr days GR>0 $(i_sp) 2017 month$(i)", c=:matter, clim = (0,31))
    end
    gif(animRp, joinpath(img_pth, "GRsup0_Daily_$(i_sp).gif"), fps = 3)

    animRp = @animate for i in 1:size(R)[3]
        plot(R[X(3100:3600), Y(950:1400),Ti(i)], xlabel = "", ylabel = "",
            title = "Nbr days GR>0 $(i_sp) 2017 month$(i)", c=:matter, clim = (0,31))
    end
    gif(animRp, joinpath(img_pth, "GRsup0_Daily_$(i_sp)_AUS.gif"), fps = 3)
end


################# NBR DAY / YEAR
## RES 10, 5, 3
for res in [10, 5, 3]
    filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryYear")
    img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "img")

    for i_sp in species_list
        i_path = searchdir(filepath, "$(i_sp)_daily.nc")
        R = Raster(joinpath(filepath, i_path[1]))
        plot(R[Ti(1)], xlabel = "", ylabel = "", title = "Nbr days GR>0 $(i_sp) year 2017", c=:matter,clim = (0,365))
        savefig(joinpath(img_pth,"GR_DDbyYY_sup0_$(i_sp).png"))
        plot(R[X(310:360), Y(95:140),Ti(1)], xlabel = "", ylabel = "", title = "Nbr days GR>0 $(i_sp) year 2017", c=:matter,clim = (0,365))
        savefig(joinpath(img_pth,"GR_DDbyYY_sup0_$(i_sp)_AUS.png"))
    end
end

## WORLD9sq
filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "sumBinaryYear")
img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "img")
for i_sp in species_list
    i_path = searchdir(filepath, "$(i_sp)_daily.nc")
    R = Raster(joinpath(filepath, i_path[1]))
    plot(R[Ti(1)], xlabel = "", ylabel = "", title = "Nbr days GR>0 $(i_sp) year 2017", c=:matter,clim = (0,365))
    savefig(joinpath(img_pth,"GR_DDbyYY_sup0_$(i_sp).png"))
    plot(R[X(3100:3600), Y(950:1400),Ti(1)], xlabel = "", ylabel = "", title = "Nbr days GR>0 $(i_sp) year 2017", c=:matter,clim = (0,365))
    savefig(joinpath(img_pth,"GR_DDbyYY_sup0_$(i_sp)_AUS.png"))
end

################# NBR MONTH / YEAR
## RES 10, 5, 3
for res in [10, 5, 3]
    filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "sumBinaryYear")
    img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "lower_res_$res", "img")
    for i_sp in species_list
        i_path = searchdir(filepath, "$(i_sp)_monthly.nc")
        R = Raster(joinpath(filepath, i_path[1]))
        plot(R[Ti(1)], xlabel = "", ylabel = "",
            title = "Nbr month GR>0 $(i_sp) 2017", c=:matter,clim = (0,12))
        savefig(joinpath(img_pth,"GR_MMbyYY_sup0_$(i_sp).png"))
        plot(R[X(310:360), Y(95:140),Ti(1)], xlabel = "", ylabel = "",
            title = "Nbr month GR>0 $(i_sp) 2017", c=:matter,clim = (0,12))
        savefig(joinpath(img_pth,"GR_MMbyYY_sup0_$(i_sp)_AUS.png"))
    end
end

## WORLD9sq
filepath =  joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "sumBinaryYear")
img_pth = joinpath("D:\\SMAP","nsidc", "GROWTHRATE", "img")
for i_sp in species_list
    i_path = searchdir(filepath, "$(i_sp)_monthly.nc")
    R = Raster(joinpath(filepath, i_path[1]))
    plot(R[Ti(1)], xlabel = "", ylabel = "",
        title = "Nbr month GR>0 $(i_sp) 2017", c=:matter,clim = (0,12))
    savefig(joinpath(img_pth,"GR_MMbyYY_sup0_$(i_sp).png"))
    plot(R[X(3100:3600), Y(950:1400),Ti(1)], xlabel = "", ylabel = "",
        title = "Nbr month GR>0 $(i_sp) 2017", c=:matter,clim = (0,12))
    savefig(joinpath(img_pth,"GR_MMbyYY_sup0_$(i_sp)_AUS.png"))
end