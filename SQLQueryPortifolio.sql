SELECT *
fROM SQLPortifolioProject.dbo.coviddeaths
order by 3,4

--SELECT *
--fROM SQLPortifolioProject.dbo.covidvaccinations
--order by 3,4

--select needed data
select location, date,total_cases, new_cases,total_deaths,population
from SQLPortifolioProject.dbo.coviddeaths 

-- Total cases vs Total deaths(likelihood of dying if you have covid)
select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Deathpercentage
from SQLPortifolioProject.dbo.coviddeaths 
where location like '%Rwanda%'
order by 1,2

-- Total cases vs population ( percentage of people who got covid)
select location, date,population, total_cases,(total_cases/population)*100 as percentageInfectedPopulation
from SQLPortifolioProject.dbo.coviddeaths 
where location ='Rwanda'
order by 1,2

-- countries with the highest infected rate compared to population 
select location, population, MAX(total_cases) as Maxinfectedcount, MAX((total_cases/population))*100 as percentageInfectedPopulation
from SQLPortifolioProject.dbo.coviddeaths 
--where location ='Rwanda'
GROUP BY location,date,population
order by percentageInfectedPopulation desc

-- countries with the highest death rate per population 
select location, MAX(cast(total_deaths as int)) as Maxdeathcount
from SQLPortifolioProject.dbo.coviddeaths 
where continent is not null
GROUP BY location 
order by  Maxdeathcount desc

--  BREAKING THINGS DOWN BY CONTINTENT
-- continents with the highest death rate
select continent, MAX(cast(total_deaths as int)) as Maxdeathcount
from SQLPortifolioProject.dbo.coviddeaths 
where continent is not null
GROUP BY continent
order by  Maxdeathcount desc

-- continent with the highest infected rate 
select continent, MAX(total_cases) as Maxinfectedcount, MAX((total_cases/population))*100 as percentageInfectedPopulation
from SQLPortifolioProject.dbo.coviddeaths 
--where location ='Rwanda'
where continent is not null
GROUP BY continent
order by percentageInfectedPopulation desc

--BREAKING THINGS DOWN GLOBAL
-- looking at the total number of newcases and newdeaths perday globally 
select date, SUM(new_cases) as dailynewcases,SUM(cast(new_deaths as int)) as dailynewdeaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as percentageNewdeathperday
from SQLPortifolioProject.dbo.coviddeaths 
where continent is not null
group by date
order by percentageNewdeathperday desc

--looking at the overall total cases, total deaths, and percentageofnewdeathperday 
select SUM(new_cases) as dailynewcases,SUM(cast(new_deaths as int)) as dailynewdeaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as percentageNewdeathperday
from SQLPortifolioProject.dbo.coviddeaths 
where continent is not null
--group by date
order by percentageNewdeathperday

-- LOOKING AT THE TOTAL NUMBER OF daily VACCINATED people
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations
fROM SQLPortifolioProject.dbo.coviddeaths dea
join SQLPortifolioProject..covidvaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

-- looking at rollingpeople vaccinated(adding up numbers of vaccined people per day)
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date)as rollingpeoplevaccinated
fROM SQLPortifolioProject.dbo.coviddeaths dea
join SQLPortifolioProject..covidvaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- looking at total population vs total vaccination 

-- USE CTE
with vacvspop(continent,location,date, population,new_vaccinations,rollingpeoplevaccinated)
as (
SELECT dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date)as rollingpeoplevaccinated

fROM SQLPortifolioProject.dbo.coviddeaths dea
join SQLPortifolioProject..covidvaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingpeoplevaccinated/population)*100 as percentageofvaccinatedpeopleoverpopulation
from vacvspop

-- use Temp table 
drop table if exists #percentageofpopulationvaccinated
create table #percentageofpopulationvaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric)
insert into #percentageofpopulationvaccinated
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date)as rollingpeoplevaccinated

fROM SQLPortifolioProject.dbo.coviddeaths dea
join SQLPortifolioProject..covidvaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null

select *, (rollingpeoplevaccinated/population)*100 as percentageofvaccinatedpeopleoverpopulation
from #percentageofpopulationvaccinated

-- creating view to store data for later visualization 

Create View populationvaccinated as
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations, SUM(cast(vac.new_vaccinations as bigint)) over(Partition by dea.location order by dea.location, dea.date)as rollingpeoplevaccinated

fROM SQLPortifolioProject.dbo.coviddeaths dea
join SQLPortifolioProject..covidvaccinations vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null

select *
from populationvaccinated

--creating view for the overall total cases, total deaths, and percentageofnewdeathperday 
create view percentageofdailydeath as
select SUM(new_cases) as dailynewcases,SUM(cast(new_deaths as int)) as dailynewdeaths,(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as percentageNewdeathperday
from SQLPortifolioProject.dbo.coviddeaths 
where continent is not null
--group by date
--order by percentageNewdeathperday

select *
from percentageofdailydeath