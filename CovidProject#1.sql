--Note that total_cases, total_deaths, etc is recorded daily in the csv file, and TotalDeaths(no underscore), etc is the total count of (x) from 01/2020-6/26/2023
	--Key takeaways from this data exploration at the bottom 

--Shows the entire table ordered by location and date 
--1.
select *
from [Portfolio Project#1]..[Covid Deaths]
Where continent is not null
order by 3,4;

--2.
--Shows cases over time by country 
select location, date, population, new_cases, total_cases, total_deaths
from [Portfolio Project#1]..[Covid Deaths]
order by total_cases asc,4,6
 
 --3.
 --Total Deaths vs Population 
	--Percent of entire population that has died from covid
Select Location,Population, max(cast(total_deaths as int)) as TotalDeaths, max ((total_deaths/population))*100 as DeathPercentage
From [Portfolio Project#1]..[Covid Deaths]
WHERE (Location NOT LIKE '%world%' OR Location NOT LIKE 'income%') AND Continent IS NOT NULL
group by location, population
order by DeathPercentage desc

--4.
 --Total Deaths vs Population (Death% of infected)
	--Chance of dying if infected with Covid
Select Location,max(total_cases) as TotalCases,max(total_deaths) as TotalDeaths, (max(total_deaths)/max(total_cases))*100 as DeathPercentageInfected
From [Portfolio Project#1]..[Covid Deaths]
WHERE (Location NOT LIKE '%world%' OR Location NOT LIKE 'income%') AND Continent IS NOT NULL 
group by location
ORDER BY DeathPercentageInfected DESC

--5.
--Countries by total highest %population infected
--Note that it is unclear whether or not duplicate cases (i.e someone contracts covid twice) are included in this table 
Select Location, Population, MAX(total_cases) as TotalCases,  Max((total_cases/population))*100 as PercentInfected
From [Portfolio Project#1]..[Covid Deaths] 
--Where location like '%location%'
Group by Location, Population
Order by PercentInfected desc


--6.
--Countries by highest death count
SELECT Location, Population, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM [Portfolio Project#1]..[Covid Deaths]
WHERE (Location NOT LIKE '%world%' OR Location NOT LIKE 'income%') AND Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY TotalDeathCount DESC


--7A. 
--Continents by highest death count
--		*This code is useless as when continent is not null, North America shows only USA deaths*	
--Select Continent, MAX(cast(total_deaths as int)) as TotalDeathCount
--From [Portfolio Project#1]..[Covid Deaths]
--Where continent is not null 
--Group by continent
--Order by TotalDeathCount desc

--7B.
--Regions by highest death count (This dataset includes a continent column and a location column. Location column contains countries AND continents)
Select location as Region , SUM(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project#1]..[Covid Deaths]
Where location in ('Europe', 'Asia', 'North America', 'South America', 'Oceania','Africa')
Group by location
order by TotalDeathCount desc

-----------------------------------------------

--8.
--Vaccinations 
	--Converting from nvarchar to decimal
		--alter table [Portfolio Project#1]..[Vaccinations]
		--alter column new_vaccinations decimal
Select dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations,
sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations 
From [Portfolio Project#1]..[Covid Deaths] dea
Join [Portfolio Project#1]..[Vaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null 
--and vac.total_vaccinations > 0
--order by total_vaccinations asc
order by 2,3
		--First vaccination on 2020-12-09 in Norway (According to this Dataset)

--9.
--Use CTE
--Finding % of population that is vaccinated 
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, TotalVaccinations)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations 
From [Portfolio Project#1]..[Covid Deaths] dea
Join [Portfolio Project#1]..[Vaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null
--and vac.total_vaccinations > 0
--order by total_vaccinations asc
--order by 2,3
)
Select *, (TotalVaccinations/Population)*100 as VacPercentage
from PopvsVac



--Temp Table 
Create table  #percentpopvaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric, 
New_vaccinations numeric,
TotalVaccinations numeric
)
Insert into #percentpopvaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations 
From [Portfolio Project#1]..[Covid Deaths] dea
Join [Portfolio Project#1]..[Vaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null
--and vac.total_vaccinations > 0
--order by total_vaccinations asc
--order by 2,3


--Create View(s) for later data viz
--View #1 (%population vaccinated)
USE [Portfolio Project#1]
go 
Create view percentpopvaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(decimal,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as TotalVaccinations 
From [Portfolio Project#1]..[Covid Deaths] dea
Join [Portfolio Project#1]..[Vaccinations] vac
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent is not null
--and vac.total_vaccinations > 0
--order by total_vaccinations asc
--order by 2,3

select* 
from [Portfolio Project#1]..percentpopvaccinated



--Viz #2 Death Percentage of infected (total)
USE [Portfolio Project#1]
go 
Create view DeathPercentage as 
Select SUM(new_cases) as Total_Infected, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Portfolio Project#1]..[Covid Deaths]



--View #3 (TotalDeathCount)
USE [Portfolio Project#1]
go 
Create view TotalDeathCount as 
Select location as Region, SUM(cast(new_deaths as int)) as TotalDeathCount
From [Portfolio Project#1]..[Covid Deaths]
Where location in ('Europe', 'Asia', 'North America', 'South America', 'Oceania','Africa')
Group by location
--order by TotalDeathCount desc

--View #4 (%Infected)
USE [Portfolio Project#1]
go 
Create view PercentInfected as 
Select Location, Population, MAX(total_cases) as TotalCases,  Max((total_cases/population))*100 as PercentInfected
From [Portfolio Project#1]..[Covid Deaths] 
Group by Location, Population
--Order by PercentInfected desc


--View #5 (%Infected w/Date)
USE [Portfolio Project#1]
go 
Create view Percentinfecteddate as 
Select Location, Population,Date, MAX(total_cases) as InfectionCount,  Max((total_cases/population))*100 as PercentInfected
From [Portfolio Project#1]..[Covid Deaths]
Group by Location, Population, Date
--order by PercentInfected desc


--List of views 
	--Use [Portfolio Project#1]
	--go
	--select * 
	--From percentpopvaccinated

		--Use [Portfolio Project#1]
		--go
		--select* 
		--from PercentInfected

			--Use [Portfolio Project#1]
			--go
			--select * 
			--from DeathPercentage

				--Use [Portfolio Project#1]
				--go
				--select * 
				--from TotalDeathCount

					--Use [Portfolio Project#1]
					--go
					--select * 
					--from Percentinfecteddate



							--Key takeaways--

--- Peru had the highest death% compared to total population (64.844%)
--- Yemen had the highest death% of those who were infected (18.074%)
--    -(Chance of dying if infected with covid)
--- Cyprus had the highest % of infected with 73.755% of the total population being infected (660854cases/896007pop)
--- The US was #1 for total covid deaths for a single country (1,127,152)
--    - #2 is Brazil (703,399)and India is #3 (531,896)
--- In order to find statistics for a continent (region) it was easier to find it in the location column, and filter out all countries and income levels.
--  There is no con
--- Regions ranked by highest death count were as follows
--    - #1 Europe - 2,068,932
--    - #2 Asia - 1,633,632
--    - #3 North America - 1,602,228
--    - #4 South America - 1,353,998
--    - #5 Africa - 258,977
--    - #5 Oceania - 27,929
--		Total = 6,945,696 deaths as of 6/26/23
--- First vaccine administered (according to this dataset) on 2020-12-09 in Norway
--    - Could be a useful date marker for future visualizations








