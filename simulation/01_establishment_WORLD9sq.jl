using Rasters
using GrowthMaps
using Unitful
using UnitfulRecipes
using Unitful: °C, K, cal, mol
using Dates
using ColorSchemes
using DataFrames
using CSV

filepath =  joinpath("D:\\SMAP","nsidc")
searchdir(path,key) = filter(x->occursin(key,x), readdir(path))

filepath_wlt = searchdir(filepath,"wilt.nc")
filepath_tmp = searchdir(filepath,"temp.nc")

# r_wlt = NetCDF.open(joinpath(filepath, filepath_wlt[1]), "unnamed")
dfGR = DataFrame(CSV.File("data/growthRate_parameters.csv"))

species_list = ["Liriomyza sativae","Liriomyza huidobrensis",
"Liriomyza trifolii", "Diglyphus isaea", "Hemiptarsenus varicornis"]

function extract_date(path)
    yyyy = parse(Int64, path[16:19])
    mm =  parse(Int64, path[20:21])
    dd =  parse(Int64, path[22:23])
    return DateTime(yyyy,mm,dd)
end

dates_wlt = [extract_date(i_path) for  i_path in filepath_wlt]
dates_tmp = [extract_date(i_path) for  i_path in filepath_tmp]
#check same dates
dates_wlt == dates_tmp

mm = month.(dates_wlt)
mm_uniq = unique(mm)

function r_wlt(path_wlt,i) 
    r = Rasters.Raster(joinpath(filepath, path_wlt[i]))
    r_w = replace_missing(r, -9999.0)
    return r_w
end
function r_tmp(path_tmp,i) 
    r = Rasters.Raster(joinpath(filepath, path_tmp[i]))
    r_w = replace_missing(r, -9999.0)
    return r_w
end


for s in reverse(mm_uniq)
    
    select = [s == i_mm for i_mm ∈ mm]

    path_wlt = filepath_wlt[select]
    path_tmp = filepath_tmp[select]

    climate = [RasterStack((tavg=r_tmp(path_tmp,i), wilt=r_wlt(path_wlt,i))) for i in 1:length(path_wlt)]
    
    timedim = Ti(1:length(climate))
    climate_series_w = RasterSeries(climate, (timedim,))

    for species_select in species_list

        growthratesfilepath = joinpath(filepath, "GROWTHRATE", string("growthrates_2017_$(string(s,pad=2))", species_select,".nc"))

        if !(growthratesfilepath ∈ readdir(joinpath(filepath, "GROWTHRATE")))

            println(growthratesfilepath)

            dfGR_sel = filter(row -> row.Species == species_select, dfGR)
            ##### GROWTH MODEL
            # Set SchoolfieldIntrinsicGrowth model parameters including fields for units and bounds for fitting
            p = dfGR_sel[:, "p"][1] 
            ΔH_A = dfGR_sel[:, "HA"][1]cal/mol
            ΔH_H =  dfGR_sel[:, "HH"][1]cal/mol
            ΔH_L = dfGR_sel[:, "HL"][1]cal/mol

            T_ref = dfGR_sel[:, "Tref"][1]°C |> K

            Thalf_L = dfGR_sel[:, "T0.5L"][1]K
            Thalf_H = dfGR_sel[:, "T0.5H"][1]K

            growthmodel = SchoolfieldIntrinsicGrowth(p, ΔH_A, ΔH_L, Thalf_L, ΔH_H, Thalf_H, T_ref)
            # Link growth model to hypothetical layer of temperature data.
            growthresponse = Layer(:tavg, K, growthmodel)

            ##### STRESS MODELS
            # coldstress is a LowerStress
            coldthresh = dfGR_sel[:,"CTmin"][1]°C |> K
            coldmort = dfGR_sel[:,"mTmin"][1] * K^-1
            # heatstress is an UpperStress
            heatthresh = dfGR_sel[:,"CTmax"][1]°C |> K
            heatmort = dfGR_sel[:,"mTmax"][1] * K^-1
            # wiltstress is an UpperStress
            wiltthresh = dfGR_sel[:,"Cwilt"][1]
            wiltmort   = dfGR_sel[:,"mwilt"][1]

            coldstress = Layer(:tavg, K, LowerStress(coldthresh, coldmort))
            heatstress = Layer(:tavg, K, UpperStress(heatthresh, heatmort))
            wiltstress = Layer(:wilt, UpperStress(wiltthresh, wiltmort))

            growthrates_stress = mapgrowth(
                growthresponse,
                coldstress,
                heatstress,
                wiltstress,
                ;
                series=climate_series_w,
                tspan = 1:length(climate_series_w)
            )

            ############# SAVE RASTERS ####################
            Rasters.write(growthratesfilepath, Raster(growthrates_stress))
        end
    end
end
