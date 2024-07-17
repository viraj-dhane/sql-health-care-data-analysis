-- Data check - imported data as table 

SELECT *
FROM CovidDeaths;

SELECT *
FROM CovidVaccinations;

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3, 4	-- order by location and date

SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL 
ORDER BY 3, 4	-- order by location and date

-- Select data that we are going to start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- Total Cases vs Total Deaths
		-- Likelihood of dying if contracted by covid in perticular country
SELECT location, 
	   date, 
	   total_cases, 
	   total_deaths, 
	   CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) as Mortality_rate
FROM CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1,2;	-- order by location and date

-- Calculaitng Death Percentage
SELECT location, 
	   date, 
	   total_cases, 
	   total_deaths,
	   population,
	   CASE
			WHEN total_cases > 0 THEN (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) * 100)
			ELSE NULL -- when total_cases is zero
	   END AS Death_percentage 
FROM CovidDeaths
--WHERE location like '%states%' -- to check death percetages of particular country
ORDER BY 1,2;	-- order by location and date

-- Total Deaths vs Population i.e Mortality Rate
SELECT location, 
	   date, 
	   total_cases, 
	   total_deaths,
	   population,
	   CASE
			WHEN population > 0 THEN (CAST(total_deaths AS FLOAT) / CAST(population AS FLOAT) * 100)
			ELSE NULL -- when populatoin is zero
	   END AS Mortality_Rate 
FROM CovidDeaths
--WHERE location like 'India' -- to check death percetages of particular country
ORDER BY 1,2;	-- order by location and date

-- Countries with Highest Infection Rate and Mortality Rate by Population
SELECT
  location,
  date,
  population,
  MAX(total_cases) as HighestInfectionCount,
  MAX(
    CASE
      WHEN population > 0 THEN (total_cases / population)*100
      ELSE NULL
    END
  ) AS HighestMortalityRate
FROM
  CovidDeaths
GROUP BY
  location, date, population
ORDER BY
  location,
  MAX(date);

-- Countries with Highest Infection Rate compared to Population
SELECT location,
	   population, 
	   MAX(total_cases) as HighestInfectionCount,
	   Max((CAST(total_cases AS FLOAT)) / (CAST(population AS FLOAT)))*100 as PercentPopulationInfected
FROM CovidDeaths
WHERE population IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT location, 
       MAX(CAST(Total_deaths AS INT)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

/*
-------------------- Analysis by Continent --------------------
*/

-- Contintents with Highest Death Count per Population
SELECT continent,
	   MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC


-------------------- Global Number --------------------
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(New_Cases AS FLOAT))*100 as DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
order by 1,2

SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(New_Cases AS FLOAT))*100 as DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date	-- to get result for each day
order by 1,2

-- Join both tables
SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date

-- Total Population vs Vaccination
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Percentage of population that has recieved at least one covid vaccine
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using Common Table Expression (CTE) to perform Calculation on PARTITION BY in previous query
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT)/ CAST(population AS FLOAT))*100 AS PercentRollingPeopleVaccinated
FROM PopvsVac

-- Using Temp Table to perform calculation on PARTITIN BY in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
	(
	continent nvarchar(255),
	location nvarchar(255),
	date date,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
	)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentRollingPeopleVaccinated
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
	   dea.location,
	   dea.date,
	   dea.population,
	   vac.new_vaccinations,
	   SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 