SELECT * 
FROM CovidDeaths cd
WHERE continent is not null
order by 3,4;

/*SELECT * 
FROM CovidVaccinations cv 
order by 3,4;
*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths cd 
order by 1,2;



-- Looking at total deaths vs total cases
-- shows likelihood of dying if you contract covid

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
FROM CovidDeaths cd 
WHERE location like '%states%' and continent is not null
order by 1,2;

-- looking at total cases vs population
-- shows what % got covid
SELECT location, date, total_cases, population,  (total_deaths/population) * 100 as InfectedPercentage
FROM CovidDeaths cd 
WHERE location like '%states%' and continent is not null
order by 1,2;

-- Looking at countries with highest infection rate compared to population
SELECT location, population,  MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as InfectedPercentage
FROM CovidDeaths cd 
WHERE continent is not null
Group by location, population
order by InfectedPercentage desc;

-- showing countries with the highest death count per population
SELECT location, population,  MAX(cast(total_deaths as decimal)) as HighestDeathCount, MAX((total_deaths/population)) * 100 as DeathPercentage
FROM CovidDeaths cd 
WHERE continent is not null
Group by location, population
order by DeathPercentage desc;

-- breaking things down by continent
SELECT location, MAX(cast(total_deaths as decimal)) as HighestDeathCount
FROM CovidDeaths cd
WHERE continent is null
Group by location
order by HighestDeathCount desc;

-- showing the continents with the highest death count
SELECT continent, MAX(cast(total_deaths as decimal)) as HighestDeathCount
FROM CovidDeaths cd
WHERE continent is not null
Group by continent
order by HighestDeathCount desc;

-- global numbers 
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as decimal)) as total_deaths_calc, (SUM(cast(new_deaths as decimal))/SUM(new_cases)) * 100 as DeathPercentage
FROM CovidDeaths cd 
WHERE continent is not NULL 
GROUP by date
order by 1,2;

-- aggregated global numbers 
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as decimal)) as total_deaths_calc, (SUM(cast(new_deaths as decimal))/SUM(new_cases)) * 100 as DeathPercentage
FROM CovidDeaths cd 
WHERE continent is not NULL 
-- GROUP by date
order by 1,2;

-- joining vaccination and death table together
SELECT * 
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date

-- looking at total population vaccinations
SELECT cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations 
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null
order by 2,3;

-- rolling sum
SELECT cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as decimal))OVER (PARTITION by cd.location order by cd.location, cd.`date`) as DailyUpdatedVaccinations
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null
and cv.new_vaccinations is not null
order by 2,3;


-- using cte to calculate percentages of vaccinations of rolling people 
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, DailyUpdatedVaccinations)
as
(
SELECT cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as decimal))OVER (PARTITION by cd.location order by cd.location, cd.`date`) as DailyUpdatedVaccinations
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null
and cv.new_vaccinations is not null
-- order by 2,3;
)
SELECT *, (DailyUpdatedVaccinations/population) * 100
FROM PopvsVac;

/* table not working right now
-- using temp table to calculate percentages of vaccinations of rolling people 
drop table if exists percentpopulationvaccinated
create table percentpopulationvaccinated
(
	Continent varchar(50),
	Location varchar(50),
	`Date` datetime,
	Population bigint, 
	New_vaccinations bigint, 
	DailyUpdatedVaccinations bigint
);


insert INTO percentpopulationvaccinated
SELECT cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as decimal))OVER (PARTITION by cd.location order by cd.location, cd.`date`) as DailyUpdatedVaccinations
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cv.new_vaccinations is not null
-- and cd.continent is not null
-- order by 2,3;

SELECT *, (DailyUpdatedVaccinations/population) * 100
FROM percentpopulationvaccinated;
*/

-- creating view to store data for future vizualizations
create view percentpopulatedDaily as
SELECT cd.continent, cd.location, cd.`date`, cd.population, cv.new_vaccinations, 
SUM(cast(cv.new_vaccinations as decimal))OVER (PARTITION by cd.location order by cd.location, cd.`date`) as DailyUpdatedVaccinations
FROM CovidDeaths cd 
join CovidVaccinations cv 
	on cd.location = cv.location 
	and cd.date = cv.date
where cd.continent is not null
and cv.new_vaccinations is not null
-- order by 2,3;

SELECT *
FROM percentpopulatedDaily;

